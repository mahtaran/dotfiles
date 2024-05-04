# Mahtaran's dotfiles

## Git configuration

If you wish to diff the secret files, you need to set up SOPS as a diff tool.

```console
# Make sure you have sops installed
$ git config diff.sopsdiffer.textconv "sops decrypt"
```

## Installation guide

1. Reset Secure Boot status to 'set up' mode in your UEFI firmware settings.
2. Boot from a NixOS installation media.
3. Close the graphical installer and open a terminal.
4. Run `lsblk` and note the name of the disk you'd like to use. For me, it was `nvme1n1`.
5. Ensure you have a working internet connection.
6. Run `sudo nix run --experimental-features "nix-command flakes" github:nix-community/disko#disko-install -- --flake github:mahtaran/dotfiles#feanor --write-efi-boot-entries --disk primary /dev/nvme1n1`
   1. Enter the password for the disk encryption when prompted.
7. Reboot into the new installation, enter your chosen disk encryption password and log into the account `mahtaran` with the password `password`.
8. Ensure you have a working internet connection again.
9. Git clone this repository.
10. Import your personal SSH keypair and convert it to an age key:

    ```console
    # I store my ssh keys in Bitwarden, so I use the Bitwarden CLI to get them
    # Adjust as needed
    $ nix-shell -p ssh-to-age bitwarden-cli
    $ bw config server https://vault.bitwarden.eu
    $ export BW_SESSION=$(bw login --raw)
    $ bw get notes "SSH key" > ~/.ssh/id_ed25519
    $ chmod u=rw,go= ~/.ssh/id_ed25519
    $ ssh-keygen -y -f ~/.ssh/id_ed25519 > ~/.ssh/id_ed25519.pub
    $ ssh-add
    # Create the persistent age keys file, so that we don't override the symlink
    $ touch /persist/home/mahtaran/.config/sops/age/keys.txt
    # Add the host key to the age encryption keys
    $ sudo ssh-to-age -private-key -i /etc/ssh/ssh_host_ed25519_key >> ~/.config/sops/age/keys.txt
    # Make sure to add the public key in the `.sops.yaml` file!
    $ ssh-to-age -i /etc/ssh/ssh_host_ed25519_key.pub
    # Assuming you have a passphrase set for the SSH key (as you should)
    $ read -s SSH_TO_AGE_PASSPHRASE; export SSH_TO_AGE_PASSPHRASE
    $ ssh-to-age -private-key -i ~/.ssh/id_ed25519 >> ~/.config/sops/age/keys.txt
    ```

11. Ensure that `sudo bootctl status` reports UEFI firmware with TPM2 support, and secure boot in setup mode.
12. Run `sudo sbctl create-keys`.
13. Run `sudo sbctl enroll-keys --microsoft`.
14. Rebuild the system: `sudo nixos-rebuild switch --flake ~/dotfiles`.
15. Check that all went well using `sudo sbctl verify` (only the Linux image should not be signed).
16. Turn Secure Boot back on.
17. Run `sudo systemd-cryptenroll /dev/disk/by-partlabel/disk-primary-luks --wipe-slot=tpm2 --tpm2-device=auto --tpm2-pcrs=0+2+7` to enrol the disk encryption key in the TPM.
18. We can now also clean up old `systemd-boot` entries: `sudo rm /boot/loader -r`, followed by rebuilding the system again.

## Creating a secrets file

Create the hash for the password you want, and put it in a secrets file

```console
$ read -s PASSWORD; echo $PASSWORD | mkpasswd -s
$y$j9T$rAFN5Csek3da0mv72gb4B.$M3dzM3xKHNzHNkiSh5g2K4maVPJCNr9hsVCRGa/27b8
# You will probably get something else, as this is the hash for 'password'
$ nix-shell -p sops --run "sops ~/dotfiles/secret/user/mahtaran/secrets.yaml"
```

```yaml
# ~/dotfiles/secret/user/mahtaran/secrets.yaml
password: $y$j9T$rAFN5Csek3da0mv72gb4B.$M3dzM3xKHNzHNkiSh5g2K4maVPJCNr9hsVCRGa/27b8
```

## Add a Windows boot entry

```console
# Assuming /dev/nvme0n1p1 is the EFI partition of the Windows installation
$ sudo mount /dev/nvme0n1p1 /mnt
$ sudo cp /mnt/EFI/Microsoft /boot/EFI/ -r
```

## Delete old boot entries

```console
# Do make sure that you don't have other Linux installations with an EFI boot entry
$ nix-shell -p efibootmgr --run "sudo efibootmgr -BL 'Linux Boot Manager'"
$ sudo bootctl install
$ sudo nixos-rebuild switch --flake ~/dotfiles
```
