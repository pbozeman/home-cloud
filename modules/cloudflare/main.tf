terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4"
    }
  }
}

# cloudkey

resource "cloudflare_record" "cloudkey" {
  zone_id = var.zone_id
  name    = "cloudkey"
  value   = var.cloudkey_ip
  type    = "A"
  proxied = false
}

# the round robin dns for the pve cluster
resource "cloudflare_record" "pve" {
  for_each = var.pve_nodes

  zone_id = var.zone_id
  name    = "pve"
  value   = each.value.ip
  type    = "A"
  proxied = false
}

# each pve node
resource "cloudflare_record" "pve_node" {
  for_each = var.pve_nodes

  zone_id = var.zone_id
  name    = each.key
  value   = each.value.ip
  type    = "A"
  proxied = false
}
