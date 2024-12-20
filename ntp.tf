resource "routeros_system_ntp_server" "ros" {
  enabled         = true
  broadcast       = false
  multicast       = false
  manycast        = false
  use_local_clock = false
}

resource "routeros_system_ntp_client" "ros" {
  enabled = true
  mode    = "unicast"
  servers = [
    "0.pool.ntp.org",
    "1.pool.ntp.org",
  ]
}