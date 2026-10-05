#!/usr/bin/env bash
# Shared implementation; run the platform-specific installer instead.
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  echo "Run install.sh or install-ubuntu.sh instead." >&2
  exit 1
fi

# HOME itself is a user-selected boundary, including a home symlink.
mkdir -p "$HOME"

validation_error() {
  echo "Installation validation failed: $1" >&2
  exit 1
}

# Keep signatures in memory; never print machine-local contents or checksums.
path_signature() {
  local path="$1"
  if [ -L "$path" ]; then
    printf 'link %s\n' "$(readlink "$path")"
  fi
  if [ -d "$path" ]; then
    (
      cd "$path"
      find . -type f -exec cksum {} \;
      find . -type l -exec sh -c 'for path do printf "%s -> %s\n" "$path" "$(readlink "$path")"; done' sh {} +
      find . -type d -print
    ) | LC_ALL=C sort | cksum
  elif [ -f "$path" ]; then
    cksum < "$path"
  elif [ ! -L "$path" ]; then
    validation_error "unreadable path: $path"
  fi
}

EXPECTED_SOURCES=()
EXPECTED_DESTINATIONS=()
PRESERVED_PATHS=()
PRESERVED_SIGNATURES=()
for local_path in "$HOME/.zshrc.local" "$HOME/.gitconfig.local" \
    "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/AGENTS.local.md" \
    "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.local.json" \
    "${CODEX_HOME:-$HOME/.codex}/AGENTS.local.md" \
    "${CODEX_HOME:-$HOME/.codex}/config.toml"; do
  if [ -e "$local_path" ] || [ -L "$local_path" ]; then
    PRESERVED_PATHS+=("$local_path")
    # Parent directory links are replaced with copies; preserve file contents.
    if [ -f "$local_path" ]; then
      PRESERVED_SIGNATURES+=("$(cksum < "$local_path")")
    else
      PRESERVED_SIGNATURES+=("$(path_signature "$local_path")")
    fi
  fi
done

backup_path() {
  local dst="$1" backup="${1}.bak" index=1
  while [ -e "$backup" ] || [ -L "$backup" ]; do
    backup="${dst}.bak.${index}"
    index=$((index + 1))
  done
  printf '%s\n' "$backup"
}

backup_existing() {
  local dst="$1" backup signature
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    backup="$(backup_path "$dst")"
    signature="$(path_signature "$dst")"
    mv "$dst" "$backup"
    [ "$(path_signature "$backup")" = "$signature" ] || validation_error "backup differs: $backup"
    echo "Backed up: $dst -> $backup"
  fi
}

ensure_directory() {
  local dir="$1" parent backup ancestor
  [ "$dir" = "$HOME" ] && return
  [ "$dir" = / ] && return
  [ "$dir" = . ] && return
  parent="$(dirname "$dir")"
  # Never rewrite system-level directory aliases outside the home/config roots.
  if [ "$parent" = "$HOME" ] || [[ "$parent" == "$HOME/"* ]] || \
     [[ "$parent" == "${CODEX_HOME:-$HOME/.codex}"* ]] || \
     [[ "$parent" == "${CLAUDE_CONFIG_DIR:-$HOME/.claude}"* ]]; then
    ensure_directory "$parent"
  else
    # External config roots may use real directories, but do not follow an
    # unowned ancestor link. Supply its physical path instead.
    ancestor="$parent"
    while [ "$ancestor" != / ] && [ "$ancestor" != . ]; do
      if [ -L "$ancestor" ]; then
        case "$ancestor:$(readlink "$ancestor")" in
          /var:private/var|/var:/private/var|/tmp:private/tmp|/tmp:/private/tmp) ;;
          *)
            echo "Refusing linked parent outside HOME: $ancestor (use a physical path)." >&2
            exit 1
            ;;
        esac
      fi
      ancestor="$(dirname "$ancestor")"
    done
  fi
  if [ -L "$dir" ]; then
    backup="$(backup_path "$dir")"
    local signature
    signature="$(path_signature "$dir")"
    mv "$dir" "$backup"
    [ "$(path_signature "$backup")" = "$signature" ] || validation_error "backup differs: $backup"
    mkdir -p "$dir"
    if [ -d "$backup" ]; then
      cp -R "$backup/." "$dir/"
    fi
    echo "Backed up directory link: $dir -> $backup"
  elif [ ! -d "$dir" ]; then
    backup_existing "$dir"
    mkdir -p "$dir"
  fi
}

link() {
  local src="$1" dst="$2"
  [ -e "$src" ] || validation_error "missing source: $src"
  EXPECTED_SOURCES+=("$src")
  EXPECTED_DESTINATIONS+=("$dst")
  ensure_directory "$(dirname "$dst")"
  # Never replace the source itself, including an already-correct symlink.
  if [ "$src" -ef "$dst" ] 2>/dev/null; then
    return
  fi
  if [ ! -L "$dst" ] && [ -f "$src" ] && [ -f "$dst" ] && cmp -s "$src" "$dst"; then
    return
  fi
  backup_existing "$dst"
  ln -s "$src" "$dst"
  echo "Linked: $dst -> $src"
}

