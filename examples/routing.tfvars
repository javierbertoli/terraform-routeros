##### ROUTING
routing = {
  routes = {
    one_place = {
      gateway     = "192.168.2.1"
      pref_src    = "192.168.2.2"
      dst_address = "10.20.30.0/24"
    },
  }
  rules = {
    wireguard_loopback = {
      action      = "lookup-only-in-table"
      table       = "to_ether8"
      src_address = "10.255.255.1/32"
    },
  }
}
