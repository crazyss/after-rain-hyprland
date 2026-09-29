#!/usr/bin/env bash
# Install a user-level launcher override, preserving the packaged desktop metadata.
set -euo pipefail
source_file=/usr/share/applications/chatgpt.desktop
data_root=${XDG_DATA_HOME:-$HOME/.local/share}
state_root=${XDG_STATE_HOME:-$HOME/.local/state}/after-rain-hyprland
target=$data_root/applications/chatgpt.desktop
[[ -f "$source_file" ]] || { echo "ChatGPT desktop entry is not installed." >&2; exit 1; }
mkdir -p "$data_root/applications" "$state_root/backups"
backup=$(mktemp -d "$state_root/backups/chatgpt-wayland-XXXXXX")
if [[ -e "$target" ]]; then
  cp -a "$target" "$backup/chatgpt.desktop"
else
  touch "$backup/previously-absent"
fi
temporary=$(mktemp --suffix=.desktop)
trap 'rm -f "$temporary"' EXIT
sed 's|^Exec=chatgpt %U$|Exec=/usr/bin/env -u GTK_IM_MODULE GDK_BACKEND=wayland /usr/bin/chatgpt --ozone-platform=wayland --enable-wayland-ime %U|' "$source_file" > "$temporary"
grep -q '^Exec=.*--ozone-platform=wayland' "$temporary"
if command -v desktop-file-validate >/dev/null; then
  desktop-file-validate "$temporary"
fi
install -m 0644 "$temporary" "$target"
if command -v update-desktop-database >/dev/null; then
  update-desktop-database "$data_root/applications"
fi
printf 'Installed: %s\nBackup: %s\nFully quit ChatGPT, then reopen it from the application launcher.\n' "$target" "$backup"
