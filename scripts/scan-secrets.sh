#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
failed=0

if find "$repo_root" -path "$repo_root/.git" -prune -o -type f \( -name '.env' -o -name '*.pem' -o -name '*.key' \) -print | grep -q .; then
  echo "Secret-like files found." >&2
  failed=1
fi

patterns=(
  'fc-[a-fA-F0-9]{20,}'
  'gh[pousr]_[A-Za-z0-9_]{20,}'
  'sk-[A-Za-z0-9_-]{20,}'
  'AKIA[0-9A-Z]{16}'
  '-----BEGIN (RSA |OPENSSH |EC )?PRIVATE KEY-----'
)
for pattern in "${patterns[@]}"; do
  if rg -n --hidden --glob '!.git/**' --glob '!scripts/scan-secrets.sh' -- "$pattern" "$repo_root"; then
    failed=1
  fi
done

if (( failed )); then
  echo "Secret scan failed." >&2
  exit 1
fi
echo "Secret scan passed."
