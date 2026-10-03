{ pkgs }:
{
  codex = pkgs.stdenv.mkDerivation rec {
    pname = "codex";
    version = "0.160.0";
    src = pkgs.fetchurl {
      url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-aarch64-apple-darwin.tar.gz";
      sha256 = "sha256-B8PHyjdqj3kRFTQvUxON2jfpfPopuBJdBlLZN4SJS10=";
    };
    codeModeHostSrc = pkgs.fetchurl {
      url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-code-mode-host-aarch64-apple-darwin.tar.gz";
      sha256 = "sha256-3HD7x26dyuWuPVQkgIyOfC314NtKyCfd1PvjOQFarXU=";
    };
    unpackPhase = ''
      tar -xzf "$src"
      tar -xzf "$codeModeHostSrc"
    '';
    installPhase = ''
      mkdir -p "$out/bin"
      cp codex-aarch64-apple-darwin "$out/bin/codex"
      cp codex-code-mode-host-aarch64-apple-darwin "$out/bin/codex-code-mode-host"
      chmod +x "$out/bin/codex" "$out/bin/codex-code-mode-host"
    '';
  };

  opencode = pkgs.stdenv.mkDerivation rec {
    pname = "opencode";
    version = "1.18.32";
    src = pkgs.fetchurl {
      url = "https://github.com/anomalyco/opencode/releases/download/v${version}/opencode-darwin-arm64.zip";
      sha256 = "sha256-+mQ/k0AcE1CNjVE3gOVM6cwBID1QERS+m4jWJAi4EB8=";
    };
    nativeBuildInputs = [ pkgs.unzip ];
    unpackPhase = "unzip $src";
    installPhase = ''
      mkdir -p $out/bin
      cp opencode $out/bin/
      chmod +x $out/bin/opencode
    '';
  };

  claude-code = pkgs.stdenv.mkDerivation rec {
    pname = "claude-code";
    version = "2.1.288";
    src = pkgs.fetchurl {
      url = "https://downloads.claude.ai/claude-code-releases/${version}/darwin-arm64/claude";
      sha256 = "sha256-u+kwY/egh5oQIbKJHlyTVOWzuYQz4y7+Z1D3cQr+11A=";
    };
    dontUnpack = true;
    installPhase = ''
      mkdir -p "$out/bin"
      install -m755 "$src" "$out/bin/claude"
    '';
  };

  t3code = pkgs.stdenv.mkDerivation rec {
    pname = "t3code";
    version = "0.0.45";
    src = pkgs.fetchurl {
      url = "https://github.com/pingdotgg/t3code/releases/download/v${version}/T3-Code-${version}-arm64.zip";
      sha256 = "sha256-J+48WUpKEOjLrWvXJJlymsGhBtkPHDn7igP9kwpbvQY=";
    };
    nativeBuildInputs = [
      pkgs.unzip
      pkgs.makeWrapper
    ];
    dontStrip = true;
    dontFixup = true;
    unpackPhase = "unzip $src";
    installPhase = ''
      mkdir -p "$out/Applications" "$out/bin"
      cp -R "T3 Code (Alpha).app" "$out/Applications/T3 Code.app"
      chmod +x "$out/Applications/T3 Code.app/Contents/MacOS/T3 Code (Alpha)"
      makeWrapper "$out/Applications/T3 Code.app/Contents/MacOS/T3 Code (Alpha)" "$out/bin/t3code"
    '';
  };

  t3codeNightly = pkgs.stdenv.mkDerivation rec {
    pname = "t3code-nightly";
    version = "0.0.46-nightly.20261003.2623";
    src = pkgs.fetchurl {
      url = "https://github.com/pingdotgg/t3code/releases/download/v${version}/T3-Code-${version}-arm64.zip";
      sha256 = "sha256-NX68SsAYe3q6FyOmAHm9Ww8vhf6dBaPE2XtwKX9Key8=";
    };
    nativeBuildInputs = [
      pkgs.unzip
      pkgs.makeWrapper
    ];
    dontStrip = true;
    dontFixup = true;
    unpackPhase = "unzip $src";
    installPhase = ''
      mkdir -p "$out/Applications" "$out/bin"
      cp -R "T3 Code (Nightly).app" "$out/Applications/T3 Code Nightly.app"
      chmod +x "$out/Applications/T3 Code Nightly.app/Contents/MacOS/T3 Code (Nightly)"
      makeWrapper "$out/Applications/T3 Code Nightly.app/Contents/MacOS/T3 Code (Nightly)" "$out/bin/t3code-nightly"
    '';
  };

  # Since 2026-07 the Codex desktop app ships as "ChatGPT.app" (bundle id
  # still com.openai.codex; the brew `chatgpt` cask is now ChatGPT Classic).
  # Keep installing it as Codex.app so the ~/Applications link name stays
  # stable and does not collide with /Applications/ChatGPT.app.
  codexDesktop = pkgs.stdenv.mkDerivation rec {
    pname = "codex-desktop";
    version = "26.930.31730";
    src = pkgs.fetchurl {
      url = "https://persistent.oaistatic.com/codex-app-prod/ChatGPT-darwin-arm64-${version}.zip";
      sha256 = "sha256-v9pmGnycpE2sMWgTQFjdYAeUfN4xit431XDEhDKfbUE=";
    };
    nativeBuildInputs = [ pkgs.unzip ];
    unpackPhase = "unzip $src";
    installPhase = ''
      mkdir -p "$out/Applications"
      cp -R "ChatGPT.app" "$out/Applications/Codex.app"
      chmod +x "$out/Applications/Codex.app/Contents/MacOS/ChatGPT"
    '';
  };

  cursor-cli = pkgs.cursor-cli.overrideAttrs (_old: rec {
    version = "0-unstable-2026-09-23";
    cursorRelease = "2026.09.23-86fc751";
    src = pkgs.fetchurl {
      url = "https://downloads.cursor.com/lab/${cursorRelease}/darwin/arm64/agent-cli-package.tar.gz";
      hash = "sha256-+j/hPVWJxYb/EyokwW7qlvuO/eiK/e/dzRHYD6GZ86U=";
    };
  });
}
