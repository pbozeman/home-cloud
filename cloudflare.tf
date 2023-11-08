provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

resource "cloudflare_record" "cloudkey-01" {
  zone_id = var.cloudflare_zone_id
  name    = "cloudkey-01"
  value   = var.cloudkey_01_ip
  type    = "A"
  proxied = false
}

resource "cloudflare_record" "pve-01" {
  zone_id = var.cloudflare_zone_id
  name    = "pve-01"
  value   = var.pve_01_ip
  type    = "A"
  proxied = false
}
