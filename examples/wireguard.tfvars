### INTERFACES
interfaces = {
  wireguard-server = {
    ip          = "10.10.10.1/24"
    type        = "wireguard"
    listen_port = 1234
    comment     = "Wireguard SERVER"
    list = [
      "LAN",
      "VPN",
    ]
  },
}

### WIREGUARD
wireguard_peers = {
  "javier" = {
    iface         = "server"
    public_key    = "2...2Iq9="
    preshared_key = "Dq...wj/M="
    allowed_address = [
      "10.10.10.2/32",
    ]
  }
  "john" = {
    iface         = "server"
    public_key    = "0k...e3k="
    preshared_key = "6m+...yy="
    allowed_address = [
      "10.10.10.3/32",
      "192.168.100.0/24",
    ]
  }
}