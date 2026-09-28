#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
config_root="${XDG_CONFIG_HOME:-$HOME/.config}"
bin_root="${AFTER_RAIN_BIN_ROOT:-$HOME/.local/bin}"
skip_runtime="${AFTER_RAIN_SKIP_RUNTIME:-0}"

if [[ "$skip_runtime" == 1 ]]; then
  "$repo_root/scripts/validate.sh" --portable
else
  "$repo_root/scripts/validate.sh"
fi
backup_root=$("$repo_root/scripts/backup.sh")
echo "Backup: $backup_root"

complete=0
rollback_on_failure() {
  status=$?
  if (( complete == 0 )); then
    echo "Installation failed; restoring $backup_root" >&2
    "$repo_root/scripts/restore.sh" "$backup_root" >/dev/null 2>&1 || true
  fi
  exit "$status"
}
trap rollback_on_failure ERR INT TERM

for name in hypr/conf.d hypr/wallpapers waybar swaync swayosd ghostty kitty wlogout btop/themes gtk-3.0 gtk-4.0 rainlight; do
  mkdir -p "$config_root/$name"
done
mkdir -p "$bin_root"

install_template() {
  source_file=$1
  target_file=$2
  temporary=$(mktemp)
  sed -e "s|~/.config|$config_root|g" \
    -e "s|@AFTER_RAIN_BIN_ROOT@|$bin_root|g" "$source_file" > "$temporary"
  install -m 0644 "$temporary" "$target_file"
  rm -f "$temporary"
}

install_template "$repo_root/config/hypr/hyprland.conf" "$config_root/hypr/hyprland.conf"
install_template "$repo_root/config/hypr/hyprpaper.conf" "$config_root/hypr/hyprpaper.conf"
install_template "$repo_root/config/hypr/hyprlock.conf" "$config_root/hypr/hyprlock.conf"
install -m 0644 "$repo_root/config/hypr/hypridle.conf" "$config_root/hypr/hypridle.conf"
install -m 0644 "$repo_root/config/hypr/hyprtoolkit.conf" "$config_root/hypr/hyprtoolkit.conf"
for source_file in "$repo_root/config/hypr/conf.d/"*.conf; do
  install_template "$source_file" "$config_root/hypr/conf.d/$(basename "$source_file")"
done
[[ -e "$config_root/hypr/local.conf" ]] ||
  install -m 0644 "$repo_root/config/hypr/local.conf.example" "$config_root/hypr/local.conf"

install -m 0644 "$repo_root/assets/wallpapers/"*.png "$config_root/hypr/wallpapers/"
ln -sfn "01-lin-wan-ultrawide.png" "$config_root/hypr/wallpapers/current.png"

install_template "$repo_root/config/waybar/config.jsonc" "$config_root/waybar/config.jsonc"
install -m 0644 "$repo_root/config/waybar/"{style.css,colors.css} "$config_root/waybar/"
install -m 0644 "$repo_root/config/swaync/"{config.json,style.css,colors.css} "$config_root/swaync/"
install -m 0644 "$repo_root/config/wlogout/"{layout,style.css,colors.css} "$config_root/wlogout/"
install -m 0644 "$repo_root/config/ghostty/config" "$config_root/ghostty/config"
install -m 0644 "$repo_root/config/kitty/after-rain.conf" "$config_root/kitty/after-rain.conf"
install -m 0644 "$repo_root/config/btop/themes/after-rain.theme" "$config_root/btop/themes/after-rain.theme"
install -m 0644 "$repo_root/config/gtk-3.0/gtk.css" "$config_root/gtk-3.0/gtk.css"
install -m 0644 "$repo_root/config/gtk-4.0/gtk.css" "$config_root/gtk-4.0/gtk.css"
install -m 0644 "$repo_root/config/swayosd/"{style.css,colors.css} "$config_root/swayosd/"
install -m 0644 "$repo_root/config/rainlight/"{style.css,colors.css} "$config_root/rainlight/"
sed "s|@STYLE@|$config_root/swayosd/style.css|g" "$repo_root/config/swayosd/config.toml" > "$config_root/swayosd/config.toml"
chmod 0644 "$config_root/swayosd/config.toml"

if [[ ! -e "$config_root/kitty/kitty.conf" ]]; then
  printf '%s\n' 'include after-rain.conf' > "$config_root/kitty/kitty.conf"
elif ! grep -qF 'include after-rain.conf' "$config_root/kitty/kitty.conf"; then
  printf '\n%s\n' 'include after-rain.conf' >> "$config_root/kitty/kitty.conf"
fi

if command -v btop >/dev/null 2>&1; then
  [[ -e "$config_root/btop/btop.conf" ]] || btop --default-config > "$config_root/btop/btop.conf"
  if grep -q '^color_theme' "$config_root/btop/btop.conf"; then
    sed -i 's/^color_theme.*/color_theme = "after-rain"/' "$config_root/btop/btop.conf"
  else
    printf '\ncolor_theme = "after-rain"\n' >> "$config_root/btop/btop.conf"
  fi
fi

install -m 0755 "$repo_root/bin/"after-rain-* "$bin_root/"
install -m 0755 "$repo_root/bin/rainlight" "$bin_root/rainlight"

if [[ "$skip_runtime" != 1 ]]; then
  "$bin_root/after-rain-reload"
  "$bin_root/after-rain-doctor"
fi

complete=1
trap - ERR INT TERM
echo "After Rain installed. Log out/in once to apply every environment setting."
echo "Rollback: $repo_root/scripts/restore.sh '$backup_root'"
