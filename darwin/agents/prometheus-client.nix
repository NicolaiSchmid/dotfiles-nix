# atlas: Claude Code + Codex (incl. t3code's providers) use the prometheus hub
# instead of atlas's own logins. Runs `ai-hub on` on every home-manager
# activation; it only touches the hub keys, so the CLIs keep writing their own
# settings. The access key lives in ~/.config/prometheus/access-key (0600, on
# the state volume, never in the store). Revert: `ai-hub off` + drop this import.
{ pkgs, lib, ... }:
let
  aiHub = pkgs.callPackage ../packages/ai-hub { };
in
{
  home.packages = [ aiHub ];

  home.activation.prometheusClient = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -r "$HOME/.config/prometheus/access-key" ]; then
      run ${aiHub}/bin/ai-hub on
    else
      warnEcho "prometheus-client: no ~/.config/prometheus/access-key, leaving Claude/Codex configs alone"
    fi
  '';
}