case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

if ! command -v rustup &>/dev/null && [ ! -x "$HOME/.cargo/bin/rustup" ]; then
  echo "Installing Rust..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi
if ! command -v pnpm &>/dev/null; then
  echo "Installing pnpm..."
  curl -fsSL https://get.pnpm.io/install.sh | SHELL="$(command -v zsh)" sh -
fi
if ! command -v vp &>/dev/null && [ ! -x "$HOME/.vite-plus/bin/vp" ]; then
  echo "Installing Vite+..."
  curl -fsSL https://vite.plus | bash
fi
echo "Installing/updating natural-japanese..."
pnpm dlx skills add coji/natural-japanese \
  --global --agent claude-code codex --skill natural-japanese --yes

# Home dotfiles
link "$DOTFILES/.zshrc"            "$HOME/.zshrc"
link "$DOTFILES/.zshenv"           "$HOME/.zshenv"
link "$DOTFILES/.zprofile"         "$HOME/.zprofile"
link "$DOTFILES/.gitconfig"        "$HOME/.gitconfig"
link "$DOTFILES/.gitignore_global" "$HOME/.gitignore_global"
link "$DOTFILES/.vimrc"            "$HOME/.vimrc"

# ~/.config/*
if [ "$PLATFORM" = macos ]; then
  link "$DOTFILES/ghostty/config" "$HOME/.config/ghostty/config"
else
  # Linux gets a regular file without macOS-only Ghostty options.
  GHOSTTY_CONFIG="$HOME/.config/ghostty/config"
  ensure_directory "$(dirname "$GHOSTTY_CONFIG")"
  GHOSTTY_TMP="$(mktemp)"
  trap 'rm -f "$GHOSTTY_TMP"' EXIT
  awk '!/^[[:space:]]*(macos-option-as-alt|macos-titlebar-style|window-save-state)[[:space:]]*=/' \
    "$DOTFILES/ghostty/config" > "$GHOSTTY_TMP"
  if [ -L "$GHOSTTY_CONFIG" ] || ! cmp -s "$GHOSTTY_TMP" "$GHOSTTY_CONFIG"; then
    backup_existing "$GHOSTTY_CONFIG"
    install -m 0644 "$GHOSTTY_TMP" "$GHOSTTY_CONFIG"
    echo "Installed: $GHOSTTY_CONFIG (Ubuntu)"
  fi
  rm -f "$GHOSTTY_TMP"
  trap - EXIT
fi
# Karabiner-Elements は保存時にファイルを rename で置き換えるため、ファイル単位のリンクは外れる。ディレクトリごとリンクする
if [ "$PLATFORM" = macos ]; then
  link "$DOTFILES/karabiner" "$HOME/.config/karabiner"
fi
link "$DOTFILES/yazi/yazi.toml"           "$HOME/.config/yazi/yazi.toml"
link "$DOTFILES/herdr/config.toml"        "$HOME/.config/herdr/config.toml"

# Windows AutoHotkey settings are installed from Windows, not from Unix.
echo "Windows IME switching: see autohotkey/realforce-ime.ahk and autohotkey/install.ps1."

# Machine-local rules live under HOME, never in the checkout.
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
CLAUDE_LOCAL="$CLAUDE_DIR/AGENTS.local.md"
CODEX_DIR="${CODEX_HOME:-$HOME/.codex}"
ensure_directory "$CLAUDE_DIR"
ensure_directory "$CODEX_DIR"
if [ ! -e "$CLAUDE_LOCAL" ] && [ ! -L "$CLAUDE_LOCAL" ]; then
  if [ -f "$DOTFILES/claude/AGENTS.local.md" ]; then
    cp "$DOTFILES/claude/AGENTS.local.md" "$CLAUDE_LOCAL"
  else
    cat > "$CLAUDE_LOCAL" <<'LOCAL_EOF'
# ローカル上書き（このマシン専用・git 管理外）
# Claude Code / Codex 両方から読み込まれる。マシン固有のエージェント指示をここに書く。
LOCAL_EOF
  fi
  echo "Created: $CLAUDE_LOCAL (machine-local)"
fi
if [ ! -e "$CODEX_DIR/AGENTS.local.md" ] && [ ! -L "$CODEX_DIR/AGENTS.local.md" ]; then
  cp "$CLAUDE_LOCAL" "$CODEX_DIR/AGENTS.local.md"
fi

# ~/.claude/*
link "$DOTFILES/claude/settings.json"         "$CLAUDE_DIR/settings.json"
link "$DOTFILES/claude/statusline-command.sh" "$CLAUDE_DIR/statusline-command.sh"
link "$DOTFILES/claude/CLAUDE.md"             "$CLAUDE_DIR/CLAUDE.md"
link "$DOTFILES/claude/AGENTS.md"             "$CLAUDE_DIR/AGENTS.md"
link "$DOTFILES/claude/codex-rescue.md"       "$CLAUDE_DIR/codex-rescue.md"
link "$DOTFILES/claude/model-delegate.md"     "$CLAUDE_DIR/model-delegate.md"
link "$DOTFILES/claude/skills/reload-rules/SKILL.md" "$CLAUDE_DIR/skills/reload-rules/SKILL.md"
link "$DOTFILES/claude/skills/kuromoka-writing" "$CLAUDE_DIR/skills/kuromoka-writing"

