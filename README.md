# home-cloud

## Overview / Work in Progress

This repo contains the configuration of my home network and apps and
services that run on it. It is:

- **declarative** fully declarative using Terraform, NixOS, and Helmfile.
- **ephemeral**: the entire system can be wiped and will rebuilt from the
  declarative configuration. Persistent application state is restored from
  snapshots.
- **full stack**: declarative configuration includes:
  - **network infrstructure**: vlans, static-ip, dns, firewall rules, etc
  - **virtualization infrastructure**: Proxmox clustering, vm provisioning
  - **NAS infrastructure**: nfs/smb shares, zfs provisioning, hba pci-passthrough
  - **K3s infrastructure**: multi-server k3s cluster,
    Longhorn block storage, CertManager, etc
  - **apps:** home-automation, media services, document management, etc
  - **offsite backup**: file level backup of NAS zfs datasets,
    block level backup of Longhorn volumes.

It's still a work in progress. Most of the work was done as I was learning
Terraform and Helmfile, and a lot of it is in need of a refactoring, and
other bits that I think are in good shape, very well may not be due
to my lack of experience with the stack.
