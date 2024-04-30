{
  config,
  pkgs,
  inputs,
  ...
}: {
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = ["/"];
  };
}
