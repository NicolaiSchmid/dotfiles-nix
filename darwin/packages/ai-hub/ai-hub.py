"""ai-hub: point Claude Code + Codex at the prometheus CLIProxyAPI hub, or back.

  ai-hub on       use the hub (https://prometheus.takaya-buri.ts.net)
  ai-hub off      back to this machine's own Claude/Codex login
  ai-hub status   show what the configs point at and whether the hub answers

Only the hub keys are touched; everything else Claude Code and Codex write to
their configs (theme, project trust, ...) is preserved. The access key is read
from ~/.config/prometheus/access-key (0600, never in the nix store) and written
into the 0600 config files, like the CLIs' own logins.
"""

import json
import os
import re
import sys
import urllib.request
from pathlib import Path

import tomlkit

HUB_URL = os.environ.get("AI_HUB_URL", "https://prometheus.takaya-buri.ts.net")
PROVIDER = "prometheus"
HOME = Path.home()
KEY_FILE = HOME / ".config/prometheus/access-key"
CLAUDE_SETTINGS = Path(os.environ.get("CLAUDE_CONFIG_DIR", HOME / ".claude")) / "settings.json"
CODEX_CONFIG = Path(os.environ.get("CODEX_HOME", HOME / ".codex")) / "config.toml"
CLAUDE_KEYS = ("ANTHROPIC_BASE_URL", "ANTHROPIC_AUTH_TOKEN")


def write_private(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_name(path.name + ".ai-hub-tmp")
    fd = os.open(tmp, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(fd, "w") as f:
        f.write(text)
    os.chmod(tmp, 0o600)
    os.replace(tmp, path)


def read_key() -> str:
    try:
        key = KEY_FILE.read_text().strip()
    except FileNotFoundError:
        sys.exit(f"ai-hub: missing {KEY_FILE} (put the prometheus access key there, chmod 600)")
    if not key:
        sys.exit(f"ai-hub: {KEY_FILE} is empty")
    return key


def load_claude() -> dict:
    if CLAUDE_SETTINGS.exists():
        return json.loads(CLAUDE_SETTINGS.read_text() or "{}")
    return {}


def load_codex():
    if CODEX_CONFIG.exists():
        return tomlkit.parse(CODEX_CONFIG.read_text())
    return tomlkit.document()


def claude_set(on: bool, key: str = "") -> bool:
    settings = load_claude()
    env = settings.get("env") or {}
    before = dict(env)
    if on:
        env.update({"ANTHROPIC_BASE_URL": HUB_URL, "ANTHROPIC_AUTH_TOKEN": key})
    else:
        for k in CLAUDE_KEYS:
            env.pop(k, None)
    if env == before and CLAUDE_SETTINGS.exists():
        return False
    if env:
        settings["env"] = env
    else:
        settings.pop("env", None)
    write_private(CLAUDE_SETTINGS, json.dumps(settings, indent=2) + "\n")
    return True


def codex_set(on: bool, key: str = "") -> bool:
    doc = load_codex()
    before = tomlkit.dumps(doc)
    providers = doc.get("model_providers")
    if on:
        table = tomlkit.table()
        table.update({
            "name": PROVIDER,
            "base_url": f"{HUB_URL}/v1",
            "wire_api": "responses",
            "requires_openai_auth": False,
            "supports_websockets": True,
            "experimental_bearer_token": key,
        })
        if providers is None:
            providers = tomlkit.table(is_super_table=True)
            doc["model_providers"] = providers
        providers[PROVIDER] = table
        doc["model_provider"] = PROVIDER
    else:
        if doc.get("model_provider") == PROVIDER:
            del doc["model_provider"]
        if providers is not None and PROVIDER in providers:
            del providers[PROVIDER]
            if not providers:
                del doc["model_providers"]
    # tomlkit leaves blank lines where keys were removed; keep on/off cycles stable
    after = re.sub(r"\n{3,}", "\n\n", tomlkit.dumps(doc)).strip("\n") + "\n"
    if after == before and CODEX_CONFIG.exists():
        return False
    write_private(CODEX_CONFIG, after)
    return True


def hub_alive() -> str:
    try:
        req = urllib.request.Request(f"{HUB_URL}/v1/models",
                                     headers={"Authorization": f"Bearer {read_key()}"})
        with urllib.request.urlopen(req, timeout=5) as r:
            return f"up ({len(json.load(r).get('data', []))} models)"
    except SystemExit:
        return "unknown (no access key)"
    except Exception as e:  # noqa: BLE001 - any failure means "down"
        return f"DOWN ({e})"


def status() -> None:
    env = load_claude().get("env") or {}
    claude = "hub" if env.get("ANTHROPIC_BASE_URL") == HUB_URL else "direct"
    codex = "hub" if load_codex().get("model_provider") == PROVIDER else "direct"
    print(f"claude: {claude}\ncodex:  {codex}\nhub:    {HUB_URL} {hub_alive()}")


def main() -> None:
    cmd = sys.argv[1] if len(sys.argv) > 1 else "status"
    if cmd == "on":
        key = read_key()
        changed = [n for n, c in (("claude", claude_set(True, key)), ("codex", codex_set(True, key))) if c]
    elif cmd == "off":
        changed = [n for n, c in (("claude", claude_set(False)), ("codex", codex_set(False))) if c]
    elif cmd == "status":
        return status()
    else:
        sys.exit(__doc__)
    print(f"ai-hub {cmd}: " + (", ".join(changed) + " updated" if changed else "already set"))
    if changed:
        print("restart running claude/codex sessions to pick it up")


if __name__ == "__main__":
    main()
