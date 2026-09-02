# t3code's web UI gets its own Tailscale node/hostname (Serve is per-node):
#   t3code.<tailnet>  -> t3code UI (127.0.0.1:3773)
# The Hermes dashboard is served through the workload host's primary Tailscale
# node; “Domovoi” is the assistant name, not the host. See hermes.nix. Serving
# needs HTTPS Certificates enabled on the tailnet; until then it retries.
{ config, pkgs, lib, ... }:
let
  ts = "${pkgs.tailscale}/bin/tailscale";
  tsd = "${pkgs.tailscale}/bin/tailscaled";
  authKey = "/srv/agents-state/secrets/tailscale.authkey";
  nodePorts = {
    t3code = 41642;
  };

  mkNode = name: port: {
    "tailscaled-${name}" = {
      description = "tailscaled — ${name} UI node";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      unitConfig.RequiresMountsFor = [ "/srv/agents-state" ];
      serviceConfig = {
        ExecStart = "${tsd} --tun=userspace-networking --statedir=/srv/agents-state/ts-${name} --socket=/run/tailscale-${name}/tailscaled.sock --port=${toString nodePorts.${name}}";
        RuntimeDirectory = "tailscale-${name}";
        Restart = "on-failure";
        RestartSec = 5;
      };
    };
    "tailscale-${name}-serve" = {
      description = "tailscale up + serve — ${name} (:${toString port})";
      wantedBy = [ "multi-user.target" ];
      after = [ "tailscaled-${name}.service" ];
      requires = [ "tailscaled-${name}.service" ];
      unitConfig.RequiresMountsFor = [ "/srv/agents-state" ];
      serviceConfig = {
        Restart = "on-failure"; # retry until HTTPS certs are enabled on the tailnet
        RestartSec = 30;
      };
      script = ''
        sock=/run/tailscale-${name}/tailscaled.sock
        ${ts} --socket="$sock" up --authkey="$(cat ${authKey})" --hostname=${name} --accept-dns=false
        ${ts} --socket="$sock" serve --bg --https=443 "http://127.0.0.1:${toString port}"
        exec sleep infinity
      '';
    };
  };
in
{
  systemd.services = mkNode "t3code" 3773;
}
