# Monitor-only guardrails for autonomous agent subprocesses.
#
# This deliberately does not kill or restart anything. It logs suspicious
# long-running processes to journald so runaway commands are visible before
# they stall t3code/Hermes or fill the host.
{ pkgs, ... }:
let
  processWatch = pkgs.writeShellScript "agents-process-watch" ''
    set -euo pipefail

    ${pkgs.procps}/bin/ps -eo pid=,ppid=,etimes=,pcpu=,pmem=,comm=,args= |
      ${pkgs.gawk}/bin/awk '
        function log(reason, line) {
          cmd = "${pkgs.util-linux}/bin/logger -t agents-process-watch -- " q reason ": " line q
          system(cmd)
        }

        BEGIN {
          q = sprintf("%c", 39)
        }

        {
          pid = $1
          ppid = $2
          etimes = $3 + 0
          pcpu = $4 + 0
          pmem = $5 + 0
          comm = $6

          args = $0
          sub(/^[[:space:]]*[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9.]+[[:space:]]+[0-9.]+[[:space:]]+[^[:space:]]+[[:space:]]+/, "", args)

          if ((index(args, "glob.glob(") || index(args, "glob(")) && index(args, "/**/")) {
            log("root recursive glob", $0)
          } else if (comm ~ /^python/ && args ~ /python3? -/ && etimes > 1800 && pcpu > 80) {
            log("long high-cpu stdin python", $0)
          } else if (args ~ /(^|[[:space:]])rm[[:space:]]+-[^[:space:]]*i/ && etimes > 900) {
            log("stuck interactive rm", $0)
          } else if ((args ~ /codex exec/ || args ~ /claude --/) && etimes > 21600 && pcpu > 50) {
            log("long high-cpu agent subprocess", $0)
          }
        }
      '
  '';
in
{
  systemd.services.agents-process-watch = {
    description = "Log suspicious autonomous agent subprocesses";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = processWatch;
    };
  };

  systemd.timers.agents-process-watch = {
    description = "Run autonomous agent subprocess monitor";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5min";
      OnUnitActiveSec = "5min";
      AccuracySec = "30s";
      Unit = "agents-process-watch.service";
    };
  };
}
