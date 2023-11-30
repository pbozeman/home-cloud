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
    extraFlags =
      "--disable=servicelb " +
      "--disable=traefik " +
      "--disable=local-storage " +
      "--kube-apiserver-arg default-not-ready-toleration-seconds=10 " +
      "--kube-apiserver-arg default-unreachable-toleration-seconds=10 " +
      "--kube-controller-arg node-monitor-period=10s " +
      "--kube-controller-arg node-monitor-grace-period=10s " +
      "--kubelet-arg node-status-update-frequency=5s";
  };

  networking.firewall.allowedTCPPorts = [
    # https://kubernetes.io/docs/reference/networking/ports-and-protocols/
    6443
    2379
    2380
    7946
    9100
    10250
    10251
    10259
    10257
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

  # https://docs.k3s.io/installation/private-registry
  # TODO: pass in the domain name as a variable
  #environment.etc = {
  #  "rancher/k3s/registries.yaml" = {
  #    text = ''
  #      mirrors:
  #        blinkies.io
  #          endpoint:
  #            - "https://registry.blinkies.io:443"
  #    '';
  #    mode = "0440";
  #  };
  #};
}
