### USERS
users = {
  admin = {
    group = "full"
  }
  # This user allows a fail2ban host to block at the MK level
  fail2ban-user = {
    address = "192.168.1.2/32"
    group   = "full"
  }
  javier = {
    group = "full"
  }
  # This allows a host to get a certificate for the MK and upload it
  letsencrypt-user = {
    address = "192.168.1.215/32"
    group   = "full"
  }
  john = {
    group = "monitor"
  }
  mike = {
    group = "read"
  }
}
