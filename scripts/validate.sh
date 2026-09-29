#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
portable=0
[[ "${1:-}" == "--portable" ]] && portable=1
verify_file=$(mktemp)
trap 'rm -f "$verify_file"' EXIT

sed -e "s|~/.config/hypr|$repo_root/config/hypr|g" -e 's|source = .*/local.conf$|source = '"$repo_root"'/config/hypr/local.conf.example|' "$repo_root/config/hypr/hyprland.conf" > "$verify_file"

for script in "$repo_root"/bin/* "$repo_root"/scripts/*.sh; do
  [[ -f "$script" ]] || continue
  if head -1 "$script" | grep -q 'bash$'; then
    bash -n "$script"
  fi
done
python3 -m py_compile "$repo_root/bin/rainlight" "$repo_root/bin/after-rain-keybinds" "$repo_root/bin/after-rain-workspace" "$repo_root/bin/after-rain-ibus-candidate-follow" "$repo_root/scripts/"*.py

"$repo_root/scripts/render-theme.py" --check
"$repo_root/scripts/verify-assets.py"
python3 - <<'PY' "$repo_root/themes/after-rain/colors.toml"
import sys, tomllib
with open(sys.argv[1], "rb") as handle:
    tomllib.load(handle)
PY
python3 -m json.tool "$repo_root/config/swaync/config.json" >/dev/null
python3 - <<'PY' "$repo_root/config/waybar/config.jsonc"
import json, re, sys
text = open(sys.argv[1], encoding="utf-8").read()
text = re.sub(r"//.*$", "", text, flags=re.M)
json.loads(text)
PY

if command -v Hyprland >/dev/null 2>&1; then
  Hyprland --config "$verify_file" --verify-config
  Hyprland --config "$repo_root/config/hypr/hyprland.lua" --verify-config
elif (( portable == 0 )); then
  echo "Hyprland is required for full validation." >&2
  exit 1
fi
python3 "$repo_root/scripts/test-keybinds.py"
python3 "$repo_root/scripts/test-input-method.py"
python3 "$repo_root/scripts/test-binding-profiles.py"
python3 "$repo_root/scripts/test-ibus-candidate-follow.py"
python3 "$repo_root/scripts/test-session-start.py"
python3 "$repo_root/scripts/test-quickshell-contract.py"
if command -v ghostty >/dev/null 2>&1; then
  ghostty +validate-config --config-file="$repo_root/config/ghostty/config"
elif (( portable == 0 )); then
  echo "Ghostty is required for full validation." >&2
  exit 1
fi
"$repo_root/scripts/scan-secrets.sh"
echo "Validation passed."
