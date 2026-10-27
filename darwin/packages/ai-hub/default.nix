# `ai-hub on|off|status` — point Claude Code + Codex at the prometheus
# CLIProxyAPI hub (agent-infra hosts/forge/prometheus) or back to the local
# login. Shared by the Mac (manual fallback toggle) and atlas (forced on).
{ writeShellScriptBin, python3 }:
let
  python = python3.withPackages (p: [ p.tomlkit ]);
in
writeShellScriptBin "ai-hub" ''
  exec ${python}/bin/python3 ${./ai-hub.py} "$@"
''
