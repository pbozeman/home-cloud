#!/bin/sh

set -e

top="$(dirname $(readlink -f $0))/"
vm_tf="$top"/terraform/modules/vms/nixos_vms.tf
retry_interval=5
max_retries=3

trap cleanup EXIT ERR

main() {
	# taint k3s and rebuild the vms
	cd "$top"/terraform
	scripts/taint-k3s.sh

	disable_prevent_destroy
	retry "scripts/terraform-sops.sh apply -auto-approve"
	enable_prevent_destroy

	# reinstall software stack
	# since this is the "first" install of the cluster, sync is required
	# otherwise helmfile diff gets confused by missing crds and
	# disableValidation was causing issues down the road.
	cd "$top"/helmfile
	retry "helmfile sync"
}

cleanup() {
	enable_prevent_destroy
}

enable_prevent_destroy() {
	sed -i 's/prevent_destroy = false/prevent_destroy = true/' "$vm_tf" || true
}

disable_prevent_destroy() {
	sed -i 's/prevent_destroy = true/prevent_destroy = false/' "$vm_tf" || true
}

# Ideally the underlying providers in terraform and helm charts would
# fully handle errors and retry logic, but sometimes resources that others
# depend on are not fully ready, even if the providers think they are. We end
# up with "no route to host", or a 503 from nginx during ingress creation, etc.
# Since everything is idempotent, just redo the command and both terraform
# and helmfile will figure things out and continue from where they left off.
retry() {
	local n=1
	local cmd="$1"
	while [ "$n" -le "$max_retries" ]; do
		echo "Attempt $n/$max_retries: '$cmd'"
		if $cmd; then
			break
		else
			if [ "$n" -lt "$max_retries" ]; then
				n=$((n + 1))
				echo "Command failed: '$cmd'. Attempt $n/$max_retries in $retry_interval seconds..."
				sleep "$retry_interval"
			else
				echo "The command has failed after $max_retries attempts: '$cmd'"
				return 1
			fi
		fi
	done
}

main
