
### INTERFACES
interfaces = {
  intranet = {
    ip = [
      "10.10.10.1/24", # Intranet
      "10.20.10.1/24", # Another subnet
    ]
    iface = "ether1"
    list  = ["LAN"] # Interfaces' list to which this interface belongs
  },
  intermk = {
    ip      = "192.168.88.2/24"
    iface   = "ether7"
    disable = true
  },
  isp_one = {
    ip       = "1.2.3.5/30"
    gateway  = "1.2.3.6"
    distance = "2"
    iface    = "ether8"
    comment  = "Provider ONE"
    list     = ["WAN"]
  },
  isp_two = {
    ip      = "5.6.7.8/24"
    gateway = "5.6.7.1"
    iface   = "ether10"
    list    = ["WAN"]
  },
  loopback = {
    ip    = "10.255.255.1/32"
    iface = "lo"
    type  = "loopback"
  }
}
