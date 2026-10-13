# Ubuntu development Zsh configuration
export PATH="$HOME/.local/bin:$PATH"
export EDITOR="nano"
export VISUAL="$EDITOR"
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS HIST_REDUCE_BLANKS SHARE_HISTORY AUTO_CD

autoload -Uz compinit && compinit
bindkey -e

# Simple, dependency-free prompt
PROMPT='%F{cyan}%n@%m%f:%F{blue}%~%f %# '

alias ll='ls -lah'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'
alias dev='cd ~/Developer'
alias update='sudo apt-get update && sudo apt-get upgrade'

# Optional nvm support (if nvm is installed)
export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"

# fzf bindings on Ubuntu, when available
[[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]] && source /usr/share/doc/fzf/examples/key-bindings.zsh
[[ -f /usr/share/doc/fzf/examples/completion.zsh ]] && source /usr/share/doc/fzf/examples/completion.zsh
