#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 || ! -d "$1" ]]; then
  echo "Usage: scripts/restore.sh BACKUP_DIRECTORY" >&2
  exit 2
fi

backup_root=$(realpath "$1")
config_root="${XDG_CONFIG_HOME:-$HOME/.config}"
stamp=$(date -u +%Y%m%dT%H%M%SZ)
safety_root="${XDG_STATE_HOME:-$HOME/.local/state}/after-rain-hyprland/pre-restore/$stamp"

mkdir -p "$safety_root"
for name in hypr waybar swaync ghostty kitty; do
  [[ -e "$config_root/$name" ]] && cp -a "$config_root/$name" "$safety_root/$name"
  if [[ -e "$backup_root/$name" ]]; then
    rm -rf "$config_root/$name"
    cp -a "$backup_root/$name" "$config_root/$name"
  fi
done

echo "Restored from: $backup_root"
echo "Pre-restore safety copy: $safety_root"
hyprctl reload >/dev/null 2>&1 || true
