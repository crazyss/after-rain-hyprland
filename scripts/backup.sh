#!/usr/bin/env bash
set -euo pipefail
umask 077

state_root="${XDG_STATE_HOME:-$HOME/.local/state}/after-rain-hyprland"
config_root="${XDG_CONFIG_HOME:-$HOME/.config}"
bin_root="${AFTER_RAIN_BIN_ROOT:-$HOME/.local/bin}"
names=(
  hypr waybar swaync swayosd ghostty kitty wlogout btop gtk-3.0 gtk-4.0
  rainlight after-rain-keybinds quickshell/after-rain
  systemd/user/after-rain-shell.service
  systemd/user/waybar.service.d/after-rain-session.conf
  systemd/user/swaync.service.d/after-rain-session.conf
  systemd/user/swayosd.service.d/after-rain-session.conf
  systemd/user/hypridle.service.d/after-rain-session.conf
  systemd/user/hyprpaper.service.d/after-rain-session.conf
  systemd/user/hyprpolkitagent.service.d/after-rain-session.conf
)

mkdir -p "$state_root/backups"
chmod 0700 "$state_root" "$state_root/backups"
if [[ $# -eq 1 ]]; then
  backup_root=$1
  if [[ -e "$backup_root" ]]; then
    echo "Refusing to reuse backup path: $backup_root" >&2
    exit 2
  fi
  mkdir -m 0700 "$backup_root"
else
  stamp=$(date -u +%Y%m%dT%H%M%S)
  backup_root=$(mktemp -d "$state_root/backups/$stamp-XXXXXX")
fi

: > "$backup_root/manifest.tsv"
for name in "${names[@]}"; do
  if [[ -e "$config_root/$name" ]]; then
    printf 'config\t%s\tpresent\n' "$name" >> "$backup_root/manifest.tsv"
    mkdir -p "$(dirname -- "$backup_root/$name")"
    cp -a "$config_root/$name" "$backup_root/$name"
  else
    printf 'config\t%s\tabsent\n' "$name" >> "$backup_root/manifest.tsv"
  fi
done

mkdir -m 0700 "$backup_root/bin"
for path in "$bin_root"/after-rain-* "$bin_root/rainlight"; do
  [[ -e "$path" ]] || continue
  name=$(basename "$path")
  printf 'bin\t%s\tpresent\n' "$name" >> "$backup_root/manifest.tsv"
  cp -a "$path" "$backup_root/bin/$name"
done
for name in after-rain-menu after-rain-cheatsheet after-rain-keybinds after-rain-doctor after-rain-ibus-candidate-follow after-rain-ibus-wayland after-rain-input-status after-rain-input-toggle after-rain-reload after-rain-session-isolate after-rain-session-start after-rain-shell after-rain-terminal after-rain-wallpaper after-rain-workspace rainlight; do
  grep -qF $'bin\t'"$name"$'\tpresent' "$backup_root/manifest.tsv" ||
    printf 'bin\t%s\tabsent\n' "$name" >> "$backup_root/manifest.tsv"
done

if [[ "${AFTER_RAIN_SKIP_RUNTIME:-0}" != 1 ]]; then
  for unit in waybar.service swaync.service swayosd.service hypridle.service hyprpaper.service hyprpolkitagent.service; do
    unit_state=$(systemctl --user is-enabled "$unit" 2>/dev/null || true)
    case "$unit_state" in
      enabled|disabled|masked|static|indirect|generated|not-found) ;;
      *) unit_state=unknown ;;
    esac
    printf 'unit\t%s\t%s\n' "$unit" "$unit_state" >> "$backup_root/manifest.tsv"
  done
fi

chmod -R go-rwx "$backup_root"
printf '%s\n' "$backup_root"
