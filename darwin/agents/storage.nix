# Persistent state is a single virtiofs mount from the host's btrfs subvolume
# (/srv/agents-state). Children: t3code/, hermes/, workspace/, secrets/.
# The host (compose-services) owns provisioning + btrbk of this directory.
{ ... }:
{
  fileSystems."/srv/agents-state" = {
    device = "agents-state"; # virtiofs mount tag (see the libvirt domain)
    fsType = "virtiofs";
    options = [ "rw" ];
  };
}
