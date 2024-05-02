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

  outputs =
    inputs@{ ... }:
    let
      systemSettings = {
        architecture = "x86_64-linux";
        timezone = "Europe/Amsterdam";
        defaultLocale = "en_GB.UTF-8";
        extraLocaleSettings = {
          LC_ADDRESS = "nl_NL.UTF-8";
          LC_IDENTIFICATION = "nl_NL.UTF-8";
          LC_MEASUREMENT = "nl_NL.UTF-8";
          LC_MONETARY = "nl_NL.UTF-8";
          LC_NAME = "nl_NL.UTF-8";
          LC_NUMERIC = "nl_NL.UTF-8";
          LC_PAPER = "nl_NL.UTF-8";
          LC_TELEPHONE = "nl_NL.UTF-8";
          LC_TIME = "nl_NL.UTF-8";
        };
      };
      userSettings = {
        username = "mahtaran";
        name = "Luka";
        email = "luka.leer@gmail.com";
        editor = "nano";
      };
    in
    {
      formatter.${systemSettings.architecture} = inputs.alejandra.defaultPackage.${systemSettings.architecture};

      nixosConfigurations = {
        feanor = inputs.nixpkgs.lib.nixosSystem rec {
          system = systemSettings.architecture;
          specialArgs = {
            inherit inputs;
            inherit systemSettings userSettings;
          };
          modules = [
            inputs.sops-nix.nixosModules.sops
            inputs.disko.nixosModules.disko
            ./module/disko.nix
            inputs.lanzaboote.nixosModules.lanzaboote
            (
              { pkgs, lib, ... }:
              {
                environment.systemPackages = [ pkgs.sbctl ];
                boot.initrd.systemd.enable = true;
                # TODO make path more specific
                boot = if builtins.pathExists /etc/secureboot then {
                  loader.systemd-boot.enable = lib.mkForce false;
                  lanzaboote = {
                    enable = true;
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
                } else {
                  boot.loader.systemd-boot.enable = true;
                };
              }
            )
            inputs.impermanence.nixosModules.impermanence
            inputs.nur.nixosModules.nur
            ./host/feanor/configuration.nix
            { environment.systemPackages = [ inputs.alejandra.defaultPackage.${system} ]; }
            inputs.home-manager.nixosModules.home-manager
            (
              { ... }:
              {
                home-manager = {
                  extraSpecialArgs = {
                    inherit inputs;
                    inherit systemSettings userSettings;
                  };
                  useGlobalPkgs = true;
                  useUserPackages = true;
                  sharedModules = [ inputs.nur.hmModules.nur ];

                  users = {
                    ${userSettings.username} = import ./user/${userSettings.username}/home.nix;
                  };
                };
              }
            )
          ];
        };
      };
    };
}
