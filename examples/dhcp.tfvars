### DHCP SERVER
dhcp_server = {
  intranet = {
    iface          = "ether1"
    lease_script   = "dhcp_lease_script" # This nice script adds DNS entries for each lease
    ip_pool_ranges = ["192.168.1.20-192.168.1.100"]
    network_prefix = "192.168.1"
    gateway_host   = "1"
    dns_servers    = ["192.168.1.1"]
    ntp_servers    = ["192.168.1.1"]
    static_leases = [
      {
        webserver = {
          ip  = "192.168.1.2"
          mac = "00:48:21:d4:5c:61"
        }
      },
      {
        dbserver = {
          ip  = "192.168.1.3"
          mac = "00:d2:12:d6:af:c5"
        }
      },
      {
        cmp = { ip = "192.168.1.46" }
      },
      {
        laptop = { ip = "192.168.1.47" }
      },
    ]
  }
}