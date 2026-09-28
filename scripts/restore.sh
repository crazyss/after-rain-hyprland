#!/usr/bin/env bash
set -euo pipefail
umask 077

if [[ $# -ne 1 || ! -d "$1" || ! -f "$1/manifest.tsv" ]]; then
  echo "Usage: scripts/restore.sh BACKUP_DIRECTORY" >&2
  echo "The backup must contain manifest.tsv." >&2
  exit 2
fi

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
backup_root=$(realpath "$1")
config_root="${XDG_CONFIG_HOME:-$HOME/.config}"
bin_root="${AFTER_RAIN_BIN_ROOT:-$HOME/.local/bin}"
if [[ "$config_root" == / || "$bin_root" == / ]]; then
  echo "Refusing to restore into filesystem root." >&2
  exit 3
fi
safety_root=$("$repo_root/scripts/backup.sh")

while IFS=$'\t' read -r kind name status; do
  case "$kind:$name" in
    config:hypr|config:waybar|config:swaync|config:swayosd|config:ghostty|config:kitty|config:wlogout|config:btop|config:gtk-3.0|config:gtk-4.0|config:rainlight) ;;
    bin:after-rain-menu|bin:after-rain-cheatsheet|bin:after-rain-doctor|bin:after-rain-input-status|bin:after-rain-input-toggle|bin:after-rain-reload|bin:after-rain-wallpaper|bin:after-rain-workspace|bin:rainlight) ;;
    *) echo "Unsafe manifest target: $kind $name" >&2; exit 3 ;;
  esac
  case "$kind:$status" in
    config:present)
      rm -rf "${config_root:?}/$name"
      cp -a "$backup_root/$name" "$config_root/$name"
      ;;
    config:absent)
      rm -rf "${config_root:?}/$name"
      ;;
    bin:present)
      install -m 0755 "$backup_root/bin/$name" "$bin_root/$name"
      ;;
    bin:absent)
      rm -f "$bin_root/$name"
      ;;
    *)
      echo "Invalid manifest entry: $kind $name $status" >&2
      exit 3
      ;;
  esac
done < "$backup_root/manifest.tsv"

echo "Restored from: $backup_root"
echo "Pre-restore safety copy: $safety_root"
if [[ "${AFTER_RAIN_SKIP_RUNTIME:-0}" != 1 ]]; then
  hyprctl reload >/dev/null 2>&1 || true
  "$repo_root/bin/after-rain-reload" --best-effort >/dev/null 2>&1 || true
fi
