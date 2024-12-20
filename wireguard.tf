resource "routeros_interface_wireguard" "ros" {
  for_each    = local.wireguard_servers
  name        = lookup(each.value, "name", each.key)
  listen_port = each.value.listen_port
  mtu         = lookup(each.value, "mtu", 1420)
  comment     = upper("tf - ${lookup(each.value, "comment", each.key)}")
}
resource "routeros_interface_wireguard_peer" "ros" {
  for_each  = var.wireguard_peers
  interface = "wireguard-${each.value.iface}"
  is_responder = (
    each.value.iface == "server"
    ? true
    : false
  )
  name             = lookup(each.value, "name", each.key)
  public_key       = each.value.public_key
  preshared_key    = each.value.preshared_key
  allowed_address  = each.value.allowed_address
  disabled         = lookup(each.value, "disabled", false)
  endpoint_address = lookup(each.value, "endpoint_address", null)
  endpoint_port    = lookup(each.value, "endpoint_port", null)
  # https://github.com/terraform-routeros/terraform-provider-routeros/issues/142
  # Also, persistent keepalive should not be enabled on the server, or it will try to ping the endpoint
  # even if not connected
  persistent_keepalive = lookup(each.value, "persistent_keepalive", "0s")
  comment              = upper("tf - ${lookup(each.value, "comment", each.key)}")
}
