#!/bin/sh

set -e

# Navigate to the directory of this script
cd "$(dirname "$(readlink -f "$0")")"
cd ..

sops -d secret.tfvars > terraform.tfvars
terraform $@
