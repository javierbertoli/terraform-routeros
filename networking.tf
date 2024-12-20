### ROUTING
resource "routeros_routing_table" "ros" {
  for_each = local.routing_tables
  name     = each.key
  fib      = each.value.fib
  comment  = upper("tf - ${lookup(each.value, "comment", "table to ${each.key}")}")
}

resource "routeros_ip_route" "ros" {
  for_each      = local.routing_routes
  disabled      = lookup(each.value, "disabled", false)
  dst_address   = lookup(each.value, "dst_address", "0.0.0.0/0")
  gateway       = each.value.gateway
  routing_table = lookup(each.value, "routing_table", null)
  distance      = lookup(each.value, "distance", "1")
  pref_src      = lookup(each.value, "pref_src", null)
  comment       = upper("tf - ${lookup(each.value, "comment", each.key)}")
  check_gateway = lookup(each.value, "check_gateway", "ping")
  depends_on = [
    routeros_ip_address.ros,
    routeros_routing_table.ros,
  ]
}

resource "routeros_routing_rule" "ros" {
  for_each     = local.routing_rules
  disabled     = lookup(each.value, "disabled", false)
  action       = lookup(each.value, "action", "lookup-only-in-table")
  comment      = upper("tf - ${lookup(each.value, "comment", each.key)}")
  dst_address  = lookup(each.value, "dst_address", null)
  interface    = lookup(each.value, "interface", null)
  routing_mark = lookup(each.value, "routing_mark", null)
  src_address  = lookup(each.value, "src_address", null)
  table        = routeros_routing_table.ros[each.value.table].name
}

### FIREWALLING
resource "routeros_ip_firewall_addr_list" "ros" {
  for_each = local.addresses_lists
  disabled = lookup(each.value, "disabled", false)
  address  = each.value.address
  list     = each.value.list
  comment  = upper("tf - ${lookup(each.value, "comment", each.key)}")
}

resource "routeros_ip_firewall_filter" "input" {
  for_each             = local.firewall_input_rules
  action               = lookup(each.value, "action", "accept")
  chain                = "input"
  disabled             = try(each.value.disabled, false)
  connection_mark      = lookup(each.value, "connection_mark", null)
  connection_state     = try(join(",", each.value.connection_state), null)
  connection_nat_state = lookup(each.value, "connection_nat_state", null)
  dst_address          = lookup(each.value, "dst_address", null)
  dst_address_list     = lookup(each.value, "dst_address_list", null)
  dst_port             = try(join(",", each.value.dst_port), null)
  hw_offload           = lookup(each.value, "hw_offload", null)
  in_interface         = lookup(each.value, "in_interface", null)
  in_interface_list    = lookup(each.value, "in_interface_list", null)
  limit                = lookup(each.value, "limit", null)
  log                  = lookup(each.value, "log", false)
  log_prefix           = try(each.value.log, false) ? upper(try(each.value.log_prefix, replace(each.key, "_", " "))) : null
  out_interface        = lookup(each.value, "out_interface", null)
  out_interface_list   = lookup(each.value, "out_interface_list", null)
  packet_mark          = lookup(each.value, "packet_mark", null)
  protocol             = lookup(each.value, "protocol", "tcp")
  routing_mark         = lookup(each.value, "routing_mark", null)
  reject_with          = lookup(each.value, "reject_with", null)
  src_address          = lookup(each.value, "src_address", null)
  src_address_list     = lookup(each.value, "src_address_list", null)
  comment              = upper("tf-${format("%04d", each.value.position)} - ${try(each.value.comment, replace(each.key, "_", " "))}")
}

resource "routeros_move_items" "fw_rules_filter_input" {
  count         = length(local.firewall_filter_input_rules_sorted) > 0 ? 1 : 0
  resource_name = "routeros_ip_firewall_filter"
  # resource_path = "/ip/firewall/filter"
  sequence   = [for i, r in local.firewall_filter_input_rules_sorted : routeros_ip_firewall_filter.input[r].id]
  depends_on = [routeros_ip_firewall_filter.input]
}

