#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
[ "$#" -eq 0 ] || { echo "Usage: $0" >&2; exit 1; }
[ "$(uname -s)" = Linux ] || { echo "This installer requires Ubuntu. Use install.sh on macOS." >&2; exit 1; }
if [ ! -r /etc/os-release ]; then
  echo "Unsupported Linux distribution (Ubuntu required)." >&2
  exit 1
fi
. /etc/os-release
[ "${ID:-}" = ubuntu ] || { echo "Unsupported Linux distribution: ${ID:-unknown} (Ubuntu required)." >&2; exit 1; }
PLATFORM=ubuntu
export PNPM_HOME="${PNPM_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/pnpm}"

if [ "$(id -u)" -eq 0 ]; then
  APT=(apt-get)
elif command -v sudo &>/dev/null; then
  APT=(sudo apt-get)
else
  echo "Ubuntu package installation requires root or sudo." >&2
  exit 1
fi
"${APT[@]}" update
"${APT[@]}" install -y zsh zsh-autosuggestions git curl vim jq ca-certificates build-essential

source "$DOTFILES/scripts/install-common.sh"
