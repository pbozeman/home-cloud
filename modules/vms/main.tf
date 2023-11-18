terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.38.1"
    }
  }
}

output "done" {
  value = "done"
}
