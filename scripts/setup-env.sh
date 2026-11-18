#!/usr/bin/env bash
# Creates Backend/backend/.env from .env.example with freshly generated secrets.
# Usage (from anywhere; on Windows use Git Bash or scripts/setup-env.ps1):
#   bash scripts/setup-env.sh           # refuses to touch an existing .env
#   bash scripts/setup-env.sh --force   # backs up the existing .env, then recreates it
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
example="$root/Backend/backend/.env.example"
env_file="$root/Backend/backend/.env"

if [[ ! -f "$example" ]]; then
  echo "Cannot find $example" >&2
  exit 1
fi

if [[ -f "$env_file" ]]; then
  if [[ "${1:-}" != "--force" ]]; then
    echo "Backend/backend/.env already exists, left unchanged."
    echo "Run with --force to back it up and create a new one."
    exit 0
  fi
  backup="$env_file.backup-$(date +%Y%m%d-%H%M%S)"
  cp "$env_file" "$backup"
  echo "Backed up the existing .env to ${backup#"$root"/}"
fi

# Base64 of n random bytes on one line (openssl if present, else /dev/urandom).
random_base64() {
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -base64 "$1" | tr -d '\n'
  else
    head -c "$1" /dev/urandom | base64 | tr -d '\n'
  fi
}

jwt_secret="$(random_base64 48)"
token_key="$(random_base64 32)"

# Base64 never contains '|', so it is a safe sed delimiter for the secrets.
# OAuth placeholders become empty so the sign-in buttons stay hidden until real values are filled in.
sed -E -e "s|^JWT_SECRET=.*|JWT_SECRET=$jwt_secret|" \
    -e "s|^GITHUB_TOKEN_KEY=.*|GITHUB_TOKEN_KEY=$token_key|" \
    -e 's#^(GITHUB_CLIENT_ID|GITHUB_CLIENT_SECRET|GOOGLE_CLIENT_ID|GOOGLE_CLIENT_SECRET)=your_.*#\1=#' \
    "$example" > "$env_file"
chmod 600 "$env_file" 2>/dev/null || true

cat <<'EOF'
Created Backend/backend/.env with a new JWT_SECRET and GITHUB_TOKEN_KEY.

Optional, for "Continue with GitHub / Google": fill in GITHUB_CLIENT_ID, GITHUB_CLIENT_SECRET,
GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET in that file (see README), then restart the backend.
The file is gitignored; never commit it.
EOF
