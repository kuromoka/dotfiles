alias ll="ls -la"
export PATH="$HOME/.local/bin:$PATH"

[ -f "$HOME/.zsh/git-prompt.sh" ] && source "$HOME/.zsh/git-prompt.sh"
fpath=(~/.zsh $fpath)
zstyle ':completion:*:*:git:*' script ~/.zsh/git-completion.bash
autoload -Uz compinit && compinit
GIT_PS1_SHOWDIRTYSTATE=true
GIT_PS1_SHOWUNTRACKEDFILES=true
GIT_PS1_SHOWSTASHSTATE=true
GIT_PS1_SHOWUPSTREAM=auto
setopt PROMPT_SUBST
if (( $+functions[__git_ps1] )); then
  PS1='%F{green}%n@%m%f %F{cyan}%~%f %F{red}$(__git_ps1 "(%s)")%f\$ '
else
  PS1='%F{green}%n@%m%f %F{cyan}%~%f\$ '
fi

if [ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
  autosuggestions=/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
elif command -v brew >/dev/null 2>&1; then
  autosuggestions="$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
else
  autosuggestions=/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi
[ -f "$autosuggestions" ] && source "$autosuggestions"
unset autosuggestions

# pnpm
if [[ "$(uname -s)" == Darwin ]]; then
  export PNPM_HOME="${PNPM_HOME:-$HOME/Library/pnpm}"
else
  export PNPM_HOME="${PNPM_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/pnpm}"
fi
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=($HOME/.docker/completions $fpath)
autoload -Uz compinit
compinit
# End of Docker CLI completions


# opencode
export PATH=~/.opencode/bin:$PATH

# yazi: `y` で起動し、終了時に最後のディレクトリへ cd する
# https://yazi-rs.github.io/docs/quick-start
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
	command rm -f -- "$tmp"
}
