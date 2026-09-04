{ pkgs }:
{
  codex = pkgs.stdenv.mkDerivation rec {
    pname = "codex";
    version = "0.153.2";
    src = pkgs.fetchurl {
      url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-aarch64-apple-darwin.tar.gz";
      sha256 = "sha256-kd/CcPDfuuwW2BTxqpDU8n503J43hOZABr7zt5/p4Jw=";
    };
    codeModeHostSrc = pkgs.fetchurl {
      url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-code-mode-host-aarch64-apple-darwin.tar.gz";
      sha256 = "sha256-NHHlSmFB+8vpTOyH0UNwNTZn1A81DvFvqgBevBhUMAs=";
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
    version = "1.18.4";
    src = pkgs.fetchurl {
      url = "https://github.com/anomalyco/opencode/releases/download/v${version}/opencode-darwin-arm64.zip";
      sha256 = "sha256-BPuIG2MrMjxxLf2m3LvG/Oc2OU8HunYXblLWZlkl1OY=";
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
    version = "2.1.260";
    src = pkgs.fetchurl {
      url = "https://downloads.claude.ai/claude-code-releases/${version}/darwin-arm64/claude";
      sha256 = "sha256-PCafZoAQKII+JKY87Z/dOYjLhs+F/M2fA/h+RjudPjw=";
    };
    dontUnpack = true;
    installPhase = ''
      mkdir -p "$out/bin"
      install -m755 "$src" "$out/bin/claude"
    '';
  };

  t3code = pkgs.stdenv.mkDerivation rec {
    pname = "t3code";
    version = "0.0.38";
    src = pkgs.fetchurl {
      url = "https://github.com/pingdotgg/t3code/releases/download/v${version}/T3-Code-${version}-arm64.zip";
      sha256 = "sha256-wKde9820O8ubcgiVwSVuG1BRs5jFwX+Jp4xTOE5KQz4=";
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
    version = "0.0.39-nightly.20260904.1277";
    src = pkgs.fetchurl {
      url = "https://github.com/pingdotgg/t3code/releases/download/v${version}/T3-Code-${version}-arm64.zip";
      sha256 = "sha256-2KfBoP+kHq8HzqswyWn6aL4N0vcT7S3Nf61pU+LNWL4=";
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

  codexDesktop = pkgs.stdenv.mkDerivation rec {
    pname = "codex-desktop";
    version = "26.527.31326";
    src = pkgs.fetchurl {
      url = "https://persistent.oaistatic.com/codex-app-prod/Codex-darwin-arm64-${version}.zip";
      sha256 = "sha256-z6oU1qioqN5AMCj5J/a2S6ZpLDyXWer+wP0zdkEkudI=";
    };
    nativeBuildInputs = [ pkgs.unzip ];
    unpackPhase = "unzip $src";
    installPhase = ''
      mkdir -p "$out/Applications"
      cp -R "Codex.app" "$out/Applications/Codex.app"
      chmod +x "$out/Applications/Codex.app/Contents/MacOS/Codex"
    '';
  };
}
