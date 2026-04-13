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

# Home dotfiles
link "$DOTFILES/.zshrc"            "$HOME/.zshrc"
link "$DOTFILES/.zshenv"           "$HOME/.zshenv"
link "$DOTFILES/.zprofile"         "$HOME/.zprofile"
link "$DOTFILES/.gitconfig"        "$HOME/.gitconfig"
link "$DOTFILES/.gitignore_global" "$HOME/.gitignore_global"
link "$DOTFILES/.vimrc"            "$HOME/.vimrc"

# ~/.config/*
link "$DOTFILES/ghostty/config"           "$HOME/.config/ghostty/config"
link "$DOTFILES/karabiner/karabiner.json" "$HOME/.config/karabiner/karabiner.json"
link "$DOTFILES/zellij/config.kdl"        "$HOME/.config/zellij/config.kdl"

# ~/.claude/*
link "$DOTFILES/claude/settings.json"        "$HOME/.claude/settings.json"
link "$DOTFILES/claude/statusline-command.sh" "$HOME/.claude/statusline-command.sh"

# Git 補完・プロンプトスクリプトをダウンロード
echo "Downloading git-prompt.sh and git-completion.bash..."
GIT_VERSION=$(git --version | awk '{print $3}')
BASE_URL="https://raw.githubusercontent.com/git/git/v${GIT_VERSION}/contrib/completion"
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
