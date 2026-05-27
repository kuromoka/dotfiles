# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# Rust
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# Vite+ bin (https://viteplus.dev)
. "$HOME/.vite-plus/env"
