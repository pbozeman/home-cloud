#!/bin/sh

set -e

# Navigate to the directory of this script
cd "$(dirname "$(readlink -f "$0")")"
cd ..

TEMP_TFVARS="$(mktemp).tfvars"
trap "rm -f $TEMP_TFVARS" EXIT
sops -d secret.tfvars >"$TEMP_TFVARS"
terraform $@ -var-file="$TEMP_TFVARS"
