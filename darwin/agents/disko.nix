# Declarative disk layout for the VM (used by nixos-anywhere at install time;
# also provides config.fileSystems for ongoing nixos-rebuild). BIOS/GPT so it
# boots on plain qemu without OVMF.
{ ... }:
{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/vda";
    content = {
      type = "gpt";
      partitions = {
        boot = {
          size = "1M";
          type = "EF02"; # BIOS boot partition for GRUB
        };
        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };
}
