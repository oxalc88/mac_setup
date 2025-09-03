#!/usr/bin/env bash
set -euo pipefail

# ==== guard macOS ====
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This script is for macOS only."; exit 0
fi

# ==== helpers ====
REPO_USER="oxalc88"
REPO_NAME="mac_setup"
REPO_BRANCH="main"
RAW_BASE="https://raw.githubusercontent.com/${REPO_USER}/${REPO_NAME}/${REPO_BRANCH}"

run_local_or_remote() {
  # Usage: run_local_or_remote path/inside/repo.sh [args...]
  local rel="$1"; shift || true
  if [[ -f "$rel" ]]; then
    bash "$rel" "$@"
  else
    curl -fsSL "${RAW_BASE}/${rel}" | bash -s -- "$@"
  fi
}

echo "▶ Ensuring Homebrew…"
if ! command -v brew >/dev/null 2>&1; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Put brew in PATH now and for future shells (zsh is default on macOS)
BREW_PREFIX="$([ -d /opt/homebrew ] && echo /opt/homebrew || echo /usr/local)"
eval "$("$BREW_PREFIX/bin/brew" shellenv)"
ZRC="${ZDOTDIR:-$HOME}/.zprofile"
grep -q 'brew shellenv' "$ZRC" 2>/dev/null || echo "eval \"($BREW_PREFIX/bin/brew shellenv)\"" >> "$ZRC"

echo "▶ Installing Git (avoid Xcode CLT popup)…"
brew list git >/dev/null 2>&1 || brew install git

echo "▶ Installing AWS CLI v2…"
run_local_or_remote "programs/install_aws_cli.sh"

echo "▶ Installing packages from Brewfile…"
BREWFILE_URL="${RAW_BASE}/programs/Brewfile"
curl -fsSL "$BREWFILE_URL" | brew bundle --no-lock --file=-

echo "✓ All done."
