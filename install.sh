#!/usr/bin/env bash
set -euo pipefail

# ===== macOS guard =====
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This script is for macOS only."; exit 0
fi

# ===== repo coordinates (edit these to your repo) =====
REPO_USER="oxalc88"         # <-- change if needed
REPO_NAME="mac_setup"       # <-- change if needed
REPO_BRANCH="main"
RAW_BASE="https://raw.githubusercontent.com/${REPO_USER}/${REPO_NAME}/${REPO_BRANCH}"

# ===== Progress tracking =====
STATE_FILE="$HOME/.mac_setup_progress"

# ===== Cleanup and signal handling =====
cleanup() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        echo "🛑 Installation interrupted or failed. Cleaning up..."
        rm -f /tmp/AWSCLIV2.pkg 2>/dev/null || true
        pkill -f "brew bundle" 2>/dev/null || true
        echo "💡 Run the script again to resume installation"
    fi
    exit $exit_code
}

trap cleanup INT TERM EXIT

# ===== Progress tracking functions =====
mark_complete() {
    echo "$1" >> "$STATE_FILE"
}

is_complete() {
    [[ -f "$STATE_FILE" ]] && grep -q "^$1$" "$STATE_FILE" 2>/dev/null
}

# ===== Resume capability =====
if [[ -f "$STATE_FILE" ]]; then
    echo "🔄 Previous installation detected."
    read -p "Resume from where you left off? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        rm -f "$STATE_FILE"
        echo "Starting fresh installation..."
    fi
fi

# ===== Sudo pre-authorization =====
check_sudo_needs() {
    local needs_sudo=false
    
    if [[ -f "programs/install_aws.sh" ]] && ! command -v aws >/dev/null 2>&1; then
        needs_sudo=true
    elif [[ ! -d "programs" ]]; then
        if curl --head --silent --fail "${RAW_BASE}/programs/install_aws.sh" >/dev/null 2>&1; then
            needs_sudo=true
        fi
    fi
    
    if [[ "$needs_sudo" = true ]]; then
        echo "⚠️  Some installers require administrator privileges."
        echo "   You may be prompted for your password."
        sudo -v
        while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
    fi
}

# ===== Network retry logic =====
retry_curl() {
    local url="$1"
    local output_flag="$2"
    local attempts=3
    
    for i in $(seq 1 $attempts); do
        if curl -fsSL "$url" $output_flag; then
            return 0
        else
            echo "⚠️  Download attempt $i/$attempts failed, retrying..."
            sleep 2
        fi
    done
    
    echo "❌ Failed to download after $attempts attempts: $url"
    return 1
}

# ===== helper: run local if present, else fetch raw and run =====
run_local_or_remote() {
  local rel="$1"; shift || true
  if [[ -f "$rel" ]]; then
    bash "$rel" "$@"
  else
    retry_curl "${RAW_BASE}/${rel}" "| bash -s -- $*"
  fi
}

# ===== Safe installer wrapper =====
run_installer_safely() {
    local script="$1"
    local name="${script##*/}"
    
    if is_complete "$name"; then
        echo "✓ $name already completed"
        return 0
    fi
    
    echo "▶ Running $name..."
    if bash "$script"; then
        mark_complete "$name"
        echo "✓ $name completed"
    else
        echo "⚠️  $name failed - you can re-run this script to retry"
        return 1
    fi
}

# Check sudo requirements upfront
check_sudo_needs

echo "▶ Ensuring Homebrew…"
if ! is_complete "homebrew" && ! command -v brew >/dev/null 2>&1; then
  if retry_curl "https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh" "| /bin/bash"; then
    mark_complete "homebrew"
  else
    echo "❌ Failed to install Homebrew"
    exit 1
  fi
elif command -v brew >/dev/null 2>&1; then
  mark_complete "homebrew" 2>/dev/null || true
fi

# Put brew in PATH now and persist for future shells
BREW_PREFIX="$([ -d /opt/homebrew ] && echo /opt/homebrew || echo /usr/local)"
eval "$("$BREW_PREFIX/bin/brew" shellenv)"
ZRC="${ZDOTDIR:-$HOME}/.zprofile"
grep -q 'brew shellenv' "$ZRC" 2>/dev/null || echo "eval \"($BREW_PREFIX/bin/brew shellenv)\"" >> "$ZRC"

echo "▶ Installing Git (avoid Xcode CLT popup)…"
if ! is_complete "git"; then
  if brew list git >/dev/null 2>&1 || brew install git; then
    mark_complete "git"
  fi
fi

# ===== Brewfile FIRST =====
echo "▶ Installing packages from Brewfile…"
if ! is_complete "brewfile"; then
  if [[ -f "programs/Brewfile" ]]; then
    if brew bundle --no-lock --file="programs/Brewfile"; then
      mark_complete "brewfile"
    fi
  else
    BREWFILE_URL="${RAW_BASE}/programs/Brewfile"
    if retry_curl "$BREWFILE_URL" "| brew bundle --no-lock --file=-"; then
      mark_complete "brewfile"
    fi
  fi
fi

# ===== Then run ALL program installers =====
echo "▶ Running program installers…"

ran_any=false
if [[ -d "programs" ]]; then
  mapfile -t LOCAL_INSTALLERS < <(find "programs" -maxdepth 1 -type f -name 'install_*.sh' | sort)
  if ((${#LOCAL_INSTALLERS[@]})); then
    for script in "${LOCAL_INSTALLERS[@]}"; do
      echo "• ${script}"
      run_installer_safely "$script"
      ran_any=true
    done
  fi
fi

# Remote fallback via manifest when running from one-liner (or if no local installers found)
if [[ "$ran_any" = false ]]; then
  MANIFEST_URL="${RAW_BASE}/programs/manifest.txt"
  if curl --head --silent --fail "$MANIFEST_URL" >/dev/null; then
    echo "▶ Using manifest: $MANIFEST_URL"
    while IFS= read -r line; do
      [[ -z "${line// }" || "$line" =~ ^[[:space:]]*# ]] && continue
      script="programs/${line}"
      script_name="${script##*/}"
      if ! is_complete "$script_name"; then
        echo "• ${script}"
        if run_local_or_remote "$script"; then
          mark_complete "$script_name"
        fi
      else
        echo "✓ ${script} already completed"
      fi
    done < <(curl -fsSL "$MANIFEST_URL")
  else
    echo "  (no installers found locally and no remote manifest at $MANIFEST_URL)"
  fi
fi

# Final cleanup - remove state file on successful completion
if [[ -f "$STATE_FILE" ]]; then
  rm -f "$STATE_FILE"
  echo "🧹 Cleaned up progress tracking"
fi

echo "✅ All installations completed successfully!"
