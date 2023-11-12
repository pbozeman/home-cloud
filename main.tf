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
