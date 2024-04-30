# Mahtaran's dotfiles

## Installation guide

1. Disable secure boot.
2. Boot from a NixOS installation media.
3. Run `lsblk` and note the name of the disk you'd like to use. For me, it was `nvme1n1`.
4. Run `sudo nix run 'github:nix-community/disko#disko-install' -- --write-efi-boot-entries --flake github:mahtaran/dotfiles#laptop --disk primary /dev/nvme1n1`
