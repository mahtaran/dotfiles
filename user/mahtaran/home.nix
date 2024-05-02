{
  config,
  pkgs,
  inputs,
  systemSettings,
  userSettings,
  ...
}: {
  imports = [
    inputs.impermanence.nixosModules.home-manager.impermanence
  ];

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
      package = inputs.code-insiders.packages."x86_64-linux".vscode-insider;
    };
  };
}
