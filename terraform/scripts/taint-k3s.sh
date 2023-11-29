#!/bin/sh

# Navigate to the directory of this script
cd $(dirname $(readlink -f $0))
cd ..

# Find all state resources matching the pattern
resource_pattern="module.vms.proxmox_virtual_environment_vm.nixos_vms\[\"k3s-.*\"\]"
matching_states=($(terraform state list | grep -E "$resource_pattern"))

for state in "${matching_states[@]}"; do
  terraform taint "$state"
done