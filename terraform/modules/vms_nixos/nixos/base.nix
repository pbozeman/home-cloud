{
  config,
  lib,
  pkgs,
  modulesPath,
  hostname,
  hostId,
  ...
}: {
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot.loader.grub.enable = true;

  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "sr_mod" "virtio_blk" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" "zfs" ];
  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
  boot.supportedFilesystems = [ "zfs" ];
  boot.extraModulePackages = [ ];
  boot.zfs.extraPools = [ "storage" ];
  boot.zfs.forceImportRoot = false;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  networking.hostName = hostname;
  networking.useNetworkd = true;
  networking.hostId = hostId;

  services.zfs.autoScrub.enable = true;
  services.zfs.trim.enable = true;

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
}
