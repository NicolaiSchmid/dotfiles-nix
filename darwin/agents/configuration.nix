# NixOS configuration for the "agents" VM running on the wasc bare-metal host.
# Isolation boundary for autonomous agents (t3code + Hermes), fenced off from
# the host's sensitive Docker stack. Provisioned by compose-services
# (ansible/agents-vm.yml); this flake is its OS.
{
  config,
  pkgs,
  lib,
  inputs,
  modulesPath,
  ...
}:
let
  laptopKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAEAQCsBs0tK+2TlbdkVk7Bu5DJbLIJb4pQtcexCIcJUzzBGWISfzKfluNRkrL/NzUS8ajVVfmQcig63KpnHNDhubZb9imfr/IJZDf8iRSM7PBp++hj4SW5ZUgcFEgoUGBV+FabTLF/yZm5bcDD6dxyvdDkSQfnZ5gFGEZPSlR+j1VuF3DvpC/Oiwt2ZhZVrgzm9ZWQTec6tGPOYdtTr0hfIzijis0k3GKW7RNe5R+6LRHrvx1srkjgvP+ibpYnuQW46NMqVFscq7hGWuLwjDm9si/jGf0P1VicbOHekaI3K22HUjj0d2FLjSq1Otofpw3NH4wdx+kuOs8bIAD6q1MEu3w4RjJYAV7+kyipTi+C/gOlewAsnTNvpW2q8a7bfh7QS1fw0sbrKDQaUfQLNMC5On73AHlZSjp+4R/eB0HUPA7PjsKwlT6yi8w/HCIC2hajYxY+z6LXhZBEG8+SSSGeZwsCe5uBdhMRfr7Pohlfd0XwQNd8XVn6TRQdVVmrNurVh61Ahj/QXjqf9sfB0Z0E7mpM/TEGtpmRV5yeM/wBS9tcPnqCNydY5G8I/dVV+xgHP3E5RpDiOxiZwBmCYakZOMqit6igwgiRWzmXSZLvvtPQwli+UKYxA54NpSfwCaBBKnf4QvZuMPJhgVxQF8/NrdRJmT2FG8Ov6xxv/Rq0iQrqpAxvRxBYdYqCssqTslk/BBRDL5/2Dmb6NXbVWcb4/cf6tXwP0m1b6fYnBKy+dQfddvd52/5U911/D2tu2DrPguiSyw5hQJfxOke4y1uZpA9+inFi8GrNDP1Um4UP9sJtFymQgJPCrzxi2SSc0W9WeCYAf1p0M0GHCFkUByuZl/DrwTNt7P6TNF1+hgfn5DMH3xREB3y8IYpeT9dQdfsdTDzg03+OCMDvty30D/Q9+kyaJZyvMg9V4CrV2Y8e/m4RqlhP+h6fQpZlvj8DETmt2BuyMshAtDWelcwgtWhMtedK0HnVo7eZDJ7dbr3BZQOYinMivTjA7SUxgvAMLX2zhnWiU9sqQ+uAkEqWohwgYo4cyDz7fEpdez6EOOR2HADwZDgl3u31IzWxM2Bdi6EhYj2QmPdkXl0jIAG5j9Hj3PC7tNi13UJxEtmaFRUskFmA7GiMFOQX2PzSeA3zPNZqaf1HchXNphJhGmpL9ZniSyL0fxWSbothJZvXJdsaX+ffEHvhACgvWWHXlLJXxh6gzDkIUYrM/RA9M2L+5OyZbbhikiGc8RDi2gGwvcev4U4Tg8rfPxB9asJvZiLmPyYD2NQjV+q8/22SyP0+5W/8tszwTVMagD83Bob1znVRMtrzaW18ke5y6M49gjBm12QiGfrBanoZtF1mSqtcgO88qHmz Nicolai@DESKTOP-8VNI4J8";
  hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPVXG4cuA28KOV+6aDOpyFXiI/p3kf1fOmhJhJF7ynv1 root@one";
  # Hermes container -> VM ssh (TERMINAL_ENV=ssh), so its shell/CLIs run as nicolai.
  hermesKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJWQiNS62UPRvbxNfkM0EzQIagNMOFFa9tzH0OOgSJEv hermes@domovoi";
