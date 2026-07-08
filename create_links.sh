#!/bin/zsh

set -euo pipefail

repo_root="$(cd "$(dirname "$0")" && pwd)"
source_dir="$repo_root/darwin"
target="/etc/nix-darwin"

if [ -e "$target" ] && [ ! -L "$target" ]; then
  echo "$target exists and is not a symlink; move it aside manually first." >&2
  exit 1
fi

rm -f "$target"
ln -s "$source_dir" "$target"
echo "Linked $target -> $source_dir"
