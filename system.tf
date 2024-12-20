resource "routeros_system_identity" "ros" {
  name = var.name
}

resource "routeros_ip_cloud" "ros" {
  ddns_enabled         = var.ip_cloud.ddns_enabled
  update_time          = var.ip_cloud.update_time
  ddns_update_interval = var.ip_cloud.ddns_update_interval
}

resource "routeros_system_user" "ros" {
  for_each = var.users
  name     = each.key
  disabled = lookup(each.value, "disabled", false)
  address  = lookup(each.value, "address", null)
  group    = lookup(each.value, "group", "read")
  password = lookup(each.value, "password", "")
  comment  = lookup(each.value, "comment", "${upper(each.key)}")
}