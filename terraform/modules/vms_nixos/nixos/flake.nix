{ 
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";

    disko = {
      url = github:nix-community/disko;
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, disko, ... }: {
    nixosConfigurations.template = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./base.nix
        disko.nixosModules.disko
        ./disk-config.nix
        {
          _module.args.disks = [ "/dev/vda" ];
          boot.loader.grub = {
            devices = [ "/dev/vda" ];
          };
        }
      ];
    };
  };
}
