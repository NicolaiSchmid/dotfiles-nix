{ pkgs }:
{
  codex = pkgs.stdenv.mkDerivation rec {
    pname = "codex";
    version = "0.156.1";
    src = pkgs.fetchurl {
      url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-aarch64-apple-darwin.tar.gz";
      sha256 = "sha256-K9ZK8U3t1HeV8va/1dElz3kZmswse6IiFE4IEnERpco=";
    };
    codeModeHostSrc = pkgs.fetchurl {
      url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-code-mode-host-aarch64-apple-darwin.tar.gz";
      sha256 = "sha256-JiXQI+K24D0rzEN6Pg4IMcJdPHItKFRjio50kh/3m9k=";
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
    version = "2.1.281";
    src = pkgs.fetchurl {
      url = "https://downloads.claude.ai/claude-code-releases/${version}/darwin-arm64/claude";
      sha256 = "sha256-qSKYH287VaJR75+duqBiGl+Zy8tcpn+KeXR2zPyD9iY=";
    };
    dontUnpack = true;
    installPhase = ''
      mkdir -p "$out/bin"
      install -m755 "$src" "$out/bin/claude"
    '';
  };

  t3code = pkgs.stdenv.mkDerivation rec {
    pname = "t3code";
    version = "0.0.42";
    src = pkgs.fetchurl {
      url = "https://github.com/pingdotgg/t3code/releases/download/v${version}/T3-Code-${version}-arm64.zip";
      sha256 = "sha256-BmOznpeQ8Hayp0uUReEXziu26CTQYZxXjoCLS6crRjc=";
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
    version = "0.0.43-nightly.20260923.2150";
    src = pkgs.fetchurl {
      url = "https://github.com/pingdotgg/t3code/releases/download/v${version}/T3-Code-${version}-arm64.zip";
      sha256 = "sha256-vTs9DHvSB3pssi96qk/uWMf1PK7V6nnv6KrNvXNkEUk=";
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

  cursor-cli = pkgs.cursor-cli.overrideAttrs (_old: rec {
    version = "0-unstable-2026-09-23";
    cursorRelease = "2026.09.23-86fc751";
    src = pkgs.fetchurl {
      url = "https://downloads.cursor.com/lab/${cursorRelease}/darwin/arm64/agent-cli-package.tar.gz";
      hash = "sha256-+j/hPVWJxYb/EyokwW7qlvuO/eiK/e/dzRHYD6GZ86U=";
    };
  });
}