# ~/.codex/* — AGENTS.md（汎用ルール）と AGENTS.local.md（ローカル上書き）を Claude と共有
link "$DOTFILES/claude/AGENTS.md"             "$CODEX_DIR/AGENTS.md"
link "$DOTFILES/claude/skills/kuromoka-writing" "$CODEX_DIR/skills/kuromoka-writing"

# Antigravity CLI
link "$DOTFILES/claude/skills/kuromoka-writing" "$HOME/.gemini/config/skills/kuromoka-writing"

# ~/.codex/agents/* — Codex agent profiles must be standalone files
ensure_directory "$CODEX_DIR/agents"
"$DOTFILES/codex/sync-agents.sh" "$CODEX_DIR/agents"

# Git completion
echo "Downloading git-prompt.sh and git-completion.bash..."
BASE_URL="https://raw.githubusercontent.com/git/git/master/contrib/completion"
ensure_directory "$HOME/.zsh"
curl -fsSL "$BASE_URL/git-prompt.sh"       -o "$HOME/.zsh/git-prompt.sh"
curl -fsSL "$BASE_URL/git-completion.bash" -o "$HOME/.zsh/git-completion.bash"
curl -fsSL "$BASE_URL/git-completion.zsh"  -o "$HOME/.zsh/_git"

# .zshrc.local のセットアップ案内
if [ ! -f "$HOME/.zshrc.local" ]; then
  echo ""
  echo "Note: ~/.zshrc.local not found. Create it to add machine-local secrets."
fi

# .gitconfig.local のセットアップ案内
if [ ! -f "$HOME/.gitconfig.local" ]; then
  echo ""
  echo "Note: ~/.gitconfig.local not found. Create it to set your name and email."
fi

validate_installation() {
  local index src dst file signature
  for ((index=0; index<${#EXPECTED_SOURCES[@]}; index++)); do
    src="${EXPECTED_SOURCES[$index]}"
    dst="${EXPECTED_DESTINATIONS[$index]}"
    [ -e "$src" ] && [ -e "$dst" ] || validation_error "missing source or destination: $src -> $dst"
    if [ -d "$src" ]; then
      [ "$src" -ef "$dst" ] || validation_error "directory link differs: $dst"
      while IFS= read -r -d '' file; do
        cmp -s "$file" "$dst/${file#"$src/"}" || validation_error "managed file differs: $file -> $dst"
      done < <(find "$src" -type f -print0)
    elif [ "$src" -ef "$dst" ]; then
      :
    elif [ ! -L "$dst" ] && [ -f "$dst" ] && cmp -s "$src" "$dst"; then
      :
    else
      validation_error "installed file differs: $dst"
    fi
  done
  if [ "$PLATFORM" = ubuntu ]; then
    [ -f "$GHOSTTY_CONFIG" ] && [ ! -L "$GHOSTTY_CONFIG" ] || validation_error "Ghostty must be a regular file: $GHOSTTY_CONFIG"
    cmp -s <(awk '!/^[[:space:]]*(macos-option-as-alt|macos-titlebar-style|window-save-state)[[:space:]]*=/' "$DOTFILES/ghostty/config") "$GHOSTTY_CONFIG" || validation_error "Ubuntu Ghostty content differs: $GHOSTTY_CONFIG"
    if grep -Eq '^[[:space:]]*(macos-option-as-alt|macos-titlebar-style|window-save-state)[[:space:]]*=' "$GHOSTTY_CONFIG"; then
      validation_error "macOS option in Ubuntu Ghostty: $GHOSTTY_CONFIG"
    fi
  fi
  for src in "$DOTFILES/codex/agents/"*.toml; do
    [ -e "$src" ] || continue
    dst="$CODEX_DIR/agents/$(basename "$src")"
    [ -f "$dst" ] && [ ! -L "$dst" ] && cmp -s "$src" "$dst" || validation_error "Codex agent differs or is linked: $dst"
  done
  for dst in "$HOME/.zsh/git-prompt.sh" "$HOME/.zsh/git-completion.bash" "$HOME/.zsh/_git"; do
    [ -s "$dst" ] || validation_error "Git completion is empty or missing: $dst"
  done
  for dst in "$CLAUDE_LOCAL" "$CODEX_DIR/AGENTS.local.md"; do
    [ -f "$dst" ] || validation_error "local rules missing: $dst"
  done
  for ((index=0; index<${#PRESERVED_PATHS[@]}; index++)); do
    dst="${PRESERVED_PATHS[$index]}"
    [ -e "$dst" ] || [ -L "$dst" ] || validation_error "machine-local file missing: $dst"
    if [ -f "$dst" ]; then
      signature="$(cksum < "$dst")"
    else
      signature="$(path_signature "$dst")"
    fi
    [ "$signature" = "${PRESERVED_SIGNATURES[$index]}" ] || validation_error "machine-local file changed: $dst"
  done
  echo "Installation checks passed."
}

validate_installation
echo ""
echo "Done."
