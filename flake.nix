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
        ./device-specific/legion.nix
        ./additional-features/branding.nix
      ];
    };
    nixosConfigurations.gmk = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./general-configuration.nix
        ./device-specific/gmk.nix
        ./additional-features/branding-rexctl.nix
        ./additional-features/trb-ntp.nix
        ./additional-features/mediamtx-hikvision.nix
        ./additional-features/nginx-wiki.nix
      ];
    };
    nixosConfigurations.nuc = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./general-configuration.nix
        ./device-specific/nuc.nix
        ./additional-features/branding-rexctl.nix
        ./additional-features/trb-ntp.nix
        ./additional-features/mediamtx-hikvision.nix
        ./additional-features/nginx-wiki.nix
      ];
    };
    nixosConfigurations.rex-vm = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./general-configuration.nix
        ./device-specific/rex-vm.nix
        ./additional-features/branding-rexctl.nix
#        ./additional-features/mediamtx-hikvision.nix
#        ./additional-features/nginx-wiki.nix
      ];
    };

    apps."x86_64-linux".rex-vm = {
      type = "app";
      program = "${self.nixosConfigurations.rex-vm.config.system.build.vm}/bin/run-rex-vm-vm";
    };
  };
}
