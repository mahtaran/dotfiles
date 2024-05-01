{
  description = "NixOS config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

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

    alejandra = {
      url = "github:kamadorueda/alejandra";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    code-insiders = {
      url = "github:iosmanthus/code-insider-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    disko,
    lanzaboote,
    impermanence,
    nur,
    home-manager,
    alejandra,
    code-insiders,
    ...
  } @ inputs: {
    formatter.x86_64-linux = alejandra.defaultPackage.x86_64-linux;

    nixosConfigurations = {
      laptop = nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          disko.nixosModules.disko
          ./module/disko.nix
          lanzaboote.nixosModules.lanzaboote
          ({
            pkgs,
            lib,
            ...
          }: {
            environment.systemPackages = [
              pkgs.sbctl
            ];
            boot.initrd.systemd.enable = true;
            boot.loader.systemd-boot.enable = lib.mkForce false;
            boot.lanzaboote = {
              enable = false;
              pkiBundle = "/etc/secureboot";

              configurationLimit = 5;
              settings = {
                auto-entries = true;
                auto-firmware = true;
                console-mode = "auto";
                editor = false;
                timeout = 10;
              };
            };
          })
          impermanence.nixosModules.impermanence
          nur.nixosModules.nur
          ./host/laptop/configuration.nix
          {
            environment.systemPackages = [
              alejandra.defaultPackage.${system}
            ];
          }
          home-manager.nixosModules.home-manager
          ({...}: {
            home-manager = {
              extraSpecialArgs = {inherit self inputs;};
              useGlobalPkgs = true;
              useUserPackages = true;
              sharedModules = [ nur.hmModules.nur ];
              
              users = {
                "mahtaran" = import ./user/mahtaran/home.nix;
              };
            };
          })
        ];
      };
    };
  };
}
