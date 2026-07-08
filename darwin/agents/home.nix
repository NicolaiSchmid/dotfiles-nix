# home-manager on the VM — gives both the agent user (nicolai) and root the
# same real shell config (see home-shell.nix), so it's consistent whether you
# `ssh nicolai@domovoi` or `ssh root@domovoi`.
{ inputs, ... }:
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-bak"; # take over the bootstrap ~/.zshrc stub
    users.nicolai = import ./home-shell.nix;
    users.root = import ./home-shell.nix;
  };
}
