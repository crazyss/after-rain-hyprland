#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
config_root="${XDG_CONFIG_HOME:-$HOME/.config}"
bin_root="$HOME/.local/bin"

"$repo_root/scripts/validate.sh"
backup_root=$("$repo_root/scripts/backup.sh")
echo "Backup: $backup_root"

mkdir -p "$config_root/hypr/conf.d" "$config_root/hypr/wallpapers"
mkdir -p "$config_root/waybar" "$config_root/swaync" "$config_root/ghostty" "$config_root/kitty" "$bin_root"

install -m 0644 "$repo_root/config/hypr/hyprland.conf" "$config_root/hypr/hyprland.conf"
install -m 0644 "$repo_root/config/hypr/hyprpaper.conf" "$config_root/hypr/hyprpaper.conf"
install -m 0644 "$repo_root/config/hypr/hypridle.conf" "$config_root/hypr/hypridle.conf"
install -m 0644 "$repo_root/config/hypr/hyprlock.conf" "$config_root/hypr/hyprlock.conf"
install -m 0644 "$repo_root/config/hypr/conf.d/"*.conf "$config_root/hypr/conf.d/"
[[ -e "$config_root/hypr/local.conf" ]] || install -m 0644 "$repo_root/config/hypr/local.conf.example" "$config_root/hypr/local.conf"

install -m 0644 "$repo_root/assets/wallpapers/"*.png "$config_root/hypr/wallpapers/"
ln -sfn "01-lin-wan-ultrawide.png" "$config_root/hypr/wallpapers/current.png"

install -m 0644 "$repo_root/config/waybar/config.jsonc" "$config_root/waybar/config.jsonc"
install -m 0644 "$repo_root/config/waybar/style.css" "$config_root/waybar/style.css"
install -m 0644 "$repo_root/config/swaync/config.json" "$config_root/swaync/config.json"
install -m 0644 "$repo_root/config/swaync/style.css" "$config_root/swaync/style.css"
install -m 0644 "$repo_root/config/ghostty/config" "$config_root/ghostty/config"
install -m 0644 "$repo_root/config/kitty/after-rain.conf" "$config_root/kitty/after-rain.conf"
if [[ ! -e "$config_root/kitty/kitty.conf" ]]; then
  printf '%s\n' 'include after-rain.conf' > "$config_root/kitty/kitty.conf"
elif ! grep -qF 'include after-rain.conf' "$config_root/kitty/kitty.conf"; then
  printf '\n%s\n' 'include after-rain.conf' >> "$config_root/kitty/kitty.conf"
fi

install -m 0755 "$repo_root/bin/"after-rain-* "$bin_root/"

hyprctl reload >/dev/null 2>&1 || true
pkill -x waybar >/dev/null 2>&1 || true
setsid -f env GDK_BACKEND=wayland waybar >/dev/null 2>&1
swaync-client -R >/dev/null 2>&1 || true
swaync-client -rs >/dev/null 2>&1 || true
pkill -x hyprpaper >/dev/null 2>&1 || true
setsid -f hyprpaper -c "$config_root/hypr/hyprpaper.conf" >/dev/null 2>&1
pgrep -x hypridle >/dev/null 2>&1 || setsid -f hypridle -c "$config_root/hypr/hypridle.conf" >/dev/null 2>&1

echo "After Rain installed. Log out/in once to apply every environment setting."
echo "Rollback: $repo_root/scripts/restore.sh '$backup_root'"
