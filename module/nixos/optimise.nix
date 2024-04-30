{
  config,
  pkgs,
  ...
}: {
  nix = {
    optimise.automatic = true;
    # gc = {
    #   automatic = true;
    #   dates = "daily";
    #   options = "--delete-older-than 30d";
    # };
  };
}
