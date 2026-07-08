{
  description = "Nicolai's nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    darwin.url = "github:lnl7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
    homebrew-steipete-tap = {
      url = "github:steipete/homebrew-tap";
      flake = false;
    };
    homebrew-anomalyco-tap = {
      url = "github:anomalyco/homebrew-tap";
      flake = false;
    };
    rayscripts = {
      url = "path:../rayscripts";
      flake = false;
    };
    dotfiles = {
      url = "path:../dotfiles";
      flake = false;
    };
    nvimconfig = {
      url = "path:../dotfiles/nvim";
      flake = false;
    };
  };

  outputs =
    {
      self,
      darwin,
      nixpkgs,
      home-manager,
      nix-homebrew,
      homebrew-bundle,
      homebrew-steipete-tap,
      homebrew-anomalyco-tap,
      nvimconfig,
      ...
    }@inputs:
    let
      hostConfig = import ./host.nix;
    in
    {
      # Agents VM on the wasc bare-metal host (x86_64-linux). Provisioned by
      # compose-services (ansible/agents-vm.yml); see darwin/agents/.
      nixosConfigurations.domovoi = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [ ./agents/configuration.nix ];
      };

      darwinConfigurations.${hostConfig.hostname} = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = { inherit hostConfig; };
        modules = [
          home-manager.darwinModules.home-manager
          (
            {
              config,
              pkgs,
              lib,
              hostConfig,
              ...
            }:
            {
              system.primaryUser = hostConfig.username;
            }
          )
          ./work.nix
          (
            {
              config,
              pkgs,
              lib,
              ...
            }:
            let
              aiApps = import ./packages/ai-apps.nix { inherit pkgs; };
              inherit (aiApps)
                claude-code
                codex
                opencode
                t3code
                codexDesktop
                ;
            in
            {
              nixpkgs.config.allowUnfree = true;

              system.activationScripts.extraActivation.text = lib.mkIf (hostConfig.installRosetta or false) ''
                softwareupdate --install-rosetta --agree-to-license
              '';

              system.defaults.finder = {
                AppleShowAllExtensions = true; # Show all file extensions in Finder
                _FXSortFoldersFirst = true; # Sort folders first in the Finder
                FXPreferredViewStyle = "Nlsv"; # Use list view in Finder
                ShowStatusBar = true; # Show status bar in Finder (e.g. space left)
                _FXShowPosixPathInTitle = false; # Show POSIX path in window title
                QuitMenuItem = true; # Show "Quit" option in Finder
                ShowPathbar = true; # Show path bar in Finder
                FXDefaultSearchScope = "SCcf"; # Search the current folder by default
                ShowMountedServersOnDesktop = true;
                ShowHardDrivesOnDesktop = true;
                ShowRemovableMediaOnDesktop = true;
                ShowExternalHardDrivesOnDesktop = true;

              };

              system.defaults.menuExtraClock = {
                Show24Hour = true;
                ShowDayOfWeek = false;
                ShowSeconds = false;
                ShowDate = 1;
                ShowDayOfMonth = true;
              };

              system.defaults.trackpad = {
                Clicking = false; # tap to click
              };
              system.startup.chime = false;
              system.defaults.screensaver.askForPasswordDelay = 4;

              system.defaults.CustomUserPreferences = {
                "com.apple.iCal" = {
                  "com.apple.iCal.ShowWeekNumbers" = true;
                  "com.apple.iCal.TimeZoneSupportEnabled" = true;
                };
              };

              environment.systemPackages = with pkgs; [
                nixfmt
                cursor-cli
                vim
                neovim
                uv
                bun
                kubelogin
                watch
                claude-code
                codex
                opencode
                tmux
              ];
              environment.systemPath = [ "/opt/homebrew/bin" ];
              system.keyboard = {
                enableKeyMapping = true;
                remapCapsLockToEscape = true;
              };
              security.pam.services.sudo_local.touchIdAuth = true;
              nix.settings.experimental-features = "nix-command flakes";

              system.configurationRevision = self.rev or self.dirtyRev or null;

              system.stateVersion = 5;

              nixpkgs.hostPlatform = "aarch64-darwin";

              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.${hostConfig.username} =
                {
                  config,
                  pkgs,
                  lib,
                  ...
                }:
                {
                  home = {
                    stateVersion = "24.11";
                    username = hostConfig.username;
                    homeDirectory = lib.mkForce hostConfig.homeDirectory;
                    shell.enableShellIntegration = true;
                  };

                  home.packages = with pkgs; [
                    pnpm
                    yarn
                    gh # GitHub CLI
                    t3code
                    codexDesktop
                    nodejs_24 # Add LTS Node.js
                    go
                    gopls
                    delve
                    gotools
                    golangci-lint

                    postgresql # Includes pg_dump and pg_restore

                    eza
                    google-fonts # Add Roboto and other Google fonts

                    himalaya

                    bitwarden-cli # `bw` secrets CLI
                  ];

                  programs.git = {
                    enable = true;
                    settings = {
                      user = {
                        name = hostConfig.fullName;
                        email = hostConfig.email;
                      };
                      core.editor = "vim";
                      alias = {
                        a = "add";
                        r = "reset";
                        c = "commit -m";
                        up = "pull -r";
                        p = "push";
                        s = "status";
                        amend = "commit --amend --all";
                        co = "checkout";
                        lg = "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --";
                      };
                      push = {
                        default = "current";
                        followTags = true;
                      };
                      filter.lfs = {
                        required = true;
                        clean = "git-lfs clean -- %f";
                        smudge = "git-lfs smudge -- %f";
                        process = "git-lfs filter-process";
                      };
                      fetch.prune = true;
                      diff.compactionHeuristic = true;
                      stash.showPatch = true;
                      init.defaultBranch = "main";
                    };
                  };

                  home.sessionVariables = {
                    # Set history control to ignore commands starting with space
                    HISTCONTROL = "ignorespace";
                  };
                  home.sessionPath = [
                    "$HOME/bin"
                    "$HOME/.cargo/bin"
                    "/opt/homebrew/bin"
                  ];

                  programs.zsh = {
                    enable = true;
                    autosuggestion.enable = true;
                    enableCompletion = false; # We use cached compinit below
                    syntaxHighlighting.enable = true;

                    initContent = ''
                      # Cached compinit - only rebuild once per day
                      autoload -Uz compinit
                      if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
                        compinit
                      else
                        compinit -C
                      fi

                      source ~/.aliases

                      # Enable forward delete key
                      bindkey "^[[3~" delete-char

                      # Helpful alias for creating new Python projects
                      pynew() {
                        mkdir -p "$1" && cd "$1"
                        uv venv
                        source .venv/bin/activate
                        echo "Created new Python project in $1 with uv virtual environment"
                      }

                      # Function to install IPython kernel
                      ki() {
                        if [ -z "$1" ]; then
                          echo "Usage: ki <kernel-name>"
                          return 1
                        fi
                        uv run python -m ipykernel install --user --name "$1"
                        echo "Installed IPython kernel: $1"
                      }
                    '';

                    shellAliases = {
                      k = "kubectl";
                    };
                  };
                  # Starship prompt - a customizable cross-shell prompt
                  programs.starship = {
                    enable = true;
                    settings = {
                      add_newline = true;
                      character = {
                        success_symbol = "[➜](bold green)";
                        error_symbol = "[✗](bold red)";
                      };
                      git_branch = {
                        style = "bold purple";
                      };
                      git_status = {
                        disabled = true;
                        format = "([$all_status$ahead_behind]($style) )";
                        style = "bold blue";
                      };
                    };
                  };

                  programs.ssh = {
                    enable = true;
                    enableDefaultConfig = false;
                    settings = {
                      "*" = {
                        AddKeysToAgent = "yes";
                        UseKeychain = "yes";
                        IdentityFile = "~/.ssh/id_rsa";
                        Protocol = 2;
                        ControlMaster = "auto";
                        ControlPersist = 1800;
                        Compression = true;
                        TCPKeepAlive = true;
                        ServerAliveInterval = 20;
                        ServerAliveCountMax = 10;
                        ForwardAgent = false;
                      };
                      "cx22" = {
                        HostName = "65.108.88.62";
                        User = "root";
                        IdentityFile = "~/.ssh/id_ansible";
                      };
                      "ci1" = {
                        HostName = "ci1.cis.git.nicolaischmid.de";
                        Port = 1329;
                        User = "dw";
                      };
                      "one" = {
                        HostName = "one.nunc.immo";
                        User = "root";
                        IdentityFile = "~/.ssh/id_ansible";
                      };
                      "tower" = {
                        HostName = "10.0.0.99";
                        Port = 22;
                        User = "root";
                      };
                      "rtower" = {
                        HostName = "tower.takaya-buri.ts.net";
                        Port = 22;
                        User = "root";
                      };
                    };
                  };

                  home.file = {
                    "Applications/T3 Code.app" = {
                      source = "${t3code}/Applications/T3 Code.app";
                    };

                    "Applications/Codex.app" = {
                      source = "${codexDesktop}/Applications/Codex.app";
                    };

                    "Documents/rayscripts/enable-sleep.sh" = {
                      text = builtins.readFile "${inputs.rayscripts}/enable-sleep.sh";
                      executable = true;
                    };

                    "Documents/rayscripts/disable-sleep.sh" = {
                      text = builtins.readFile "${inputs.rayscripts}/disable-sleep.sh";
                      executable = true;
                    };
                    ".aliases" = {
                      text = builtins.readFile "${inputs.dotfiles}/.aliases";
                    };
                    ".config/nvim" = {
                      source = inputs.nvimconfig;
                      recursive = true;
                    };
                  };
                };

              homebrew = {
                enable = true;
                onActivation = {
                  autoUpdate = true;
                  cleanup = "none";
                  upgrade = false;
                };
                global = {
                  autoUpdate = true;
                  brewfile = true;
                };
                taps = [
                  "homebrew/bundle"
                  "steipete/tap"
                  "anomalyco/tap"
                ];
                casks = [
                  "signal"
                  "claude"
                  "cap"
                  "chatgpt"
                  "banking-4"
                  "mx-power-gadget"
                  "google-chrome"
                  "google-drive"
                  "telegram"
                  "owncloud"
                  "betterdisplay" # to fix wrong TV role for displays
                  "discord"
                  "disk-inventory-x"
                  "visual-studio-code"
                  "cursor"
                  "zen"
                  "ghostty"
                  "orbstack"
                  "bartender"
                  "whatsapp"
                  # The current Homebrew Ruby cask has duplicate macOS dependencies.
                  # Keep the existing install unmanaged until the cask is fixed.
                  "openscad"
                  "affinity-photo"
                  "affinity-designer"
                  "affinity-publisher"
                  "affinity"
                  "caffeine"
                  "stats"
                  "zoom"
                  "slack"
                  "raycast"
                  "obsidian"
                  "spotify"
                  "cyberduck"
                  "portfolioperformance"
                  "intune-company-portal"
                  "obs"
                  "bambu-studio"
                  "descript"
                  "legcord"
                  "tailscale-app"
                  "vlc"
                  # manual install the correct 2022.3 version
                  "datagrip"
                  "mochi"
                  "microsoft-teams"
                  "surfshark"
                  "lulu"
                  "trezor-suite"
                  "yaak"
                  "transmission"
                  "jamie"
                  "linear"
                  "beeper"
                  "helium-browser"
                  "steipete/tap/codexbar"
                  "font-fira-code-nerd-font"
                ];
                brews = [
                  {
                    name = "mas";
                    args = [ "HEAD" ];
                  }
                  "railway"
                  "ffmpeg"
                  "azure-cli"
                  "yt-dlp"
                  "pulumi"
                  "typst"
                  "rustup-init"
                  "gpac"
                  "imagemagick"
                  "mediainfo"
                  "imapsync"
                  "k6"
                  "poppler"
                  "lazygit"
                  "tree-sitter"
                  "fzf"
                  "ripgrep"
                  "fd"
                ];
                # `mas install` currently fails during brew bundle even for already installed apps.
                masApps = { };
              };

              system.activationScripts.homebrew.text = lib.mkForce ''
                echo >&2 "Homebrew bundle..."
                if [ -f "${config.homebrew.prefix}/bin/brew" ]; then
                  PATH="${config.homebrew.prefix}/bin:${lib.makeBinPath [ pkgs.mas ]}:$PATH" \
                  sudo \
                    --preserve-env=PATH \
                    --user=${lib.escapeShellArg config.homebrew.user} \
                    --set-home \
                    env \
                    HOMEBREW_NO_INSTALL_FROM_API=1 \
                    ${config.homebrew.onActivation.brewBundleCmd}

                  if [ -e "${config.homebrew.prefix}/bin/codex" ]; then
                    /usr/bin/xattr -d com.apple.quarantine "${config.homebrew.prefix}/bin/codex" 2>/dev/null || true
                  fi
                else
                  echo -e "\e[1;31merror: Homebrew is not installed, skipping...\e[0m" >&2
                fi
              '';

              system.defaults.dock = {
                persistent-apps = [
                  "/System/Applications/Mail.app"
                  "/Applications/Signal.app"
                  "/Applications/Zen.app"
                  "/Applications/Spotify.app"
                  "/Applications/Ghostty.app"
                  "/Applications/Obsidian.app"
                  "/Applications/Cursor.app"
                  "/Applications/Linear.app"
                ];
                orientation = "bottom"; # Dock position on screen
                autohide = true; # Don't automatically hide the dock
                tilesize = 56; # Dock icon size
                magnification = true; # Enable dock magnification
                largesize = 76; # Magnified dock icon size
                autohide-delay = 0.0;
                autohide-time-modifier = 0.0;
              };

              system.defaults.NSGlobalDomain = {
                NSAutomaticCapitalizationEnabled = false;
                NSAutomaticDashSubstitutionEnabled = false;
                NSAutomaticInlinePredictionEnabled = false;
                NSAutomaticPeriodSubstitutionEnabled = false;
                NSAutomaticQuoteSubstitutionEnabled = false;
                NSAutomaticSpellingCorrectionEnabled = false;
              };
            }
          )
          nix-homebrew.darwinModules.nix-homebrew
          (
            { pkgs, lib, ... }:
            {
              nix-homebrew = {
                enable = true;
                user = hostConfig.username;
                mutableTaps = true;
                taps = {
                  "homebrew/homebrew-bundle" = homebrew-bundle;
                  "steipete/tap" = homebrew-steipete-tap;
                  "anomalyco/tap" = homebrew-anomalyco-tap;
                };
              };
            }
          )
        ];
      };
    };
}
