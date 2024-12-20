terraform {
  required_providers {
    routeros = {
      source = "terraform-routeros/routeros"
      # version = "1.75"
    }
  }
}

provider "routeros" {
  hosturl  = var.api.hosturl
  username = lookup(var.api, "username", "admin")
  password = var.api.password
  insecure = lookup(var.api, "insecure", false)
}
