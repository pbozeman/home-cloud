{ inputs.nixpkgs.url = "nixpkgs/nixos-unstable";

  outputs = { nixpkgs, ... }: {
    nixosConfigurations.first = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./base.nix
        ./k3s-first.nix
      ];
    };

    nixosConfigurations.subsequent = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./base.nix
        ./k3s-subsequent.nix
      ];
    };
  };
}
