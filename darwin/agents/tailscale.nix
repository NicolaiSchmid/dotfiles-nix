# Tailscale is the only ingress. It also serves the t3code UI (t3 configures
# Serve itself via --tailscale-serve) and the Hermes dashboard (hermes.nix).
# The service user `nicolai` is the operator so it may run `tailscale serve`.
{ ... }:
{
  services.tailscale = {
    enable = true;
    authKeyFile = "/srv/agents-state/secrets/tailscale.authkey";
    port = 41641;
    extraUpFlags = [
      "--ssh"
      "--hostname=domovoi"
      "--operator=nicolai"
    ];
  };
}
