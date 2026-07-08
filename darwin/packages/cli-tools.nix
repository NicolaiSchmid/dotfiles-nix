# Shared CLI toolchain — the nix equivalents of the Homebrew `brews` plus the
# core dev tools from the laptop's home.packages. Imported by the agents VM
# (and, later, by the darwin host once its brews are migrated).
#
# `pkgs` resolves per-platform: aarch64-darwin on the laptop, x86_64-linux on
# the agents VM. The same names give the right binaries on each.
{ pkgs }:
with pkgs;
[
  # search / navigation / git
  ripgrep
  fd
  fzf
  eza
  lazygit
  tree-sitter
  neovim
  tmux
  gh
  git
  git-lfs

  # language runtimes / package managers
  nodejs_24
  bun
  pnpm
  yarn
  uv

  # go toolchain
  go
  gopls
  delve
  gotools
  golangci-lint

  # rust (rustup manages toolchains, like `rustup-init` on the mac)
  rustup

  # postgres client (pg_dump / pg_restore)
  postgresql

  # media / documents (formerly Homebrew brews)
  ffmpeg
  imagemagick
  poppler-utils
  yt-dlp
  typst
  mediainfo
  gpac

  # infra / misc CLIs (formerly Homebrew brews)
  k6
  imapsync
  azure-cli
  railway
  pulumi-bin

  # secrets / credentials
  bitwarden-cli

  # general shell utilities the agents lean on
  jq
  curl
  wget
  unzip
  openssh

  # networking / diagnostics (dig, nslookup, host, ping, traceroute, ...)
  dnsutils
  iputils
  traceroute
  mtr
  whois
  netcat-gnu
  socat
  tcpdump
  nmap

  # base unix tools NixOS' minimal base omits but you'd expect anywhere
  vim # also the git core.editor; only nvim was present before
  file
  tree
  htop
  lsof
  psmisc # killall, pstree, fuser
  zip
  bat

  # C build toolchain (native deps: node-gyp, python wheels, etc.)
  gcc
  gnumake
  pkg-config
  python3
]
