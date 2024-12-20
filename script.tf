resource "routeros_system_script" "ros" {
  for_each = var.scripts
  name     = replace(each.key, "_", "-")
  source   = templatefile("${path.module}/files/${each.key}.tftpl", each.value.vars)
  policy = lookup(each.value, "policies", [
    "read",
    "write",
    "test",
    "policy",
    "ftp",
    "password",
    "reboot",
    "sensitive",
    "sniff",
    ]
  )
}