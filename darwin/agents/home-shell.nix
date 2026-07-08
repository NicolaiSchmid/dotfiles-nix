# Shared home-manager shell config — extracted from the laptop flake so the VM
# uses the *same* zsh setup (functions, prompt, git). Imported for both nicolai
# (the agent user) and root, so the shell is consistent however you ssh in.
{ pkgs, ... }:
let
  # Drop-in `gh` wrapper: intercepts ONLY t3's per-branch PR-status call
  # (`gh pr list --head <b> --json <fields>`) and serves it from a per-repo
  # cache, refreshed via real gh only when a conditional REST GET (free 304s)
  # says PRs actually changed. Collapses ~N GraphQL calls per status sweep → ~0
  # on idle, so the VcsStatusBroadcaster poll stops burning the GitHub API quota.
  # Everything else (and any error) execs the real gh untouched. node launcher:
  # it forwards argv verbatim, unlike bun which would eat flags like --version.
  ghPrShim = pkgs.writeShellScriptBin "gh" ''
    export GH_PR_SHIM_REAL_GH=${pkgs.gh}/bin/gh
    exec ${pkgs.nodejs_24}/bin/node ${./gh-pr-shim.mjs} "$@"
  '';

  # Hands-free Bitwarden session, mirroring the laptop: `bw unlock` is ALWAYS
  # interactive, so we never use it. `bw-session` reads the API key + master
  # password from a 0600 credentials.env (NOT in the flake — it's a secret, on
  # the persisted state volume), logs in via the API key if needed, and prints
  # a raw session key with zero prompts. Agents/scripts call `bw-session`
  # directly; interactive shells use `bwunlock` (below) to cache it.
  # Values in credentials.env are taken literally after the first '=' (so the
  # master password may contain spaces/quotes/$ — do NOT quote them in the file).
  bwSession = pkgs.writeShellScriptBin "bw-session" ''
    set -o errexit
    set -o nounset
    set -o pipefail

    export PATH="${pkgs.bitwarden-cli}/bin:${pkgs.jq}/bin:$PATH"

    cred_file="''${BW_CRED_FILE:-$HOME/.config/bitwarden-cli/credentials.env}"
    if [ ! -r "$cred_file" ]; then
      echo "bw-session: cannot read credentials file: $cred_file" >&2
      exit 1
    fi
    while IFS= read -r line || [ -n "$line" ]; do
      [ -z "$line" ] && continue
      case "$line" in "#"*) continue ;; esac
      key=''${line%%=*}
      val=''${line#*=}
      val=''${val%$'\r'}
      export "$key=$val"
    done < "$cred_file"

    status="$(bw status 2>/dev/null | jq -r '.status' 2>/dev/null || echo unauthenticated)"
    if [ "$status" = "unauthenticated" ]; then
      # Server can only be set while logged out (self-hosted vaults).
      if [ -n "''${BW_SERVER:-}" ]; then
        bw config server "$BW_SERVER" >/dev/null
      fi
      # Prefer an API key if one is configured (Bitwarden's documented headless
      # method); otherwise fall back to email + master password (works on
      # vaultwarden when the account has no 2FA). Either way, no prompt.
      if [ -n "''${BW_CLIENTID:-}" ] && [ -n "''${BW_CLIENTSECRET:-}" ]; then
        bw login --apikey >/dev/null
      elif [ -n "''${BW_EMAIL:-}" ]; then
        bw login "$BW_EMAIL" --passwordenv BW_PASSWORD --raw >/dev/null
      else
        echo "bw-session: cred file needs BW_CLIENTID/BW_CLIENTSECRET or BW_EMAIL" >&2
        exit 1
      fi
    fi

    # Non-interactive unlock; emits the session key on stdout.
    bw unlock --passwordenv BW_PASSWORD --raw
  '';
in
{
  home.stateVersion = "24.11";

  # `bw-session` on the login PATH so t3code/Hermes agents (resolved via the
  # login shell) and interactive shells can mint a Bitwarden session hands-free.
  home.packages = [ bwSession ];

  # Aliases (vendored from the laptop's dotfiles; ll uses eza, which is installed).
  home.file.".aliases".source = ./aliases;

  home.sessionVariables.HISTCONTROL = "ignorespace";

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    enableCompletion = false; # cached compinit below
    syntaxHighlighting.enable = true;
    initContent = ''
      # Cached compinit - only rebuild once per day
      autoload -Uz compinit
      if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
        compinit
      else
        compinit -C
      fi

      [ -f ~/.aliases ] && source ~/.aliases

      # Bitwarden: `bw unlock` is always interactive — don't use it. `bwunlock`
      # mints a hands-free session via `bw-session` (reads credentials.env, no
      # prompt) and caches it in a 0600 file (the Linux stand-in for the Mac's
      # Keychain) so every later shell re-exports BW_SESSION. Re-run `bwunlock`
      # if the vault times out. Agents/scripts should call `bw-session` directly.
      bwunlock() {
        local key
        key="$(bw-session)" || return 1
        mkdir -p ~/.cache
        ( umask 077; printf '%s' "$key" > ~/.cache/bw_session )
        export BW_SESSION="$key"
        echo "Bitwarden session ready."
      }
      if [ -z "''${BW_SESSION:-}" ] && [ -r ~/.cache/bw_session ]; then
        BW_SESSION="$(cat ~/.cache/bw_session)"
        [ -n "$BW_SESSION" ] && export BW_SESSION
      fi

      # Scope the t3code gh PR-status shim to ONLY t3code's child processes.
      # t3 resolves git/gh through the PATH it captures from this login shell
      # (`zsh -ilc`), and sets T3CODE_HOME in that capture's env. Interactive
      # logins and Hermes (also nicolai, but no T3CODE_HOME) never set it, so
      # they keep the real gh — the shim is invisible to everything but t3.
      if [[ -n "$T3CODE_HOME" ]]; then
        export PATH="${ghPrShim}/bin:$PATH"
      fi

      # Enable forward delete key
      bindkey "^[[3~" delete-char

      # Create a new Python project with a uv venv
      pynew() {
        mkdir -p "$1" && cd "$1"
        uv venv
        source .venv/bin/activate
        echo "Created new Python project in $1 with uv virtual environment"
      }

      # Install an IPython kernel
      ki() {
        if [ -z "$1" ]; then
          echo "Usage: ki <kernel-name>"
          return 1
        fi
        uv run python -m ipykernel install --user --name "$1"
        echo "Installed IPython kernel: $1"
      }
    '';
    shellAliases.k = "kubectl";
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = true;
      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[✗](bold red)";
      };
      git_branch.style = "bold purple";
      git_status = {
        disabled = true;
        format = "([$all_status$ahead_behind]($style) )";
        style = "bold blue";
      };
    };
  };

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Nicolai Schmid";
        email = "nicolai@schmid.uno";
      };
      core.editor = "vim";
      alias = {
        a = "add";
        r = "reset";
        c = "commit -m";
        up = "pull -r";
        p = "push";
        s = "status";
        amend = "commit --amend --all";
        co = "checkout";
        lg = "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --";
      };
      push = {
        default = "current";
        followTags = true;
      };
      fetch.prune = true;
      diff.compactionHeuristic = true;
      stash.showPatch = true;
      init.defaultBranch = "main";
    };
  };
}
