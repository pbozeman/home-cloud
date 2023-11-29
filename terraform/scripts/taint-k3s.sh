#!/bin/sh

set -e

# Navigate to the directory of this script
cd "$(dirname "$(readlink -f "$0")")"
cd ..

# Function to taint resources based on a given pattern
taint_resources() {
	local resource_pattern="$1"
	local matching_states=($(terraform state list | grep -E "$resource_pattern" || true))

	if [ ${#matching_states[@]} -eq 0 ]; then
		return
	fi

	for state in "${matching_states[@]}"; do
		terraform taint "$state"
	done
}

# Taint VMs
vm_pattern="module.vms.proxmox_virtual_environment_vm.nixos_vms\[\"k3s-.*\"\]"
taint_resources "$vm_pattern"

# Taint k3s deployment
k3s_pattern="module.k3s.null_resource.deploy\[\"k3s-.*\"\]"
taint_resources "$k3s_pattern"
