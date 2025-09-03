#!/usr/bin/env bash
set -euo pipefail

# Install AWS CLI v2 (pkg method) if not present or if user passes --force
FORCE="${1:-}"
if command -v aws >/dev/null 2>&1 && [[ "$FORCE" != "--force" ]]; then
  echo "AWS CLI already installed ($(aws --version 2>/dev/null || true)). Use '--force' to reinstall."
  exit 0
fi

PKG="/tmp/AWSCLIV2.pkg"
echo "• Downloading AWS CLI v2 pkg…"
curl -fsSL "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "$PKG"

echo "• Installing AWS CLI v2… (sudo required)"
sudo installer -pkg "$PKG" -target /

rm -f "$PKG"
echo "✓ AWS CLI installed: $(aws --version 2>/dev/null || true)"
