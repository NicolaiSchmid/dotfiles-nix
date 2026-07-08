# Hermes Agent (NousResearch, MIT). Upstream ships only a Docker image, so we
# run it as a container — but its shell/tools execute ON the VM as nicolai via
# TERMINAL_ENV=ssh, so Hermes uses the SAME CLIs (claude/codex/bun), /workspace
# and $HOME as t3code. The container is just Hermes' engine; ssh is its hands.
# Configure providers/messaging with `hermes setup` (Codex/ChatGPT subscription
# via `hermes model`; Slack via the dashboard, served on the domovoi node).
{ config, pkgs, lib, ... }:
let
  dataDir = "/srv/agents-state/hermes";
  repoDir = "${dataDir}/src";
  containerData = "${dataDir}/data";
  docker = "${pkgs.docker}/bin/docker";
in
{
  virtualisation.docker.enable = true;

  # `hermes ...` on the VM host runs the CLI inside the container, so
  # `hermes model` / `hermes setup` work over a plain `ssh domovoi`.
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "hermes" ''exec ${docker} exec -it hermes hermes "$@"'')
  ];

  # Build the image from source (no upstream published image; idempotent/cached).
  systemd.services.hermes-image = {
    description = "Build Hermes Agent docker image";
    wantedBy = [ "multi-user.target" ];
    after = [
      "docker.service"
      "network-online.target"
    ];
    wants = [ "network-online.target" ];
    requires = [ "docker.service" ];
    unitConfig.RequiresMountsFor = [ "/srv/agents-state" ];
    path = [
      pkgs.docker
      pkgs.git
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      TimeoutStartSec = "30min";
    };
    script = ''
      set -euo pipefail
      mkdir -p "${dataDir}" "${containerData}"
      if [ ! -d "${repoDir}/.git" ]; then
        git clone --depth 1 https://github.com/NousResearch/hermes-agent "${repoDir}"
      else
        git -C "${repoDir}" pull --ff-only || true
      fi
      docker build -t hermes-agent:latest "${repoDir}"
    '';
  };

  systemd.services.hermes = {
    description = "Hermes Agent gateway";
    wantedBy = [ "multi-user.target" ];
    after = [ "hermes-image.service" ];
    requires = [ "hermes-image.service" ];
    path = [ pkgs.docker ];
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = 10;
      ExecStartPre = "-${docker} rm -f hermes";
      # TERMINAL_ENV=ssh: the agent's shell/tools run ON the VM as nicolai (full
      # nix toolchain + /workspace), not in a throwaway sandbox container.
      #
      # ONE container runs gateway + dashboard, per upstream's documented shape
      # (HERMES_DASHBOARD=1 brings the dashboard up as an s6 service alongside
      # the gateway). Running a *second* container for the dashboard makes both
      # reconcile the persisted gateway profile from the shared /opt/data and
      # start a gateway each — two gateways fight over the Telegram/Slack stream
      # (dropped updates → no responses). So the dashboard lives here.
      ExecStart = ''
        ${docker} run --rm --name hermes \
          --network host \
          -v ${containerData}:/opt/data \
          -v /srv/agents-state/secrets/hermes_ssh:/secrets/hermes_ssh:ro \
          --env-file /srv/agents-state/secrets/hermes-dashboard.env \
          -e HERMES_UID=1000 -e HERMES_GID=100 \
          -e HERMES_DASHBOARD=1 \
          -e TERMINAL_ENV=ssh \
          -e TERMINAL_SSH_HOST=127.0.0.1 \
          -e TERMINAL_SSH_USER=nicolai \
          -e TERMINAL_SSH_PORT=22 \
          -e TERMINAL_SSH_KEY=/secrets/hermes_ssh \
          hermes-agent:latest gateway run
      '';
      ExecStop = "${docker} stop hermes";
    };
  };

  # (No separate dashboard container: the gateway container runs the dashboard
  # too via HERMES_DASHBOARD=1 — see the hermes service above. A second
  # container would spawn a duplicate gateway off the shared /opt/data.)

  # Serve the dashboard on the domovoi tailnet node (domovoi IS the assistant).
  systemd.services.hermes-serve = {
    description = "Tailscale Serve (domovoi node) -> Hermes dashboard";
    wantedBy = [ "multi-user.target" ];
    after = [
      "tailscaled.service"
      "hermes.service"
    ];
    path = [ pkgs.tailscale ];
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = 30;
    };
    script = ''
      tailscale serve --bg --https=443 http://127.0.0.1:9119
      exec sleep infinity
    '';
  };
}
