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

    alejandra = {
      url = "github:kamadorueda/alejandra";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    code-insiders = {
      url = "github:iosmanthus/code-insider-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ ... }:
  let
    settings = import ./settings.nix;
    alejandra = inputs.alejandra.defaultPackage.${settings.system.architecture};
  in {
    formatter.${settings.system.architecture} = alejandra;

    nixosConfigurations = {
      ${settings.system.name} = inputs.nixpkgs.lib.nixosSystem {
        system = settings.system.architecture;
        specialArgs = {
          inherit inputs;
          inherit settings;
        };
        modules = [
          { nix.settings.experimental-features = ["nix-command" "flakes"]; }
          inputs.disko.nixosModules.disko
          inputs.lanzaboote.nixosModules.lanzaboote
          inputs.sops-nix.nixosModules.sops
          inputs.impermanence.nixosModules.impermanence
          inputs.nur.nixosModules.nur

          ./host/${settings.system.name}/configuration.nix
          { environment.systemPackages = [ alejandra ]; }
          
          inputs.home-manager.nixosModules.home-manager
          (
            { ... }:
            {
              home-manager = {
                extraSpecialArgs = {
                  inherit inputs;
                  inherit settings;
                };
                useGlobalPkgs = true;
                useUserPackages = true;
                sharedModules = [ inputs.nur.hmModules.nur ];

                users = {
                  ${settings.user.name} = import ./user/${settings.user.name}/home.nix;
                };
              };
            }
          )
        ];
      };
    };
  };
}
