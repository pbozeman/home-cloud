# manual steps:
#   enable Snippet storage on local
#   enable images on local

terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.40.0"
    }
  }
}
