{ config, lib, pkgs, modulesPath, ... }: {
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

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
}