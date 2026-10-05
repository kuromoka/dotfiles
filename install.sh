#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
[ "$#" -eq 0 ] || { echo "Usage: $0" >&2; exit 1; }
[ "$(uname -s)" = Darwin ] || { echo "This installer requires macOS. Use install-ubuntu.sh on Ubuntu." >&2; exit 1; }
PLATFORM=macos
export PNPM_HOME="${PNPM_HOME:-$HOME/Library/pnpm}"

# Prefer the user's PATH, then detect existing Apple Silicon / Intel installs.
if ! command -v brew &>/dev/null; then
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi
if ! command -v brew &>/dev/null; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi
eval "$(brew shellenv)"
if ! brew list zsh-autosuggestions &>/dev/null; then
  brew install zsh-autosuggestions
fi

source "$DOTFILES/scripts/install-common.sh"
