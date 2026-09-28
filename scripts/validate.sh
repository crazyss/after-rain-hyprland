#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
verify_file=$(mktemp)
trap 'rm -f "$verify_file"' EXIT

sed -e "s|~/.config/hypr|$repo_root/config/hypr|g" -e 's|source = .*/local.conf$|source = '"$repo_root"'/config/hypr/local.conf.example|' "$repo_root/config/hypr/hyprland.conf" > "$verify_file"

for script in "$repo_root"/bin/* "$repo_root"/scripts/*.sh; do
  bash -n "$script"
done

python3 -m json.tool "$repo_root/config/swaync/config.json" >/dev/null
python3 - <<'PY' "$repo_root/config/waybar/config.jsonc"
import json, re, sys
text = open(sys.argv[1], encoding="utf-8").read()
text = re.sub(r"//.*$", "", text, flags=re.M)
json.loads(text)
PY

Hyprland --config "$verify_file" --verify-config
ghostty +validate-config --config-file="$repo_root/config/ghostty/config"
"$repo_root/scripts/scan-secrets.sh"
echo "Validation passed."