in
{
  imports = [
    # virtio initrd modules (virtio_blk/_pci/_scsi) so the VM can find its root disk
    (modulesPath + "/profiles/qemu-guest.nix")
    inputs.disko.nixosModules.disko
    ./disko.nix
    ./storage.nix
    ./tailscale.nix
    ./tailscale-uis.nix
    ./t3code.nix
    ./hermes.nix
    ./process-watch.nix
    ./home.nix
  ];

  # disko configures grub.devices for the EF02 partition; just enable it.
  boot.loader.grub.enable = true;
  # Auto-grow the root partition/filesystem to fill the disk (so resizing the
  # qcow2 is all it takes to give the VM more space).
  boot.growPartition = true;
  fileSystems."/".autoResize = true;
  # Serial console so the host can `virsh console agents` for debugging.
  boot.kernelParams = [
    "console=ttyS0,115200"
    "console=tty0"
  ];
  # Allow unprivileged ICMP so `ping` works for nicolai (the agent user), not just root.
  boot.kernel.sysctl."net.ipv4.ping_group_range" = "0 2147483647";

  networking.hostName = "domovoi";
  networking.useDHCP = lib.mkDefault true;
  networking.firewall = {
    enable = true;
    # Tailscale is the only ingress; trust the tailnet interface, block the rest.
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPorts = [
      config.services.tailscale.port
      41642
    ];
  };

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
  };

  users.users.root.openssh.authorizedKeys.keys = [
    hostKey
    laptopKey
  ];
  users.users.nicolai = {
    isNormalUser = true;
    uid = 1000;
    description = "Nicolai Schmid";
    # Home on the persisted state mount: interactive logins (gh/claude/codex)
    # and the t3code service share one backed-up home.
    home = "/srv/agents-state/nicolai";
    createHome = true;
    extraGroups = [
      "wheel"
      "docker"
    ];
    openssh.authorizedKeys.keys = [
      laptopKey
      hermesKey
    ];
  };

  # Persist the tailscale node identity across VM rebuilds (the disk is cattle).
  fileSystems."/var/lib/tailscale" = {
    device = "/srv/agents-state/tailscale";
    fsType = "none";
    options = [
      "bind"
      "x-systemd.requires-mounts-for=/srv/agents-state"
    ];
  };
  security.sudo.wheelNeedsPassword = false;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages =
    (import ../packages/cli-tools.nix { inherit pkgs; })
    ++ (with pkgs; [
      claude-code
      codex
      chromium
      tailscale
    ]);

  # git identity + aliases come from home-manager (home-shell.nix), for both
  # nicolai and root.

  # Run generic dynamically-linked Linux binaries (npm/pip prebuilts like
  # Biome, esbuild, native node modules) on NixOS — provides a real loader at
  # the standard /lib64 path + common shared libs via NIX_LD_LIBRARY_PATH.
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib
    zlib
    zstd
    openssl
    curl
    icu
    libgcc
    # Playwright/Chromium runtime libs (libglib-2.0.so.0 = glib, etc.)
    glib
    nss
    nspr
    atk
    at-spi2-atk
    at-spi2-core
    cups
    dbus
    expat
    cairo
    pango
    gdk-pixbuf
    gtk3
    libdrm
    libxkbcommon
    mesa
    libgbm # libgbm.so.1 (split out of mesa in recent nixpkgs)
    systemd # libudev.so.1
    alsa-lib
    fontconfig
    freetype
    libGL
    libx11
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
    libxrender
    libxtst
    libxi
    libxcb
    libxscrnsaver
    libxshmfence
  ];

  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;
  users.users.root.shell = pkgs.zsh; # so `ssh root@domovoi` gets the same shell
  # starship/git/aliases are configured per-user via home-manager (home.nix)

  time.timeZone = "Europe/Berlin";
  system.stateVersion = "24.11";
}
