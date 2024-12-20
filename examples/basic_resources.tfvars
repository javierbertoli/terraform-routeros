# Mikrotik host name
name = "MK-1"

# Domain to use for internal network resources (DNS, DHCP, etc.)
domain = "my.local"
api = {
  hosturl  = "https://10.10.10.1:4443"
  password = "your_mk_user_password"
  insecure = true # Required unless you upload a valid certificate.
}
