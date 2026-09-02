# AGENTS.md - dotfiles-nix

This repo manages Nicolai's macOS setup with nix-darwin, Home Manager,
nix-homebrew, Homebrew Bundle, local dotfiles, keyboard assets, and helper
scripts.

## Structure

- `darwin/flake.nix`: main nix-darwin and Home Manager configuration.
- `darwin/host.nix`: local host/user identity and feature flags.
- `darwin/work.nix`: optional work-specific configuration.
- `dotfiles/`: user dotfiles linked through Home Manager.
- `keyboard/`: custom keyboard layout assets.
- `rayscripts/`: helper scripts installed from the flake.

## Agent Infrastructure

The production agent environment is defined in `~/git/personal/agent-infra`:
Black is the bare-metal host, Atlas is its workload VM, T3 Code runs natively on
Atlas, and Hermes (the assistant called Domovoi) runs there in Docker. The
`darwin/agents/` directory in this repository contains shared NixOS modules
imported by `agent-infra`; do not treat the legacy `nixosConfigurations.domovoi`
output as a currently deployed machine.

## Commands

From `darwin/`:

```sh
nix build .#darwinConfigurations.nicolais-MacBook-Pro.system --no-link
sudo darwin-rebuild switch --flake .#nicolais-MacBook-Pro
```

Format Nix files with:

```sh
nixfmt darwin/*.nix
```

## Package Updates

For fixed-output derivations such as `t3code` and `opencode`:

1. Verify the latest upstream release.
2. Update `version`, `url` if needed, and `sha256`.
3. Build with `nix build ... --no-link`.
4. Run `darwin-rebuild switch` only after the build succeeds.

For Homebrew casks:

1. Run `brew search <query>`.
2. Add the selected cask to `homebrew.casks`.
3. Apply with `darwin-rebuild switch`.

For Mac App Store apps:

1. Run `mas search <app name>`.
2. Add the selected app name and ID to `homebrew.masApps`.
3. Apply with `darwin-rebuild switch`.

## Git

Use Conventional Commits:

```text
type(scope): summary
```

Use lowercase commit messages. Common scopes:

- `darwin`
- `homebrew`
- `nvim`
- `dotfiles`
- `keyboard`
- `rayscripts`
- `docs`

Examples:

```text
chore(darwin): update t3code
chore(homebrew): add cursor-cli cask
docs(readme): clarify switch command
```

## Safety

- Do not revert unrelated user changes.
- Keep edits scoped and avoid formatting churn.
- Be careful with `darwin/host.nix`; it contains machine-specific identity and
  flags.
- Rosetta cannot be easily uninstalled after activation installs it.
