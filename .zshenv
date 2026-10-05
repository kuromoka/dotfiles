# Homebrew
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# Rust
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# Vite+ bin (https://viteplus.dev)
[ -f "$HOME/.vite-plus/env" ] && . "$HOME/.vite-plus/env"
