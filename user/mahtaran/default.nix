{
  config,
  lib,
  pkgs,
  inputs,
  onInstallMedia,
  ...
}: {
  sops = lib.mkIf (!onInstallMedia) {
    age = {
      keyFile = "/home/mahtaran/.config/sops/age/keys.txt";
    };
    secrets = {
      gpg-password = {
        sopsFile = ../../secret/user/mahtaran/secrets.yaml;
      };
      gpg-key = {
        sopsFile = ../../secret/user/mahtaran/secrets.yaml;
      };
    };
  };

  home = {
    # This value determines the Home Manager release that your configuration is
    # compatible with. This helps avoid breakage when a new Home Manager release
    # introduces backwards incompatible changes.
    #
    # You should not change this value, even if you update Home Manager. If you do
    # want to update the value, then make sure to first check the Home Manager
    # release notes.
    stateVersion = "23.11"; # Please read the comment before changing.

    # Home Manager needs a bit of information about you and the paths it should
    # manage.
    username = "mahtaran";
    homeDirectory = "/home/mahtaran";

    # The home.packages option allows you to install Nix packages into your
    # environment.
    packages = [
      # # Adds the 'hello' command to your environment. It prints a friendly
      # # "Hello, world!" when run.
      # pkgs.hello

      # # It is sometimes useful to fine-tune packages, for example, by applying
      # # overrides. You can do that directly here, just don't forget the
      # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
      # # fonts?
      # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

      # # You can also create simple shell scripts directly inside your
      # # configuration. For example, this adds a command 'my-hello' to your
      # # environment:
      # (pkgs.writeShellScriptBin "my-hello" ''
      #   echo "Hello, ${config.home.username}!"
      # '')

      pkgs.bitwarden-desktop
      pkgs.kate
      pkgs.ferdium
    ];

    # Home Manager is pretty good at managing dotfiles. The primary way to manage
    # plain files is through 'home.file'.
    file = {
      # # Building this configuration will create a copy of 'dotfiles/screenrc' in
      # # the Nix store. Activating the configuration will then make '~/.screenrc' a
      # # symlink to the Nix store copy.
      # ".screenrc".source = dotfiles/screenrc;

      # # You can also set the file content immediately.
      # ".gradle/gradle.properties".text = ''
      #   org.gradle.console=verbose
      #   org.gradle.daemon.idletimeout=3600000
      # '';
    };

    # Home Manager can also manage your environment variables through
    # 'home.sessionVariables'. If you don't want to manage your shell through Home
    # Manager then you have to manually source 'hm-session-vars.sh' located at
    # either
    #
    #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
    #
    # or
    #
    #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
    #
    # or
    #
    #  /etc/profiles/per-user/mahtaran/etc/profile.d/hm-session-vars.sh
    #
    # sessionVariables = {
    #   EDITOR = "nano";
    # };
  };

  wayland.windowManager.hyprland.enable = true;

  xdg.enable = true;

  programs = {
    # Let Home Manager install and manage itself.
    home-manager.enable = true;

    firefox = {
      enable = true;
      # package = pkgs.firefox;
      profiles."mahtaran" = {
        extensions = with config.nur.repos.rycee.firefox-addons; [
          bitwarden
          ublock-origin
        ];
      #   search = {
      #     default = "DuckDuckGo";
      #   };
      };
    };
  
    vscode = {
      enable = true;
      package = inputs.code-insiders.packages.x86_64-linux.vscode-insider;
    };
  };

  programs.git = {
    enable = true;
    userName = "Luka Leer";
    userEmail = "luka.leer@gmail.com";

    signing = {
      key = "C7FFB72E0527423AD470E132AA82C4EBCB1682E0";
      signByDefault = true;
    };

    delta.enable = true;
  };

  programs.gpg = {
    enable = true;
    mutableKeys = false;
    mutableTrust = false;
    publicKeys = [
      {
        # Personal GPG key
        text = ''
          -----BEGIN PGP PUBLIC KEY BLOCK-----

          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
          mM6jA4jPvzZ0fV8T9w==
          =tpgI
          -----END PGP PUBLIC KEY BLOCK-----
        '';
        trust = "ultimate";
      }
    ];
  };

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    sshKeys = [ "C7FFB72E0527423AD470E132AA82C4EBCB1682E0" ];
  };

  services.mullvad-vpn = {
    enable = true;
    # We will use the version with GUI for now
    package = pkgs.mullvad-vpn;
  };

  systemd.user.services = {
    import-gpg-key = lib.mkIf (!onInstallMedia) {
      Unit = {
        Description = "Import secret GPG key";
        After = [ "sops-nix.service" ];
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = let 
          passphraseFile = config.sops.secrets.gpg-password.path;
          keyFile = config.sops.secrets.gpg-key.path;
        in "${pkgs.gnupg}/bin/gpg --pinentry-mode loopback --passphrase-file ${passphraseFile} --import ${keyFile}";
      };
    };
  };
}
