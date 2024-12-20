locals {
  interfaces_lists = distinct(flatten(concat(
    [
      for int, p in var.interfaces : p.list if contains(keys(p), "list")
    ]
  )))

  interfaces_lists_members = merge([
    for int, p in var.interfaces : {
      for l in flatten(concat([p.list], [])) : "${int}-${l}" => {
        iface   = try(p.iface, int)
        list    = l
        comment = try(p.comment, "${upper(int)}")
      }
    } if contains(keys(p), "list")
  ]...)

  addresses_lists = merge([
    for l, as in var.addresses_lists : {
      for a in as : "${l}-${a}" => {
        list    = "${l}"
        address = a
      }
    }
  ]...)

  ip_addresses = merge([
    for int, p in var.interfaces : {
      for ip in flatten(concat([p.ip], [])) : "${int}-${ip}" => {
        iface   = try(p.iface, int)
        ip      = ip
        network = try(p.network, cidrhost(ip, 0))
        comment = try(p.comment, "Red de ${upper(int)}")
      }
    } if contains(keys(p), "ip")
  ]...)

  # dhcp_servers lists, to fake macs
  dhcp_servers_lists = keys(var.dhcp_server)

  dhcp_static_leases = merge(flatten(
    [
      for d, c in var.dhcp_server : [
        for i, l in try(c.static_leases, {}) : {
          for n, p in l : "${d}-${n}" => {
            address = p.ip
            comment = lookup(p, "comment", n)
            # https://serverfault.com/a/40720
            mac_address = lookup(p, "mac", "0E:0E:0E:0E:${format("%02d", index(local.dhcp_servers_lists, d))}:${format("%02d", i + 1)}")
            server      = d
          }
        }
      ]
    ])...
  )

  dns_forwarders_map = {
    # https://dnsprivacy.org/public_resolvers/
    cleanbrowsing_adult = {
      doh_url = "https://doh.cleanbrowsing.org/doh/adult-filter/",
      forwarders = [
        "185.228.168.10",
        "185.228.169.11",
      ],
      verify_doh_cert = false,
    },
    # Cleanbrowsing needs a custom CAs
    cleanbrowsing_family = {
      doh_url = "https://doh.cleanbrowsing.org/doh/family-filter/",
      forwarders = [
        "185.228.168.168",
        "185.228.169.168",
      ],
      verify_doh_cert = false,
    },
    cleanbrowsing_security = {
      doh_url = "https://doh.cleanbrowsing.org/doh/security-filter/",
      forwarders = [
        "185.228.168.9",
        "185.228.169.9",
      ],
      verify_doh_cert = false,
    },
    google = {
      doh_url = "https://dns.google/dns-query",
      forwarders = [
        "8.8.8.8",
        "8.8.4.4",
      ],
    },
    opendns = {
      doh_url = "https://doh.opendns.com/dns-query",
      forwarders = [
        "208.67.222.123",
        "208.67.220.123",
      ],
    },
    opendns_family = {
      doh_url = "https://doh.familyshield.opendns.com/dns-query",
      forwarders = [
        "208.67.222.123",
        "208.67.220.123",
      ],
    },
    quad9 = {
      doh_url = "https://dns.quad9.net/dns-query",
      forwarders = [
        "9.9.9.9",
        "149.112.112.112",
      ],
    },
    ultimate = {
      doh_url = "",
      forwarders = [
        "88.198.70.38",
        "88.198.70.39",
      ],
    },
  }

  dns_forwarders = (
    length(try(var.dns.forwarders, "")) > 0
    ? (var.dns.forwarders == "custom_forwarders"
      ? var.dns.custom_forwarders
      : local.dns_forwarders_map[var.dns.forwarders].forwarders
    )
    : []
  )

  dns_use_doh = try(var.dns.use_doh, false)

  dns_doh_url     = try(var.dns.doh_url, local.dns_forwarders_map[try(var.dns.forwarders, "quad9")].doh_url)
  verify_doh_cert = try(var.dns.verify_doh_cert, try(local.dns_forwarders_map[try(var.dns.forwarders, "quad9")].verify_doh_cert, true))

  malicious_contents_filtering_urls = (
    var.malicious_contents_filtering.enabled
    ? try(var.malicious_contents_filtering.filters_urls, ["https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling-porn/hosts"])
    : []
  )

  wans_list = [for i, p in var.interfaces : i if contains(keys(p), "gateway") || try(p.add_route, false)]
  wans = (
    length(local.wans_list) > 0
    ? merge(
      {
        for i, p in var.interfaces : i => {
          index    = index(local.wans_list, i) + 1
          ip       = p.ip
          gateway  = p.gateway
          distance = lookup(p, "distance", "1")
          iface    = p.iface
          pref_src = split("/", p.ip)[0]
          comment  = lookup(p, "comment", i)
        } if contains(keys(p), "gateway")
      },
      {
        for i, p in var.interfaces : i => {
          index    = index(local.wans_list, i) + 1
          ip       = routeros_ip_dhcp_client.ros[i].address
          gateway  = routeros_ip_dhcp_client.ros[i].gateway
          distance = lookup(p, "distance", "1")
          iface    = p.iface
          pref_src = split("/", routeros_ip_dhcp_client.ros[i].address)[0]
          comment  = lookup(p, "comment", i)
        } if contains(keys(p), "add_route")
      },
    )
    : {}
  )

  wireguard_servers = { for i, p in var.interfaces : i => p if try(p.type, false) == "wireguard" }

  ### BASIC FIREWALL RULES #############################
  ### FILTER INPUT
  firewall_filter_input_basic_rules = [
    {
      fasttrack = {
        position = 1
        action   = "fasttrack-connection"
        connection_state = [
          "established",
          "related",
        ]
        hw_offload = true
        comment    = "fasttrack est rel"
        protocol   = null
      }
    },
    {
      est_rel_unt = {
        position = 2
        connection_state = [
          "established",
          "related",
          "untracked",
        ]
        protocol = null
      }
    },
    {
      drop_invalid = {
        position         = 3
        action           = "drop"
        connection_state = ["invalid"]
        protocol         = null
      }
    },
    {
      accept_icmp = {
        position = 900
        protocol = "icmp"
        limit    = "1,5:packet"
      }
    },
    {
      reject_udp_smb = {
        position    = 901
        action      = "reject"
        protocol    = "udp"
        dst_port    = ["137-139"]
        reject_with = "icmp-admin-prohibited"
      }
    },
    {
      reject_tcp_smb = {
        position    = 902
        action      = "reject"
        protocol    = "tcp"
        dst_port    = ["137-139"]
        reject_with = "icmp-admin-prohibited"
      }
    },
    {
      drop_all_not_from_lan = {
        position          = 903
        action            = "drop"
        in_interface_list = "!LAN"
        protocol          = null
      }
    },
  ]

  firewall_filter_input_vpn_rules = (
    contains(local.interfaces_lists, "VPN")
    ? [
      {
        wireguard = {
          position = 4
          protocol = "udp"
          dst_port = [var.interfaces.wireguard-server.listen_port]
        },
      }
    ]
    : []
  )

  firewall_input_rules_list = concat(
    local.firewall_filter_input_basic_rules,
    local.firewall_filter_input_vpn_rules,
    try(var.firewall.input, []),
  )

  firewall_input_rules = merge([
    for i, m in local.firewall_input_rules_list : {
      for r, p in m : r => p
    }
  ]...)

  firewall_filter_input_rules_sorted = {
    for r, p in local.firewall_input_rules : format("%04d", p.position) => r
  }

  ### FILTER FORWARD
  firewall_filter_forward_basic_rules = [
    {
      fasttrack = {
        position = 50
        action   = "fasttrack-connection"
        connection_state = [
          "established",
          "related",
        ]
        hw_offload = true
        comment    = "defconf: fasttrack"
        protocol   = null
      }
    },
    {
      est_rel_unt = {
        position = 51
        connection_state = [
          "established",
          "related",
          "untracked",
        ]
        protocol = null
      }
    },
    {
      drop_invalid = {
        position         = 52
        action           = "drop"
        connection_state = ["invalid"]
        protocol         = null
      }
    },
    {
      accept_icmp = {
        position = 53
        protocol = "icmp"
        limit    = "1,5:packet"
      }
    },
    {
      drop_from_wan_not_dstnated = {
        position             = 999
        action               = "drop"
        protocol             = null
        connection_state     = ["new"]
        connection_nat_state = "!dstnat"
        in_interface_list    = "WAN"
      }
    },
  ]

  firewall_filter_forward_block_dns_rules = (
    try(var.dns.block_external_dns, false)
    ? [
      {
        lan_denied_a_dns_udp = {
          position          = 54
          action            = "reject"
          in_interface_list = "LAN"
          protocol          = "udp"
          dst_port = [
            "53"
          ]
          comment     = "LAN should not use external DNS, so we can filter malicious traffic"
          reject_with = "icmp-admin-prohibited"
        },
      }
    ]
    : []
  )

  firewall_forward_rules_list = concat(
    local.firewall_filter_forward_basic_rules,
    local.firewall_filter_forward_block_dns_rules,
    try(var.firewall.forward, []),
  )

  firewall_forward_rules = merge([
    for i, m in local.firewall_forward_rules_list : {
      for r, p in m : r => p
    }
  ]...)

  firewall_filter_forward_rules_sorted = {
    for r, p in local.firewall_forward_rules : format("%04d", p.position) => r
  }

  ### NAT
  firewall_nat_basic_rules = [
    {
      masquerade = {
        position           = 999
        action             = "masquerade"
        out_interface_list = "WAN"
      },
    }
  ]

  # Just to make it easier to create the firewall rules
  wireguard_rules_list = [for i, p in try(var.routing.rules, {}) : i if startswith(i, "wireguard")]

  firewall_nat_wireguard_rules = concat([
    for r, p in try(var.routing.rules, []) : { "${r}" = {
      position         = index(local.wireguard_rules_list, r) + 1
      protocol         = "udp"
      dst_port         = [var.interfaces.wireguard-server.listen_port]
      dst_address_type = "local"
      chain            = "dstnat"
      action           = "dst-nat"
      to_addresses     = split("/", p.src_address)[0]
      to_ports         = [var.interfaces.wireguard-server.listen_port]
      in_interface     = split("_", p.table)[1]
      passthrough      = false
      comment          = "CONN IN from VPN"
      }
    } if startswith(r, "wireguard")
  ])

  firewall_nat_transparent_proxy_rules = (
    var.enable_transparent_proxy
    ? [
      {
        redirect_http_to_proxy = {
          position          = length(local.wireguard_rules_list) + 1
          chain             = "dstnat"
          action            = "redirect"
          in_interface_list = "LAN"
          protocol          = "tcp"
          dst_port          = ["80"]
          dst_address_type  = "!local"
          to_ports          = ["8080"]
          comment           = "LAN should access the Webz using the proxy"
        }
      }
    ]
    : []
  )

  firewall_nat_rules_list = concat(
    local.firewall_nat_basic_rules,
    local.firewall_nat_wireguard_rules,
    local.firewall_nat_transparent_proxy_rules,
    try(var.firewall.nat, []),
  )

  firewall_nat_rules = merge([
    for i, m in local.firewall_nat_rules_list : {
      for r, p in m : r => p
    }
  ]...)

  firewall_nat_rules_sorted = {
    for r, p in local.firewall_nat_rules : format("%04d", p.position) => r
  }

  ### MANGLE
  firewall_mangle_basic_rules = []
  firewall_mangle_vpn_rules = [
    {
      vpn_prerouting = {
        position          = 0
        chain             = "prerouting"
        action            = "accept"
        in_interface_list = "VPN"
        passthrough       = false
        comment           = "CONN IN from VPN"
      }
    }
  ]

  firewall_mangle_multiple_wans_prerouting_rules = [
    for r, p in local.wans : { "${r}_forward" = {
      position            = p.index
      chain               = "prerouting"
      action              = "mark-connection"
      connection_mark     = "no-mark"
      connection_state    = ["new"]
      in_interface        = p.iface
      new_connection_mark = "from_${p.iface}"
      passthrough         = true
      comment             = "MARK CONN IN from ${upper(p.iface)}"
      }
    }
  ]

  firewall_mangle_multiple_wans_routing_rules = [
    for r, p in local.wans : { "${r}_prerouting" = {
      position          = length(local.wans_list) + p.index
      chain             = "prerouting"
      action            = "mark-routing"
      connection_mark   = "from_${p.iface}"
      in_interface_list = "LAN"
      new_routing_mark  = "to_${p.iface}"
      passthrough       = false
      comment           = "MARK ROUTE TO ${upper(p.iface)}"
      }
    }
  ]

  firewall_mangle_multiple_wans_output_rules = [
    for r, p in local.wans : { "${r}_output" = {
      position         = length(local.wans_list) * 2 + p.index
      chain            = "output"
      action           = "mark-routing"
      connection_mark  = "from_${p.iface}"
      new_routing_mark = "to_${p.iface}"
      passthrough      = false
      comment          = "MARK ROUTE TO ${upper(p.iface)}"
      }
    }
  ]

  firewall_mangle_rules_list = concat(
    local.firewall_mangle_basic_rules,
    (
      contains(local.interfaces_lists, "VPN")
      ? local.firewall_mangle_vpn_rules
      : []
    ),
    (
      length(local.wans) > 1
      ? local.firewall_mangle_multiple_wans_prerouting_rules
      : []
    ),
    (
      length(local.wans) > 1
      ? local.firewall_mangle_multiple_wans_routing_rules
      : []
    ),
    (
      length(local.wans) > 1
      ? local.firewall_mangle_multiple_wans_output_rules
      : []
    ),
    try(var.firewall.mangle, []),
  )

  firewall_mangle_rules = merge([
    for i, m in local.firewall_mangle_rules_list : {
      for r, p in m : r => p
    }
  ]...)

  firewall_mangle_rules_sorted = {
    for r, p in local.firewall_mangle_rules : format("%04d", p.position) => r
  }

  # {
  #   for r, p in local.firewall_mangle_rules : format("%04d", p.position) => r
  # }

  router_has_wifi = contains(data.routeros_interfaces.ros.interfaces[*].type, "wlan")

  routing_per_interface_routes = (
    length(local.wans) > 1
    ? { for r, p in local.wans : "to_${r}" => {
      comment       = "to ${p.comment}"
      distance      = "1"
      gateway       = p.gateway
      iface         = p.iface
      index         = 1
      ip            = p.ip
      pref_src      = p.pref_src
      routing_table = "to_${p.iface}"
      }
    }
    : {}
  )

  routing_routes = merge(
    try(var.routing.routes, {}),
    local.wans,
    local.routing_per_interface_routes
  )

  routing_rules = (
    length(local.wans) > 1
    ? merge(
      try(var.routing.rules, {}),
      local.wans,
      { for r, p in local.wans : r => {
        action       = lookup(p, "action", "lookup-only-in-table")
        comment      = lookup(p, "comment", null)
        disabled     = lookup(p, "disabled", false)
        dst_address  = lookup(p, "dst_address", null)
        interface    = lookup(p, "interface", try(var.interfaces["intranet"].iface))
        routing_mark = lookup(p, "routing_mark", "to_${p.iface}")
        src_address  = lookup(p, "src_address", null)
        table        = lookup(p, "table", "to_${p.iface}")
        }
      }
    )
    : {}
  )

  routing_tables = merge(
    try(var.routing.tables, {}),
    # Damn splats y maps
    # https://github.com/hashicorp/terraform/issues/22476
    {
      for t, p in local.routing_rules : p.table => {
        fib     = true
        comment = "Table to ${t}"
      } if !startswith(t, "wireguard_loopback")
    }
  )
}
