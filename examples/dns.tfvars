domain = "my.local"

### DNS
dns = {
  forwarders = "quad9"
  records = {
    api = {
      type  = "CNAME"
      cname = "web"
    }
    "remote-01" = {
      type  = "CNAME"
      cname = "anothermk.sn.mynetname.net."
    }
    "remote-02" = {
      type  = "CNAME"
      cname = "aaaaandanothermk.sn.mynetname.net."
    }
    cmp = { target = "192.168.1.4" }
    web = { target = "192.168.1.15" }
    db  = { target = "192.168.1.21" }
    ntp = { target = "192.168.1.1" }
  }
}