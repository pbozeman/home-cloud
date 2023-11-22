{ config,
  lib,
  pkgs,
  modulesPath,
  hostname,
  is_first_host,
  first_host,
  ... }: {

  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  time.timeZone = "America/Los_Angeles";

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/vda";

  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "sr_mod" "virtio_blk" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = { 
    device = "/dev/vda3";
    fsType = "ext4";
  };

  fileSystems."/boot" = { 
    device = "/dev/vda2";
    fsType = "vfat";
  };

  fileSystems."/var/lib/longhorn" = {
    device = "/dev/vdb";
    fsType = "ext4";
    autoFormat = true;
  };

  swapDevices = [];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  networking.hostName = "";
  networking.useNetworkd = true;

  services.cloud-init.enable = true;
  services.cloud-init.network.enable = true;
  services.qemuGuest.enable = true;

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  services.openiscsi.enable = true;
  services.openiscsi.name = "iqn.2023-21.local:${hostname}";

  services.k3s = {
    enable = true;
    role = "server";
    token = "FIXMEthisisnotrandom";
    clusterInit = is_first_host;
    serverAddr = if is_first_host == false then "https://${first_host}:6443" else "";
    extraFlags = "--disable=traefik --disable=local-storage";
  };

  networking.firewall.allowedTCPPorts = [
    6443 # k3s: required so that pods can reach the API server (running on port 6443 by default)
    2379 # k3s, etcd clients: required if using a "High Availability Embedded etcd" configuration
    2380 # k3s, etcd peers: required if using a "High Availability Embedded etcd" configuration
  ];
  networking.firewall.allowedUDPPorts = [
    8472 # k3s, flannel: required if using multi-node for inter-node networking
  ];

  environment.systemPackages = with pkgs; [
    jq
  ];

  # https://github.com/longhorn/longhorn/issues/2166
  systemd.tmpfiles.rules = [
    "L+ /usr/local/bin - - - - /run/current-system/sw/bin/"
  ];
}
