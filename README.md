# home-cloud

## Overview / Work in Progress

My home server that was running a bunch of ad hoc VMs died. Rather than rebuilding it manually, I decided to re-create the VM environment with terraform and then bring up a
k3s cluster for running apps.

Infra should be a single 'terraform apply' to be fully configured.

Apps should be a single 'helmfile apply' to be fully launched.

Currently completed:

- Network:

  - vlans
  - subnets
  - wlans
  - firewall rules
  - cloudflare dns

- Virtualization:

  - ubuntu cloud init template
  - ubuntu dev instance
  - nixos cloud init template
  - nix os dev instance
  - k3s cluster

- K3s:
  - all the usual, prometheus, nginx-ingress, etc.
  - private docker repo
  - Beginnings of a working k3s homeasistant with injected configs
