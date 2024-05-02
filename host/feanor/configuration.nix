{
  config,
  lib,
  pkgs,
  inputs,
  systemSettings,
  userSettings,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../module/nixos/btrfs.nix
    ../../module/nixos/manage-script.nix
    ../../module/nixos/optimise.nix
    ../../module/fingerprint.nix
    ../../module/hyprland.nix
  ];

  nix.settings.experimental-features = ["nix-command" "flakes"];

  sops = {
    age = {
      keyFile = "/persist/home/mahtaran/.config/sops/age/keys.txt";
      generateKey = true;
      sshKeyPaths = ["/persist/etc/ssh/ssh_host_ed25519_key"];
    };
    secrets = {
      "mahtaran/password" = {
        sopsFile = ../../secret/user/mahtaran/secrets.yaml;
        key = "password";
        neededForUsers = true;
      };
    };
  };

  boot = lib.mkMerge [      
    (lib.mkIf (systemSettings.secureBoot) {
      loader.systemd-boot.enable = lib.mkForce false;
      lanzaboote = {
        enable = true;
        pkiBundle = "/persist/etc/secureboot";

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
    
    (lib.mkIf (!systemSettings.secureBoot) {
      loader.systemd-boot.enable = true;
    })

    {
      initrd.systemd = {
        enable = true;
        services = {
          lvm.enable = true;

          rollback = {
            description = "Rollback BTRFS root subvolume to a pristine state";
            wantedBy = [ "initrd.target" ];
            after = [
              "systemd-cryptsetup@enc.service"
              "dev-root_vg-root.device"
            ];
            before = [
              "sysroot.mount"
            ];
            unitConfig.DefaultDependencies = "no";
            serviceConfig.Type = "oneshot";
            script = ''
              mkdir /btrfs_tmp
              mount /dev/root_vg/root /btrfs_tmp
              if [[ -e /btrfs_tmp/root ]]; then
                  mkdir -p /btrfs_tmp/old_roots
                  timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/root)" "+%Y-%m-%-d_%H:%M:%S")
                  mv /btrfs_tmp/root "/btrfs_tmp/old_roots/$timestamp"
              fi
  
              delete_subvolume_recursively() {
                  IFS=$'\n'
                  for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
                      delete_subvolume_recursively "/btrfs_tmp/$i"
                  done
                  btrfs subvolume delete "$1"
              }
  
              for i in $(find /btrfs_tmp/old_roots/ -maxdepth 1 -mtime +30); do
                  delete_subvolume_recursively "$i"
              done
  
              btrfs subvolume create /btrfs_tmp/root
              umount /btrfs_tmp
            '';
          };
        };
      };
    }
  ];

  fileSystems."/persist".neededForBoot = true;
  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/var/log"
      "/var/lib/bluetooth"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/etc/NetworkManager/system-connections"
      "/etc/secureboot"
    ];
    files = [
      "/etc/machine-id"
      { file = "/etc/ssh/ssh_host_ed25519_key"; parentDirectory = { mode = "u=rwx,g=,o="; }; }
      "/etc/ssh/ssh_host_ed25519_key.pub"
    ];
    users.mahtaran = {
      directories = [
        "Documents"
        "Downloads"
        "Music"
        "Pictures"
        "Videos"
        { directory = ".gnupg"; mode = "u=rwx,g=,o="; }
        { directory = ".local/share/keyrings"; mode = "u=rwx,g=,o="; }
        "dotfiles"
      ];
      files = [
        { file = ".config/sops/age/keys.txt"; parentDirectory = { mode = "u=rwx,g=,o="; }; }
        { file = ".ssh/id_ed25519"; parentDirectory = { mode = "u=rwx,g=,o="; }; }
        ".ssh/id_ed25519.pub"
      ];
    };
  };

  networking.hostName = "feanor";
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  hardware.enableAllFirmware = true;

  # Enable Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # Set your time zone.
  time.timeZone = "Europe/Amsterdam";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_GB.UTF-8";

  i18n.extraLocaleSettings = {
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

  # Tell Electron apps to use Wayland
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  services.xserver = {
    enable = true;

    displayManager = {
      gdm.enable = true;

      defaultSession = "gnome";
    };

    desktopManager = {
      gnome.enable = true;
    };

    # Configure keymap
    xkb = {
      layout = "us";
      variant = "intl";
    };
  };

  # Configure console keymap
  console.keyMap = "us-acentos";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account.
  users.mutableUsers = false;
  users.users.mahtaran = {
    isNormalUser = true;
    description = "Luka Leer";
    hashedPasswordFile = config.sops.secrets."mahtaran/password".path;
    extraGroups = ["networkmanager" "video" "wheel"];        
    packages = with pkgs; [
      # firefox
      # kate
      # thunderbird
    ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    sbctl
    git
    nixd
    wluma
  ];

  # Add udve rules for accessing the keyboard and screen brightness setting
  services.udev.extraRules = ''
    SUBSYSTEM=="backlight", ACTION=="add", \
      RUN+="${pkgs.coreutils}/bin/chgrp video /sys/class/backlight/%k/brightness", \
      RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/class/backlight/%k/brightness"
    SUBSYSTEM=="leds", ACTION=="add", \
      RUN+="${pkgs.coreutils}/bin/chgrp video /sys/class/leds/%k/brightness", \
      RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/class/leds/%k/brightness"
  '';

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };
  programs.java.enable = true;
  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-gnome3;
  };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    ports = [ ];
    hostKeys = [
      { path = "/persist/etc/ssh/ssh_host_ed25519_key"; type = "ed25519"; }
    ];
  };
  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
