# Warnings

Rosetta can't be easily uninstalled. Removing it from the config after installing it will do nothing.

# Setup

## Installation

1. Install nix on mac: `sh <(curl -L https://nixos.org/nix/install)`
2. Create the `/etc/nix-darwin` symlink with `./create_links.sh`, or copy `darwin/` to the nix-darwin config location.
3. Log-in with Apple for Mac Store app installations to work.
4. Install nix-darwin: `nix run nix-darwin/master#darwin-rebuild -- switch --flake /etc/nix-darwin#nicolais-MacBook-Pro`

## Updating config

From `darwin/`:

```sh
nix build .#darwinConfigurations.nicolais-MacBook-Pro.system --no-link
sudo darwin-rebuild switch --flake .#nicolais-MacBook-Pro
```

## Manual things

- Installing nix and nix-darwin (potentially create a script for this)
- Install the keyboard layout and select it as primary from the keyboard folder
- Logging in to Apple ID
- Restore RayCast settings (automatic sync needs pro, or maybe an extension exists?)
- Copying SSH keys
- Various logging in actions (Firefox, Slack, Teams, Signal, Telegram, Outlook, etc.)
