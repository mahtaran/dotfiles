{ ... }: {
  system = {
    name = "feanor";
    architecture = "x86_64-linux";
    secureBoot = false;
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
  user = {
    name = "mahtaran";
    display = "Luka";
    email = "luka.leer@gmail.com";
    editor = "nano";
  };
}