resource "routeros_ip_firewall_filter" "forward" {
  for_each             = local.firewall_forward_rules
  action               = lookup(each.value, "action", "accept")
  chain                = "forward"
  disabled             = try(each.value.disabled, false)
  connection_mark      = lookup(each.value, "connection_mark", null)
  connection_state     = try(join(",", each.value.connection_state), null)
  connection_nat_state = lookup(each.value, "connection_nat_state", null)
  dst_address          = lookup(each.value, "dst_address", null)
  dst_address_list     = lookup(each.value, "dst_address_list", null)
  dst_port             = try(join(",", each.value.dst_port), null)
  hw_offload           = lookup(each.value, "hw_offload", null)
  in_interface         = lookup(each.value, "in_interface", null)
  in_interface_list    = lookup(each.value, "in_interface_list", null)
  limit                = lookup(each.value, "limit", null)
  log                  = lookup(each.value, "log", false)
  log_prefix           = try(each.value.log, false) ? upper(try(each.value.log_prefix, each.key)) : null
  out_interface        = lookup(each.value, "out_interface", null)
  out_interface_list   = lookup(each.value, "out_interface_list", null)
  packet_mark          = lookup(each.value, "packet_mark", null)
  place_before         = lookup(each.value, "place_before", null)
  protocol             = lookup(each.value, "protocol", "tcp")
  routing_mark         = lookup(each.value, "routing_mark", null)
  reject_with          = lookup(each.value, "reject_with", null)
  src_address          = lookup(each.value, "src_address", null)
  src_address_list     = lookup(each.value, "src_address_list", null)
  comment              = upper("tf-${format("%04d", each.value.position)} - ${try(each.value.comment, replace(each.key, "_", " "))}")
}

resource "routeros_move_items" "fw_rules_filter_forward" {
  count         = length(local.firewall_filter_forward_rules_sorted) > 0 ? 1 : 0
  resource_name = "routeros_ip_firewall_filter"
  sequence      = [for i, r in local.firewall_filter_forward_rules_sorted : routeros_ip_firewall_filter.forward[r].id]
  depends_on    = [routeros_ip_firewall_filter.forward]
}

resource "routeros_ip_firewall_nat" "ros" {
  for_each          = local.firewall_nat_rules
  action            = lookup(each.value, "action", "accept")
  chain             = lookup(each.value, "chain", "srcnat")
  comment           = upper("tf-${format("%04d", each.value.position)} - ${try(each.value.comment, replace(each.key, "_", " "))}")
  disabled          = lookup(each.value, "disabled", false)
  dst_address_list  = lookup(each.value, "dst_address_list", null)
  dst_address_type  = lookup(each.value, "dst_address_type", null)
  dst_port          = try(join(",", each.value.dst_port), null)
  to_ports          = try(join(",", each.value.to_ports), null)
  ipsec_policy      = try(join(",", each.value.ipsec_policy), null)
  in_interface      = lookup(each.value, "in_interface", null)
  in_interface_list = lookup(each.value, "in_interface_list", null)
  out_interface     = lookup(each.value, "out_interface", null)
  out_interface_list = (
    lookup(each.value, "chain", "srcnat") == "dstnat"
    ? null
    : (try(each.value.out_interface, "") == ""
      ? lookup(each.value, "out_interface_list", "WAN")
      : null
    )
  )
  protocol         = lookup(each.value, "protocol", null)
  src_address      = lookup(each.value, "src_address", null)
  src_address_list = lookup(each.value, "src_address_list", null)
  to_addresses     = lookup(each.value, "to_addresses", null)
}

resource "routeros_move_items" "fw_rules_nat" {
  count         = length(local.firewall_nat_rules_sorted) > 0 ? 1 : 0
  resource_name = "routeros_ip_firewall_nat"
  sequence      = [for i, r in local.firewall_nat_rules_sorted : routeros_ip_firewall_nat.ros[r].id]
  depends_on    = [routeros_ip_firewall_nat.ros]
}

resource "routeros_ip_firewall_mangle" "ros" {
  for_each            = local.firewall_mangle_rules
  action              = lookup(each.value, "action", null)
  chain               = lookup(each.value, "chain", null)
  connection_mark     = lookup(each.value, "connection_mark", null)
  in_interface        = lookup(each.value, "in_interface", null)
  in_interface_list   = lookup(each.value, "in_interface_list", null)
  new_connection_mark = lookup(each.value, "new_connection_mark", null)
  new_routing_mark    = lookup(each.value, "new_routing_mark", null)
  passthrough         = lookup(each.value, "passthrough", null)
  out_interface       = lookup(each.value, "out_interface", null)
  protocol            = lookup(each.value, "protocol", null)
  tcp_flags           = lookup(each.value, "tcp_flags", null)
  comment             = upper("tf-${format("%04d", each.value.position)} - ${try(each.value.comment, replace(each.key, "_", " "))}")
  depends_on = [
    routeros_ip_address.ros,
    routeros_routing_rule.ros,
    routeros_ip_dhcp_client.ros,
  ]
}

resource "routeros_move_items" "fw_rules_mangle" {
  count         = length(local.firewall_mangle_rules_sorted) > 0 ? 1 : 0
  resource_name = "routeros_ip_firewall_mangle"
  sequence      = [for i, r in local.firewall_mangle_rules_sorted : routeros_ip_firewall_mangle.ros[r].id]
  depends_on    = [routeros_ip_firewall_mangle.ros]
}
