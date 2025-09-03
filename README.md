# macOS Development Setup

Automated setup script to install essential development tools, CLI utilities, and applications on macOS.

## What Gets Installed

### CLI Tools & Development
- Git, Neovim, Zellij (terminal multiplexer)
- Modern CLI replacements: `fzf`, `ripgrep`, `fd`, `eza`, `bat`, `btop`
- Development tools: `jq`, `mise`, `lazygit`, `lazydocker`, `awscli`
- AI tools: `ollama`, `gemini-cli`, Claude CLI

### Applications
- **Productivity**: 1Password, Raycast, Obsidian, Typora
- **Development**: Visual Studio Code, OrbStack (Docker alternative)
- **Communication**: WhatsApp, Zoom, Microsoft Teams, ChatGPT, Claude
- **Browsers**: Brave Browser
- **Gaming**: Steam, Heroic (Epic Games)
- **Utilities**: LocalSend, PearCleaner

### Terminal & Fonts
- Alacritty terminal
- Nerd Fonts: Hack, Cascadia Code, Fira Code, IBM Plex, Geist Mono

## Quick Start

### One-Line Install (Recommended)
```bash
curl -fsSL https://raw.githubusercontent.com/oxalc88/mac_setup/main/install.sh | bash
```

### Manual Install
```bash
# Clone the repository
git clone https://github.com/oxalc88/mac_setup.git
cd mac_setup

# Run the installer
./install.sh
```

## What Happens During Installation

1. **Progress Tracking** - Creates progress file to enable resume on interruption
2. **Sudo Pre-authorization** - Requests admin privileges upfront for smooth installation
3. **Homebrew Setup** - Installs Homebrew if not present and configures PATH
4. **Git Installation** - Installs Git via Homebrew to avoid Xcode Command Line Tools popup
5. **Package Installation** - Installs all packages from the Brewfile with progress tracking
6. **Custom Installers** - Runs additional setup scripts for AWS CLI and Claude CLI
7. **Cleanup** - Removes progress tracking on successful completion

### Resume Capability
If interrupted (Ctrl+C, network issues, etc.), simply re-run the script:
- **Automatic detection** - Script detects previous incomplete installation
- **Resume option** - Choose to continue from where you left off
- **Skip completed** - Only runs installers that haven't completed successfully

## Customization

### Adding Your Own Programs

1. **For Homebrew packages**: Edit `programs/Brewfile`
2. **For custom installers**: Create `programs/install_YOURPROGRAM.sh`

Example custom installer:
```bash
#!/usr/bin/env bash
set -euo pipefail

# Check if already installed
if command -v yourprogram >/dev/null 2>&1; then
  echo "Your Program already installed. Use '--force' to reinstall."
  exit 0
fi

echo "• Installing Your Program..."
# Installation commands here

echo "✓ Your Program installed"
```

### Using with Your Own Repository

1. Fork this repository
2. Edit the repo coordinates in `install.sh` (lines 10-12):
   ```bash
   REPO_USER="yourusername"
   REPO_NAME="your_repo_name" 
   REPO_BRANCH="main"
   ```
3. Customize `programs/Brewfile` and add your own installers
4. Update `programs/manifest.txt` with your installer script names

## Requirements

- macOS (script includes macOS detection)
- Internet connection for downloading packages
- Administrator privileges (for some installations)

## Troubleshooting

### Common Issues
- **Interruption/Network failures**: Re-run script to resume from interruption point
- **Permission errors**: Script requests sudo upfront, but may prompt again if session expires
- **Failed downloads**: Built-in retry logic (3 attempts) handles temporary network issues
- **Homebrew conflicts**: Script detects existing Homebrew and skips installation
- **Partial installations**: Progress tracking ensures only failed components are retried

### Recovery Options
```bash
# Start fresh (ignores previous progress)
rm ~/.mac_setup_progress
./install.sh

# Check what's already installed
ls -la ~/.mac_setup_progress 2>/dev/null && cat ~/.mac_setup_progress

# Run individual installers manually
bash programs/install_aws.sh --force
```

## Manual Component Installation

Run individual components if needed:
```bash
# Install only Homebrew packages
brew bundle --file=programs/Brewfile

# Run specific installer
bash programs/install_aws.sh

# Force reinstall
bash programs/install_claude.sh --force
```