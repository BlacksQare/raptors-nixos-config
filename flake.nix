{
  description = "Raptors flake";

  inputs = {
    # NixOS stable
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    rexctl = {
      url = "github:BlacksQare/rexctl";
      inputs.nixpkgs.follows = "nixpkgs";
    };


    # NixOS unstable
    # nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... } @inputs: {
    nixosConfigurations.legion-nix = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./general-configuration.nix
        ./specific-configs/legion.nix
        ./branding.nix
      ];
    };
    nixosConfigurations.gmk = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./general-configuration.nix
        ./specific-configs/gmk.nix
        ./branding-rexctl.nix
      ];
    };
    nixosConfigurations.nuc = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./general-configuration.nix
        ./specific-configs/nuc.nix
        ./branding-rexctl.nix
      ];
    };
  };
}
