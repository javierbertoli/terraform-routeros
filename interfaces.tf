### BRIDGING
resource "routeros_interface_bridge" "ros" {
  for_each       = { for i, p in var.interfaces : i => p if try(p.type, false) == "bridge" && try(p.create_iface, true) }
  name           = lookup(each.value, "name", each.key)
  vlan_filtering = lookup(each.value, "vlan_filtering", false)
  disabled       = lookup(each.value, "disable", false)
  comment        = upper("tf - ${lookup(each.value, "comment", each.key)}")
}

resource "routeros_interface_bridge_port" "ros" {
  for_each  = { for i, p in var.interfaces : i => p if contains(keys(p), "bridge") }
  bridge    = each.value.bridge
  interface = each.value.iface
  pvid      = lookup(each.value, "pvid", 1)
  comment   = upper("tf - ${lookup(each.value, "comment", each.key)}")
  depends_on = [
    routeros_interface_bridge.ros
  ]
}

### PPPOE-clients
resource "routeros_interface_pppoe_client" "ros" {
  for_each          = { for i, p in var.interfaces : i => p if try(p.type, false) == "pppoe-client" && try(p.create_iface, true) }
  interface         = each.value.iface
  name              = lookup(each.value, "name", each.key)
  user              = each.value.user
  password          = each.value.password
  disabled          = lookup(each.value, "disable", false)
  add_default_route = lookup(each.value, "add_default_route", true)
  profile           = lookup(each.value, "profile", "default-encryption")
  use_peer_dns      = lookup(each.value, "use_peer_dns", true)
  comment           = upper("tf - ${lookup(each.value, "comment", each.key)}")
}

### REGULAR INTERFACES
resource "routeros_interface_ethernet" "ros" {
  for_each     = { for i, p in var.interfaces : i => p if try(p.type, "ethernet") == "ethernet" && try(p.create_iface, true) }
  factory_name = lookup(each.value, "factory_name", try(each.value.iface, each.key))
  name         = lookup(each.value, "name", try(each.value.iface, each.key))
  mtu          = lookup(each.value, "mtu", 1500)
  disabled     = lookup(each.value, "disable", false)
  comment      = upper("tf - ${lookup(each.value, "comment", each.key)}")
}

### INTERFACES LISTS
resource "routeros_interface_list" "ros" {
  for_each = toset(local.interfaces_lists)
  name     = each.key
  comment  = upper("tf - ${each.key}")
}

resource "routeros_interface_list_member" "ros" {
  for_each  = local.interfaces_lists_members
  interface = lookup(each.value, "name", try(each.value.iface, each.key))
  list      = each.value.list
  comment   = upper("tf - ${lookup(each.value, "comment", each.key)}")
  depends_on = [
    routeros_interface_ethernet.ros,
    routeros_interface_bridge.ros,
    routeros_interface_vlan.ros,
    routeros_interface_wireguard.ros,
    routeros_interface_wireguard_peer.ros
  ]
}

### VLANS
resource "routeros_interface_vlan" "ros" {
  for_each  = var.vlans
  name      = each.key
  interface = each.value.iface
  vlan_id   = each.value.id
  comment   = upper("tf - ${lookup(each.value, "comment", each.key)}")
}

### IPS
resource "routeros_ip_address" "ros" {
  for_each  = local.ip_addresses
  address   = each.value.ip
  interface = each.value.iface
  network   = lookup(each.value, "network", cidrhost(each.value.ip, 0))
  comment   = upper("tf - ${lookup(each.value, "comment", each.key)}")
  depends_on = [
    routeros_interface_bridge.ros,
    routeros_interface_ethernet.ros,
    routeros_interface_wireguard.ros,
  ]
}