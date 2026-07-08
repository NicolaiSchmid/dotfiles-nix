{
  config,
  pkgs,
  lib,
  hostConfig,
  ...
}:
{
  # Only include these configurations if enableWork is true
  home-manager.users.${hostConfig.username} = lib.mkIf hostConfig.enableAISECHosts {
    programs.ssh.settings = {
      "dgx1" = {
        HostName = "dgx-a100-node1.aisec.fraunhofer.de";
        User = "darwah";
      };
      "dgx2" = {
        HostName = "dgx-a100-node2.aisec.fraunhofer.de";
        User = "dar80083";
      };
      "dgx3" = {
        HostName = "dgx-a100-node3.aisec.fraunhofer.de";
        User = "darwah";
      };
      "ski" = {
        HostName = "sensibleki1.aisec.fraunhofer.de";
        Port = 42957;
        User = "darwah";
        ServerAliveInterval = 60;
        ServerAliveCountMax = 30;
      };
      "ski-adm" = {
        HostName = "sensibleki1.aisec.fraunhofer.de";
        Port = 42957;
        User = "adm-user";
      };
    };
  };

  # These can stay at the system level, but also make them conditional
  homebrew = lib.mkIf hostConfig.enableWork {
    casks = [
      "cisco-jabber"
    ];

    masApps = {
      "Microsoft Outlook" = 985367838;
      "Microsoft Excel" = 462058435;
      "Microsoft Word" = 462054704;
      "Microsoft PowerPoint" = 462062816;
      "OneDrive" = 823766827;
    };
  };
}
