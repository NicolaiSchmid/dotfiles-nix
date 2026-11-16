# T3 Code appearance: the "June" dark theme, the neutral-grey dark palette T3
# shipped in June 2026 (v0.0.28): #161616 background, #1b1b1b cards, #242424
# borders, #366ffb primary. Newer releases went to near-black (#0a0a0a).
# `messageAction` is what T3 maps to --primary (switches, primary buttons).
#
# T3 keeps published themes in ~/.t3/userdata/themes/<id>.json and the active
# one in settings.json (defaultTheme / defaultAppearance). Both are files the
# app writes, so they are copied on every activation instead of symlinked
# into the read-only store. The JSON here is the source of truth: edits made
# in T3's theme editor last until the next rebuild, so copy them back into
# t3code-themes/ to keep them.
{ pkgs, hostConfig, ... }:
let
  themeId = "june";
  appearance = "dark";
  themeFile = ./t3code-themes + "/${themeId}.json";
  jq = "${pkgs.jq}/bin/jq";
in
{
  home-manager.users.${hostConfig.username} =
    { lib, ... }:
    {
      home.activation.t3codeTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        userdata="$HOME/.t3/userdata"
        run mkdir -p "$userdata/themes"
        run install -m 0644 ${themeFile} "$userdata/themes/${themeId}.json"

        settings="$userdata/settings.json"
        if [ -f "$settings" ]; then
          current="$(${jq} -r '[.defaultTheme, .defaultAppearance] | join("/")' "$settings" 2>/dev/null || true)"
          if [ "$current" != "${themeId}/${appearance}" ]; then
            now="$(date -u +%Y-%m-%dT%H:%M:%S.000Z)"
            tmp="$(mktemp "$userdata/.settings.json.XXXXXX")"
            if ${jq} --arg now "$now" '
                .defaultTheme = "${themeId}" | .defaultThemeSetAt = $now
                | .defaultAppearance = "${appearance}" | .defaultAppearanceSetAt = $now
              ' "$settings" > "$tmp"; then
              chmod 0644 "$tmp"
              run mv "$tmp" "$settings"
            else
              rm -f "$tmp"
              warnEcho "t3code-theme: could not update $settings, leaving it alone"
            fi
          fi
        else
          warnEcho "t3code-theme: $settings not found yet (start T3 Code once), theme file installed only"
        fi
      '';
    };
}
