alias ll="ls -l"
export PATH="$HOME/.local/bin:$PATH"

source ~/.zsh/git-prompt.sh
fpath=(~/.zsh $fpath)
zstyle ':completion:*:*:git:*' script ~/.zsh/git-completion.bash
autoload -Uz compinit && compinit
GIT_PS1_SHOWDIRTYSTATE=true
GIT_PS1_SHOWUNTRACKEDFILES=true
GIT_PS1_SHOWSTASHSTATE=true
GIT_PS1_SHOWUPSTREAM=auto
setopt PROMPT_SUBST
PS1='%F{green}%n@%m%f %F{cyan}%~%f %F{red}$(__git_ps1 "(%s)")%f\$ '

source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
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

# Machine-local secrets (not tracked in git)
[ -f ~/.zshrc.local ] && source ~/.zshrc.local

