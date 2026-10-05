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
  elif [ -f "$dst" ] && cmp -s "$src" "$dst"; then
    continue
  elif [ -e "$dst" ]; then
    backup="$(backup_path "$dst")"
    cp -p "$dst" "$backup"
    cmp -s "$dst" "$backup" || { echo "Agent backup differs: $backup" >&2; exit 1; }
    echo "Backed up: $dst -> $backup"
  fi

  install -m 0644 "$src" "$dst"
  echo "Synced: $dst <- $src"
done

# Also verify no-op profiles; a symlink is never a valid installed agent.
for src in "$SOURCE_DIR"/*.toml; do
  [ -e "$src" ] || continue
  dst="$CODEX_AGENTS_DIR/$(basename "$src")"
  if [ -L "$dst" ] || [ ! -f "$dst" ] || ! cmp -s "$src" "$dst"; then
    echo "Agent validation failed: $dst" >&2
    exit 1
  fi
done
