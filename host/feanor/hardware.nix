{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  boot = {
    initrd.availableKernelModules = ["xhci_pci" "thunderbolt" "nvme" "usb_storage" "sd_mod" "sdhci_pci"];
    initrd.kernelModules = ["xe"];

    kernelModules = ["kvm-intel"];
    extraModulePackages = [];
    supportedFilesystems = ["ntfs"];
  };

  networking = {
    # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
    # (the default) this is the recommended approach. When using systemd-networkd it's
    # still possible to use this option, but it's recommended to use it in conjunction
    # with explicit per-interface declarations with `interfaces.<interface>.useDHCP`.
    useDHCP = lib.mkDefault true;
    # interfaces.enp0s31f6.useDHCP = lib.mkDefault true;
    # interfaces.wlp0s20f3.useDHCP = lib.mkDefault true;
  };

  hardware = {
    enableAllFirmware = true;
    enableRedistributableFirmware = true;

    cpu = {
      intel = {
        updateMicrocode = lib.mkDefault true;
      };
    };

    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver
        intel-ocl
        intel-vaapi-driver
        vpl-gpu-rt
      ];
    };

    trackpoint = {
      enable = true;
      emaulateWheel = true;
    }
  };

  services = {
    tlp = {
      enable = true;
      settings = {
        START_CHARGE_THRESH_BAT0 = 0;
        STOP_CHARGE_THRESH_BAT0 = 0;
        # TODO
        # DISK_DEVICES = "nvme#n#";
        # DISK_APM_LEVEL_ON_AC = 254;
        # DISK_APM_LEVEL_ON_BAT = 128;

        # TODO check availability with `tlp-stat -p`
        # PLATFORM_PROFILE_ON_AC = "performance";
        # PLATFORM_PROFILE_ON_BAT = "balanced";
      };
    };

    fprintd = {
      enable = true;
    };

    fstrim = {
      enable = true;
    };
  };

  environment = {
    sessionVariables = {
      LIBVA_DRIVER_NAME = "iHD";
    };
  };
}
