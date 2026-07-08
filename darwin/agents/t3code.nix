# t3code — runs as a native systemd service. t3 is a Bun app whose dependency
# tree npm cannot lock, so we run it the way it is designed: Bun, pinned via a
# committed bun.lock (./t3code-app). The agent CLIs (claude, codex) and the dev
# toolchain come from nix and are on the service PATH, so agents can "do things"
# with the full VM toolchain. State lives on the virtiofs-backed state dir.
{ config, pkgs, lib, ... }:
let
  stateDir = "/srv/agents-state/t3code";
  appDir = "${stateDir}/app";
  # Shared with interactive logins (gh/claude/codex) so the service sees them.
  homeDir = "/srv/agents-state/nicolai";
  workspace = "/srv/agents-state/workspace";
  manifest = ./t3code-app;
in
{
  systemd.services.t3code = {
    description = "T3 Code server";
    wantedBy = [ "multi-user.target" ];
    after = [
      "network-online.target"
      "tailscaled.service"
    ];
    wants = [ "network-online.target" ];

    # The full agent toolchain on PATH: bun runs t3; claude/codex are the
    # providers t3 shells out to; git + the rest let agents actually work.
    path =
      (with pkgs; [
        bun
        nodejs_24
        tailscale
        claude-code
        codex
        git
        coreutils
      ])
      ++ import ../packages/cli-tools.nix { inherit pkgs; };

    environment = {
      HOME = homeDir;
      T3CODE_HOME = stateDir;
      XDG_CONFIG_HOME = "${homeDir}/.config";
    };

    serviceConfig = {
      User = "nicolai";
      Group = "users";
      # Provider API keys (ANTHROPIC_API_KEY etc.); written by the host playbook.
      EnvironmentFile = "-/srv/agents-state/secrets/t3code.env";
      # No WorkingDirectory: appDir is created by ExecStartPre (which cd's into
      # it); setting it here would CHDIR-fail before that runs. bun resolves
      # node_modules from the script's absolute path, so cwd is irrelevant.
      Restart = "on-failure";
      RestartSec = 5;

      # Install the pinned t3 closure (frozen lockfile → deterministic, a no-op
      # once present). Bun's cache lives under the persisted HOME.
      ExecStartPre = pkgs.writeShellScript "t3code-install" ''
        set -euo pipefail
        mkdir -p "${appDir}" "${homeDir}" "${workspace}"
        install -m644 "${manifest}/package.json" "${appDir}/package.json"
        install -m644 "${manifest}/bun.lock" "${appDir}/bun.lock"
        cd "${appDir}"
        ${pkgs.bun}/bin/bun install --frozen-lockfile
      '';

      # Bind loopback only; the dedicated `t3code` Tailscale node serves it on
      # the tailnet (see tailscale-uis.nix).
      ExecStart = ''
        ${pkgs.bun}/bin/bun "${appDir}/node_modules/t3/dist/bin.mjs" serve \
          --mode web --host 127.0.0.1 --port 3773 --no-browser \
          --base-dir "${stateDir}" "${workspace}"
      '';
    };
  };
}
