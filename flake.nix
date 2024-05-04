{
  description = "NixOS config flake";

  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.3.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence = {
      url = "github:nix-community/impermanence";
    };

    nur = {
      url = "github:nix-community/NUR";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    code-insiders = {
      url = "github:iosmanthus/code-insider-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {...}:
    let
      onInstallMedia = builtins.pathExists /home/nixos;
      mkSystem = { entry, arch, extraModules, users, ... }:
        inputs.nixpkgs.lib.nixosSystem {
          system = arch;
          specialArgs = {
            inherit inputs;
            inherit onInstallMedia;
          };

          modules = [
            {
              nix.settings.experimental-features = ["nix-command" "flakes"];
            }
            inputs.disko.nixosModules.disko
            inputs.sops-nix.nixosModules.sops
            inputs.nur.nixosModules.nur
            inputs.home-manager.nixosModules.home-manager
            entry
            {
              home-manager = {
                extraSpecialArgs = {
                  inherit inputs;
                  inherit onInstallMedia;
                };
                useGlobalPkgs = true;
                useUserPackages = true;
                sharedModules = [
                  inputs.sops-nix.homeManagerModules.sops
                  inputs.nur.hmModules.nur
                ];

                users = users;
              };
            }
          ] ++ extraModules;
        };
  in rec {
    formatter.x86_64-linux = inputs.nixpkgs.legacyPackages.x86_64-linux.alejandra;

    nixosConfigurations = {
      feanor = mkSystem {
        entry = ./host/feanor;
        arch = "x86_64-linux";
        extraModules = [
          ./module/disko/single-disk.nix
          inputs.lanzaboote.nixosModules.lanzaboote
          inputs.impermanence.nixosModules.impermanence
        ];
        users = {
          mahtaran = import ./user/mahtaran;
        };
      };
    };
  };
}
