terraform {
  backend "remote" {
    organization = "bozeman"

    workspaces {
      name = "home-network"
    }
  }

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.1"
    }
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.37.0"
    }
    remote = {
      source  = "tenstad/remote"
      version = "0.1.2"
    }
    unifi = {
      source  = "paultyng/unifi"
      version = "0.41.0"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

provider "proxmox" {
  endpoint = var.proxmox_endpoint
  username = var.proxmox_username
  password = var.proxmox_password
  insecure = true
  tmp_dir  = "/var/tmp"
}

provider "unifi" {
  username = var.unifi_username
  password = var.unifi_password
  api_url  = var.unifi_api_url

  # FIXME: install certs
  allow_insecure = true
}
