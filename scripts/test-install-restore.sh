#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
test_root=$(mktemp -d)
trap 'rm -rf "$test_root"' EXIT

export XDG_CONFIG_HOME="$test_root/xdg-config"
export XDG_STATE_HOME="$test_root/xdg-state"
export AFTER_RAIN_BIN_ROOT="$test_root/bin"
export AFTER_RAIN_SKIP_RUNTIME=1

mkdir -p "$XDG_CONFIG_HOME/hypr"
printf 'pre-existing\n' > "$XDG_CONFIG_HOME/hypr/original-marker"
mkdir -p "$AFTER_RAIN_BIN_ROOT"
printf '#!/usr/bin/env bash\necho pre-existing-rainlight\n' > "$AFTER_RAIN_BIN_ROOT/rainlight"
chmod 0755 "$AFTER_RAIN_BIN_ROOT/rainlight"

"$repo_root/scripts/install.sh" >/dev/null

grep -qF "$XDG_CONFIG_HOME/hypr/conf.d/05-theme.conf" "$XDG_CONFIG_HOME/hypr/hyprland.conf"
grep -qF 'require("after_rain.bindings")' "$XDG_CONFIG_HOME/hypr/hyprland.lua"
grep -qF "$AFTER_RAIN_BIN_ROOT" "$XDG_CONFIG_HOME/hypr/conf.d/00-programs.conf"
grep -qF "$AFTER_RAIN_BIN_ROOT" "$XDG_CONFIG_HOME/hypr/after_rain/programs.lua"
grep -qF "$AFTER_RAIN_BIN_ROOT/rainlight" "$XDG_CONFIG_HOME/waybar/config.jsonc"
grep -qF "$AFTER_RAIN_BIN_ROOT/after-rain-wallpaper" "$XDG_CONFIG_HOME/waybar/config.jsonc"
unexpanded_config_path=$'\x7e/.config'
if grep -qF "$unexpanded_config_path" "$XDG_CONFIG_HOME/hypr/hyprland.conf"; then
  echo "Install left an unexpanded config path." >&2
  exit 1
fi
if grep -qF '@AFTER_RAIN_BIN_ROOT@' "$XDG_CONFIG_HOME/hypr/after_rain/programs.lua"; then
  echo "Install left an unexpanded Lua bin path." >&2
  exit 1
fi
if command -v Hyprland >/dev/null 2>&1; then
  Hyprland --config "$XDG_CONFIG_HOME/hypr/hyprland.lua" --verify-config >/dev/null
fi
[[ -x "$AFTER_RAIN_BIN_ROOT/after-rain-doctor" ]]
[[ -x "$AFTER_RAIN_BIN_ROOT/after-rain-workspace" ]]
[[ -x "$AFTER_RAIN_BIN_ROOT/after-rain-input-toggle" ]]
[[ -x "$AFTER_RAIN_BIN_ROOT/after-rain-input-status" ]]
[[ -x "$AFTER_RAIN_BIN_ROOT/after-rain-keybinds" ]]
[[ -f "$XDG_CONFIG_HOME/wlogout/style.css" ]]
[[ -f "$XDG_CONFIG_HOME/swayosd/config.toml" ]]
[[ -f "$XDG_CONFIG_HOME/rainlight/style.css" ]]
[[ -f "$XDG_CONFIG_HOME/after-rain-keybinds/style.css" ]]
[[ -x "$AFTER_RAIN_BIN_ROOT/rainlight" ]]

backup_root=$(find "$XDG_STATE_HOME/after-rain-hyprland/backups" -mindepth 1 -maxdepth 1 -type d -print -quit)
"$repo_root/scripts/restore.sh" "$backup_root" >/dev/null

[[ -f "$XDG_CONFIG_HOME/hypr/original-marker" ]]
[[ ! -e "$XDG_CONFIG_HOME/waybar" ]]
[[ ! -e "$AFTER_RAIN_BIN_ROOT/after-rain-doctor" ]]
[[ ! -e "$AFTER_RAIN_BIN_ROOT/after-rain-workspace" ]]
[[ ! -e "$AFTER_RAIN_BIN_ROOT/after-rain-input-toggle" ]]
[[ ! -e "$AFTER_RAIN_BIN_ROOT/after-rain-input-status" ]]
[[ ! -e "$AFTER_RAIN_BIN_ROOT/after-rain-keybinds" ]]
grep -qF 'pre-existing-rainlight' "$AFTER_RAIN_BIN_ROOT/rainlight"
echo "Install/restore integration passed."
