#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

link() {
  local src="$1"
  local dst="$2"

  mkdir -p "$(dirname "$dst")"

  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    mv "$dst" "${dst}.bak"
    echo "Backed up: $dst -> ${dst}.bak"
  fi

  ln -sf "$src" "$dst"
  echo "Linked: $dst -> $src"
}

# Homebrew
if ! command -v brew &>/dev/null; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# zsh-autosuggestions
if ! brew list zsh-autosuggestions &>/dev/null; then
  echo "Installing zsh-autosuggestions..."
  brew install zsh-autosuggestions
fi

# Rust
if ! command -v rustup &>/dev/null; then
  echo "Installing Rust..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
fi

# pnpm
if ! command -v pnpm &>/dev/null; then
  echo "Installing pnpm..."
  curl -fsSL https://get.pnpm.io/install.sh | sh -
fi

# Vite+
if ! command -v vp &>/dev/null; then
  echo "Installing Vite+..."
  curl -fsSL https://vite.plus | bash
fi

# Home dotfiles
link "$DOTFILES/.zshrc"            "$HOME/.zshrc"
link "$DOTFILES/.zshenv"           "$HOME/.zshenv"
link "$DOTFILES/.zprofile"         "$HOME/.zprofile"
link "$DOTFILES/.gitconfig"        "$HOME/.gitconfig"
link "$DOTFILES/.gitignore_global" "$HOME/.gitignore_global"
link "$DOTFILES/.vimrc"            "$HOME/.vimrc"
link "$DOTFILES/.tmux.conf"        "$HOME/.tmux.conf"

# ~/.config/*
link "$DOTFILES/ghostty/config"           "$HOME/.config/ghostty/config"
link "$DOTFILES/karabiner/karabiner.json" "$HOME/.config/karabiner/karabiner.json"
link "$DOTFILES/yazi/yazi.toml"           "$HOME/.config/yazi/yazi.toml"

# ローカル上書きファイル（git 管理外）。無ければ雛形を作成
if [ ! -f "$DOTFILES/claude/AGENTS.local.md" ]; then
  cat > "$DOTFILES/claude/AGENTS.local.md" <<'LOCAL_EOF'
# ローカル上書き（このマシン専用・git 管理外）
# Claude Code / Codex 両方から読み込まれる。マシン固有のエージェント指示をここに書く。
LOCAL_EOF
  echo "Created: $DOTFILES/claude/AGENTS.local.md (machine-local, gitignored)"
fi

# ~/.claude/*
link "$DOTFILES/claude/settings.json"         "$HOME/.claude/settings.json"
link "$DOTFILES/claude/statusline-command.sh" "$HOME/.claude/statusline-command.sh"
link "$DOTFILES/claude/CLAUDE.md"             "$HOME/.claude/CLAUDE.md"
link "$DOTFILES/claude/AGENTS.md"             "$HOME/.claude/AGENTS.md"
link "$DOTFILES/claude/AGENTS.local.md"       "$HOME/.claude/AGENTS.local.md"
link "$DOTFILES/claude/codex-rescue.md"       "$HOME/.claude/codex-rescue.md"
link "$DOTFILES/claude/model-delegate.md"     "$HOME/.claude/model-delegate.md"
link "$DOTFILES/claude/skills/reload-rules/SKILL.md" "$HOME/.claude/skills/reload-rules/SKILL.md"

# ~/.codex/* — AGENTS.md（汎用ルール）と AGENTS.local.md（ローカル上書き）を Claude と共有
link "$DOTFILES/claude/AGENTS.md"             "$HOME/.codex/AGENTS.md"
link "$DOTFILES/claude/AGENTS.local.md"       "$HOME/.codex/AGENTS.local.md"

# Git 補完・プロンプトスクリプトをダウンロード
echo "Downloading git-prompt.sh and git-completion.bash..."
BASE_URL="https://raw.githubusercontent.com/git/git/master/contrib/completion"
mkdir -p "$HOME/.zsh"
curl -fsSL "$BASE_URL/git-prompt.sh"       -o "$HOME/.zsh/git-prompt.sh"
curl -fsSL "$BASE_URL/git-completion.bash" -o "$HOME/.zsh/git-completion.bash"
curl -fsSL "$BASE_URL/git-completion.zsh"  -o "$HOME/.zsh/_git"
echo "Downloaded to ~/.zsh/"

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

echo ""
echo "Done."
