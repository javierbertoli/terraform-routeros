resource "routeros_ip_dhcp_server_option" "ros" {
  for_each = var.dhcp_server_options
  name     = each.key
  code     = each.value.code
  value    = each.value.value
  comment  = upper("tf - ${lookup(each.value, "comment", each.key)}")
}

resource "routeros_ip_dhcp_client" "ros" {
  for_each               = { for i, p in var.interfaces : i => p if try(p.type, false) == "dhcp_client" && try(p.create_iface, true) }
  interface              = each.value.iface
  default_route_distance = lookup(each.value, "distance", "1")
  add_default_route      = lookup(each.value, "add_route", false) ? "yes" : "no"
  comment                = upper("tf - ${lookup(each.value, "comment", each.key)}")
  use_peer_dns           = lookup(each.value, "use_peer_dns", false)
  use_peer_ntp           = lookup(each.value, "use_peer_ntp", false)
}

resource "routeros_ip_dhcp_server" "ros" {
  for_each     = var.dhcp_server
  name         = each.key
  address_pool = routeros_ip_pool.ros[each.key].name
  interface    = lookup(each.value, "iface", "ether1")
  lease_time   = lookup(each.value, "lease_time", "8h")
  lease_script = try(
    templatefile("${path.module}/files/${each.value.lease_script}.tftpl", { domain = var.domain }),
    null
  )
  comment = upper("tf - ${lookup(each.value, "comment", each.key)}")
}
resource "routeros_ip_pool" "ros" {
  for_each = var.dhcp_server
  name     = each.key
  ranges   = each.value.ip_pool_ranges
  comment  = upper("tf - ${lookup(each.value, "comment", each.key)}")
}

resource "routeros_ip_dhcp_server_network" "ros" {
  for_each = var.dhcp_server
  address = lookup(each.value, "address",
    "${each.value.network_prefix}.0/${lookup(each.value, "network_mask", "24")}"
  )
  netmask     = lookup(each.value, "network_mask", "24")
  dhcp_option = keys(var.dhcp_server_options)
  domain      = lookup(each.value, "domain", var.domain)
  gateway     = "${each.value.network_prefix}.${lookup(each.value, "gateway_host", "254")}"
  ntp_server  = lookup(each.value, "ntp_servers", ["${each.value.network_prefix}.254"])
  dns_server  = lookup(each.value, "dns_servers", ["${each.value.network_prefix}.254"])
  next_server = lookup(each.value, "next_server", null)
  comment     = upper("tf - ${lookup(each.value, "comment", each.key)}")
}

resource "routeros_ip_dhcp_server_lease" "ros" {
  for_each    = local.dhcp_static_leases
  address     = each.value.address
  mac_address = each.value.mac_address
  server      = each.value.server
  comment     = upper("tf - ${lookup(each.value, "comment", each.key)}")
}