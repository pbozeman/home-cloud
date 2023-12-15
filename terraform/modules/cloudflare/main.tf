terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4"
    }
  }
}

locals {
  # Flatten the round robin map into a list of objects with key and value
  flattened_round_robin = flatten([
    for key, values in var.round_robin : [
      for value in values : {
        key   = key
        value = value
      }
    ]
  ])
}

resource "cloudflare_record" "host" {
  for_each = var.hosts

  zone_id = var.zone_id
  name    = each.key
  value   = each.value.ip
  type    = "A"
  proxied = false
}

# FIXME: the current variable/module setup for this is creating the round
# robin entries for pve before nodes have been added to the cluster.
resource "cloudflare_record" "round_robin" {
  for_each = { for item in local.flattened_round_robin : "${item.key}-${item.value}" => item }

  zone_id = var.zone_id
  name    = each.value.key
  value   = each.value.value
  type    = "A"
  proxied = false
}

output "ids" {
  value = [for v in values(cloudflare_record.host) : v.id]
}
