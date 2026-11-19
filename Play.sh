#!/usr/bin/env bash
set -euo pipefail

project_dir="$(dirname -- "$(realpath -- "$0")")"
engine="${GODOT_BIN:-$HOME/.local/share/garden-godot/Godot_v4.4.1-stable_linux.x86_64}"

if [[ ! -x "$engine" ]]; then
  printf 'Godot 4.4.1 was not found at %s. Set GODOT_BIN to its executable.\n' "$engine" >&2
  exit 1
fi

if [[ ! -d "$project_dir/.godot/imported" ]]; then
  "$engine" --headless --editor --path "$project_dir" --import --quit
fi

exec "$engine" --path "$project_dir" --resolution 1080x488
