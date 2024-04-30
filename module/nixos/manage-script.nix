{
  config,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "manage-nixos" ''
      # Inspired by https://gist.github.com/0atman/1a5133b842f929ba4c1e195ee67599d5

      # Enable unofficial strict mode (http://redsymbol.net/articles/unofficial-bash-strict-mode/)
      set -euo pipefail
      IFS=${"$'\\n\\t'"}

      command_help_edit() {
        echo "Usage: manage-nixos edit <command> [--flake <flake>] [--hostname <hostname>] [--editor <editor>] [--no-edit] [args]"
        echo "Commands:"
        echo "  switch   Build and switch to the new system configuration"
        echo "  build    Build the new system configuration"
        echo "  boot     Build the new system configuration and set it as the default boot option"
        echo "  test     Build the new system configuration, but don't add it to the boot menu"
        echo "Arguments:"
        echo "  --flake <flake>  Use the specified flake as the system configuration. Defaults to '~/nixos'"
        echo "  --hostname <hostname>  Use the specified hostname as the target for the system configuration. Defaults to the current hostname ('$(hostname)')"
        echo "  --editor <editor>  Use the specified editor to edit the flake. Defaults to the value of the 'EDITOR' environment variable, or 'nano' if it is not set"
        echo "  --no-edit  Skip editing the flake and proceed directly to building the system configuration"
        echo "Any additional arguments will be passed to nixos-rebuild"
        return 0
      }

      command_help() {
        if [[ -n "''${1:-}" ]]; then
          if [[ "$1" == "edit" ]]; then
            shift
            command_help_edit "$@"
            return $?
          elif [[ "$1" == "help" ]]; then
            echo "Usage: manage-nixos help <command>"
            echo "Show help for a specific command"
            return 0
          else
            echo "Unknown command: '$1'"
            command_help
            return 1
          fi
        else
          echo "Usage: manage-nixos <command> [args]"
          echo "Commands:"
          echo "  edit     Edit the system configuration and build it"
          echo "  help     Show this help message"
          echo "Tip: You can use 'manage-nixos help <command>' to get help for a specific command"
          return 0

        fi
      }

      command_edit() {
        local operation
        local flake
        local hostname
        local editor
        local no_edit
        local args

        # Parse the arguments
        if [[ -z "''${1:-}" ]]; then
          echo "No operation specified"
          command_help_edit
          exit 1
        elif [[ "$1" == "switch" ]]; then
          operation="switch"
          shift
        elif [[ "$1" == "build" ]]; then
          operation="build"
          shift
        elif [[ "$1" == "boot" ]]; then
          operation="boot"
          shift
        elif [[ "$1" == "test" ]]; then
          operation="test"
          shift
        else
          echo "Unknown operation: '$1'"
          command_help_edit
          exit 1
        fi

        while [[ "$#" -gt 0 ]]; do
          case "$1" in
            --help)
              command_help_edit
              return 0
              ;;
            --flake)
              flake="$2"
              shift 2
              ;;
            --hostname)
              hostname="$2"
              shift 2
              ;;
            --editor)
              editor="$2"
              shift 2
              ;;
            --no-edit)
              no_edit="true"
              shift
              ;;
            *)
              args+=("$1")
              shift
              ;;
          esac
        done

        # Set default values
        flake="''${flake:-$HOME/nixos}"
        hostname="''${hostname:-$(hostname)}"
        editor="''${editor:-''${EDITOR:-nano}}"
        no_edit="''${no_edit:-false}"

        # Check if the flake exists
        if [[ ! -d "$flake" ]]; then
          echo "The flake '$flake' does not exist"
          exit 1
        fi

        # Navigate to the flake directory
        pushd "$flake"

        # If we wish to edit the flake
        if [[ "$no_edit" == "false" ]]; then
          # Check if the flake is a git repository
          if [[ ! -d .git ]]; then
            echo "The flake '$flake' is not a git repository"
            popd
            exit 1
          fi

          # Edit the flake directory
          $editor flake.nix

          # Early exit if the user didn't change anything
          if git diff --quiet; then
            echo "No changes detected, exiting"
            popd
            exit 0
          fi

          # Format the nix files
          nix fmt . &>/dev/null || ( nix fmt . ; popd ; echo "formatting failed!" && exit 1 )

          # Show the changes
          git diff --unified=0
        fi

        # Build the system configuration
        echo "Building the system configuration…"
        sudo nixos-rebuild "$operation" --flake ".#$hostname" "''${args[@]}" &>nixos-switch.log \
          || ( cat nixos-switch.log ; popd ; grep --color error && exit 1 )

        # Commit the changes
        if [[ "$no_edit" == "false" ]]; then
          current=$(nixos-rebuild list-generations | grep current)
          git commit -am "🏗️ NixOS changes: $current"
        fi

        # Navigate back to the original directory
        popd

        # Notify all OK!
        notify-send -e "NixOS rebuilt successfully!" --icon=software-update-available

        return 0
      }

      if [[ -z "''${1:-}" ]]; then
        echo "No command specified"
        command_help
        exit 1
      elif [[ "$1" == "help" ]]; then
        shift
        command_help "$@"
        exit $?
      elif [[ "$1" == "edit" ]]; then
        shift
        command_edit "$@"
        exit $?
      else
        echo "Unknown command: '$1'"
        command_help
        exit 1
      fi
    '')
  ];
}
