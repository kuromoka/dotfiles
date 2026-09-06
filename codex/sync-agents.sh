#!/usr/bin/env bash
set -euo pipefail

SOURCE_DIR="$(cd "$(dirname "$0")/agents" && pwd)"
CODEX_AGENTS_DIR="${1:-${CODEX_HOME:-$HOME/.codex}/agents}"

mkdir -p "$CODEX_AGENTS_DIR"

backup_path() {
  local dst="$1"
  local backup="${dst}.bak"
  local index=1

  while [ -e "$backup" ] || [ -L "$backup" ]; do
    backup="${dst}.bak.${index}"
    index=$((index + 1))
  done

  printf '%s\n' "$backup"
}

for src in "$SOURCE_DIR"/*.toml; do
  [ -e "$src" ] || continue

  dst="$CODEX_AGENTS_DIR/$(basename "$src")"

  if [ -L "$dst" ]; then
    unlink "$dst"
  elif [ -e "$dst" ] && ! cmp -s "$src" "$dst"; then
    backup="$(backup_path "$dst")"
    cp -p "$dst" "$backup"
    echo "Backed up: $dst -> $backup"
  fi

  install -m 0644 "$src" "$dst"
  echo "Synced: $dst <- $src"
done
