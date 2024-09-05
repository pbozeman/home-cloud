# nix needs the file checked in, but this will get overwritten from template
# expansion. To make git ignore changes:
#
#  git update-index --assume-unchanged modules/vms_nixos/nixos/flake.nix
#
# TODO: add the above command to some sort of local git init script that
# inits things that aren't part of the actual sync'd repo.
