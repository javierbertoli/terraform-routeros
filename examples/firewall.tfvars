### ADDRESSES LISTS
addresses_lists = {
  EMERGENCY_ACCESS = [
    "1.2.3.4",
    "5.6.7.8"
  ]
  WANT_TO_BLOCK_THIS_ONE = [
    "186.12.4.1"
  ]
  ADMINS = [
    "192.168.1.2", # Javier
    "192.168.1.3", # John
  ]
}

### FIREWALL
### POSITION has to be a value between 100 and 900. Values <100 and >900 are used for automatically added rules.
firewall = {
  ################################
  ### MANGLE
  mangle = [
    {
      test = {
        position = 20
        chain    = "prerouting"
        action   = "accept"
      }
    }
  ]
  ################################
  ### INPUT
  input = [
    {
      emergency_access_rule = {
        position         = 0
        action           = "accept"
        disabled         = true
        protocol         = null
        src_address_list = "EMERGENCY_ACCESS"
      },
    },
    {
      crowdsec_drop = {
        position         = 100
        action           = "drop"
        src_address_list = "CROWDSEC-DROP"
        log              = true
        protocol         = null
      },
    },
    {
      fail2ban_drop = {
        position         = 105
        action           = "drop"
        src_address_list = "FAIL2BAN-DROP"
        log              = true
        protocol         = null
      },
    },
    {
      wireguard = {
        position = 110
        protocol = "udp"
        dst_port = ["1234"]
      },
    },
    {
      admins = {
        position          = 115
        action            = "accept"
        protocol          = null
        in_interface_list = "VPN"
        src_address_list  = "ADMINS"
      },
    },
    {
      intranet_to_dns_dhcp_and_ntp = {
        position          = 120
        protocol          = "udp"
        in_interface_list = "LAN"
        dst_port = [
          "53",
          "67-68",
          "123"
        ]
      },
    },
    {
      fail2ban_access = {
        position         = 125
        src_address_list = "FAIL2BAN-ACCESS"
        dst_port         = ["22"]
        connection_state = ["new"]
      },
    },
    {
      letsencrypt_access = {
        position         = 130
        src_address_list = "LETSENCRYPT-ACCESS"
        dst_port         = ["22"]
        connection_state = ["new"]
      },
    },
    {
      snmp_access = {
        position         = 135
        src_address_list = "SNMP-ACCESS"
        protocol         = "udp"
        dst_port         = ["161"]
      },
    },
  ]
  ################################
  ### FORWARD
  forward = [
    {
      fail2ban_drop = {
        position         = 145
        action           = "drop"
        src_address_list = "FAIL2BAN-DROP"
        log              = true
        protocol         = null
      },
    },
    {
      crowdsec_drop = {
        position         = 140
        action           = "drop"
        src_address_list = "CROWDSEC-DROP"
        log              = true
        protocol         = null
      },
    },
    {
      accepted_ports_from_lan = {
        position         = 155
        src_address_list = "INTRANET"
        protocol         = "tcp"
        dst_port         = ["22"]
      },
    }
  ]
  ################################
  ### NAT
  nat = [
    {
      incoming_to_hosts = {
        position         = 100
        chain            = "dstnat"
        action           = "dst-nat"
        src_address_list = "INCOMING.hosts"
        to_addresses     = "10.10.10.4"
        protocol         = "tcp"
        dst_port         = ["4500-4600"]
      },
    },
  ]
}
