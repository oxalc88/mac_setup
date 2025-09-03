#!/usr/bin/env bash
set -euo pipefail

# Install Claude CLI (Anthropic)
FORCE="${1:-}"
if command -v claude >/dev/null 2>&1 && [[ "$FORCE" != "--force" ]]; then
  echo "Claude CLI already installed ($(claude --version 2>/dev/null || true)). Use '--force' to reinstall."
  exit 0
fi

echo "• Installing Claude CLI…"
curl -fsSL https://claude.ai/install.sh | bash

echo "✓ Claude CLI installed: $(claude --version 2>/dev/null || true)"
