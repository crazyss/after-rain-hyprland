#!/usr/bin/env bash
set -euo pipefail

state_root="${XDG_STATE_HOME:-$HOME/.local/state}/after-rain-hyprland"
stamp=$(date -u +%Y%m%dT%H%M%SZ)
backup_root="${1:-$state_root/backups/$stamp}"
config_root="${XDG_CONFIG_HOME:-$HOME/.config}"

mkdir -p "$backup_root"
for name in hypr waybar swaync ghostty kitty; do
  [[ -e "$config_root/$name" ]] && cp -a "$config_root/$name" "$backup_root/$name"
done
printf '%s\n' "$backup_root"
