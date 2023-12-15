# manual steps:
#   enable Snippet storage on local
#   enable images on local

# TODO: the host level modifications of the hypervisor/pve
# nodes would likely be handled a lot better with ansible.
# This module is starting to collect a lot of adhoc file
# updates etc.. and, this would provide a way to automate
# repo updates, etc.

terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.40.0"
    }
  }
}
