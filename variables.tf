variable "addresses_lists" {
  default = {}
}
variable "admin_email" {
  description = "Admin Email"
  type        = string
  default     = "mk-notifications@your.domain"
}
variable "api" {
  type = map(string)
  default = {
    hosturl  = null
    username = "admin"
    password = null
    insecure = false
  }
}
variable "customer" {
  description = "Customer"
  type        = string
  default     = ""
}
variable "dns" {
  default = {
    # One of
    # "quad9"
    # "ultimate"
    # "opendns"
    # "opendns_family"
    # "cleanbrowsing_adult"
    # "cleanbrowsing_family"
    # "cleanbrowsing_security"
    # "custom"
    # forwarders = null
    # Cloudflare's. Verify con https://one.one.one.one/help/)
    # "https://cloudflare-dns.com/dns-query"
    # Quad9's. https://www.quad9.net/es/service/service-addresses-and-features

    # https://github.com/Ultimate-Hosts-Blacklist"
    # Quad9's. https://www.quad9.net/es/service/service-addresses-and-features
    # custom_forwarders = [] # Needs to be set if forwarders == "custom"
    # use_doh = false
    # doh_url = "https://dns.quad9.net/dns-query"
    # block_external_dns = false # whether we allow the internal network to query external servers
    # OpenDNS: https://b3n.org/dns-filter-cleanbrowsing-opendns/
    # 208.67.222.123 and 208.67.220.123
    # https://doh.opendns.com/dns-query
    # Content filtering
    # https://doh.familyshield.opendns.com/dns-query
    records = {
      #   name = {
      #     type = A # optional
      #     target = "aaa.bbb.ccc.xxx"
      #     comment = "xxx" # optional
      #   }
    }
  }
}
variable "dhcp_server" {
  default = {
    # iface          = "bridge"
    # lease_time     = "8h"
    # ip_pool_ranges = ["10.10.10.10-10.10.10.20"]
    # network_prefix = "10.10.10"
  }
}
variable "dhcp_server_options" {
  default = {
    timezone = {
      code  = 2
      value = "0xFFFFD5D0"
    }
  }
}
variable "domain" {
  description = "Network domain"
  type        = string
  default     = ""
}
variable "enable_transparent_proxy" {
  description = "Whether to redirect tcp/80 to the proxy"
  type        = bool
  default     = false
}

variable "firewall" {
  default = {
    input   = [],
    forward = [],
    nat = [
      {
        masquerade = {
          position           = 999
          action             = "masquerade"
          out_interface_list = "WAN"
          ipsec_policy       = ["out", "none"]
        }
      }
    ],
    mangle = [],
  }
}
variable "interfaces" {
  default = {
    # home = {
    #   ip = "aaa.bbb.ccc.ddd/eee"
    #   iface = "etherX"
    #   network = "aaa.bbb.ccc.xxx" # optional
    #   dhcp = {
    #     iface = 
    #   }
    #   comment = "Some optional comment"
  }
}
variable "ip_cloud" {
  description = "Mikrotik's IP cloud service configuration"
  default = {
    ddns_enabled         = true
    update_time          = true
    ddns_update_interval = "5m"
  }
}
variable "name" {
  description = "Router name"
  type        = string
}
variable "routing" {
  description = "Routing related stuff (routes, rules)"
  default = {
    # rules = {}
    # routes = {
    #   provider = {
    #     gateway  = "192.168.1.1"
    #     pref_src = "192.168.1.200"
    #   }
    # }
  }
}
variable "scripts" {
  description = "Map of scripts to apply"
  type        = map(any)
  default = {
    # instance name will be converted to script name
    # "auto-upgrade" = {
    #   # Map of vars to apply to the script
    #   vars = {
    #     admin_email = "script-notifications@your.domain"
    #   }
    #   # List of policies
    #   policies = ["read", "write", "test", "policy"]
    # }
  }
}
variable "users" {
  description = "System's Users"
  type        = map(any)
  default = {
    admin = {
      address = "www.xxx.yyy.zzz/24" # ie, your internal network ip
      group   = "full"
    },
  }
}
variable "vlans" {
  type = map(any)
  default = {
    # guests = {
    #   ip = "aaa.bbb.ccc.ddd/eee"
    #   iface = "etherX"
    #   network = "aaa.bbb.ccc.xxx" # optional
    #   comment = "Some optional comment"
  }
}
variable "wifi" {
  description = "Configuration for wifi interfaces"
  type        = map(any)
  default     = {}
}
variable "wireguard_ifaces" {
  type = map(any)
  default = {
    # some-wg-server = {
    #   listen_port = 12345
    #   comment = "Some optional comment"
  }
}
variable "wireguard_peers" {
  default = {
    # some-peer = {
    #   iface            = "interface-peer"
    #   endpoint_address = "aaa.bbb.ccc.ddd"
    #   endpoint_port    = 56789
    #   public_key       = "fsdfsf...Y="
    #   preshared_key    = " dfsdfsdfs...HE="
    #   allowed_address = [
    #     "aaa.bbb.ccc.ddd/24",
    #     "eee.fff.ggg.hhh/24",
    #   ]
    #   persistent_keepalive = "25s"
    #   comment              = "Some comment"
  }
}

variable "malicious_contents_filtering" {
  description = "Filter malicious content using Steven Black's hosts list (default fakenews, porn, gambling, malicious contents)"
  default = {
    enabled      = false,
    filters_urls = ["https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling-porn/hosts"]
  }
}
