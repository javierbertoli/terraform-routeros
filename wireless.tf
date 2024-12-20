resource "routeros_interface_wireless_security_profiles" "default" {
  # Can't be disabled nor renamed, so I add a key here
  count               = local.router_has_wifi ? 1 : 0
  name                = "default"
  wpa_pre_shared_key  = "n0 qu3rem0s que se us3 6st4 profile"
  wpa2_pre_shared_key = "n0 qu3rem0s que se us3 6st4 profile"
}
resource "routeros_interface_wireless_security_profiles" "ros" {
  for_each = var.wifi
  name     = each.key
  mode     = "dynamic-keys"
  authentication_types = [
    "wpa-psk",
    "wpa2-psk",
  ]
  wpa_pre_shared_key  = try(each.value.wpa_pre_shared_key, null)
  wpa2_pre_shared_key = try(each.value.wpa2_pre_shared_key, null)

  group_ciphers    = "aes-ccm"
  group_key_update = "00:05:00"
}

resource "routeros_interface_wireless" "ros" {
  for_each                = var.wifi
  disabled                = lookup(each.value, "disabled", true)
  mode                    = lookup(each.value, "mode", "ap-bridge")
  adaptive_noise_immunity = "ap-and-client-mode"
  frequency_mode          = "regulatory-domain"
  country                 = "argentina"
  installation            = lookup(each.value, "installation", "indoor")
  security_profile        = resource.routeros_interface_wireless_security_profiles.ros[each.key].name
  master_interface        = lookup(each.value, "master_interface", null)
  name                    = each.key
  ssid                    = each.value.ssid
  compression             = true
  depends_on = [
    resource.routeros_interface_wireless_security_profiles.ros
  ]
}