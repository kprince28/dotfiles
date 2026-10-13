# Interactive zsh configuration. PATH/EDITOR live in ~/.zshenv.
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS HIST_REDUCE_BLANKS SHARE_HISTORY AUTO_CD

bindkey -e

# Oh My Zsh is optional: ./scripts/install-dev-tools.sh ohmyzsh
# Without it we fall back to plain compinit and a dependency-free prompt.
if [[ -r "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]]; then
  export ZSH="$HOME/.oh-my-zsh"
  ZSH_THEME="robbyrussell"
  zstyle ':omz:update' frequency 7
  plugins=(git)          # keep short; every plugin costs startup time
  source "$ZSH/oh-my-zsh.sh"
else
  autoload -Uz compinit && compinit
  PROMPT='%F{cyan}%n@%m%f:%F{blue}%~%f %# '
fi

alias ll='ls -lah'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'
alias dev='cd ~/Developer'
alias update='sudo apt-get update && sudo apt-get upgrade && sudo apt-get autoremove'

# nvm, lazy-loaded: the newest installed Node goes on PATH immediately (so node,
# npm and global CLIs work with no cost); nvm.sh itself loads on first `nvm` call.
export NVM_DIR="$HOME/.nvm"
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  _nvm_node=("$NVM_DIR"/versions/node/v*(N-/n[-1]))
  [[ -n "$_nvm_node" ]] && path=("$_nvm_node/bin" $path)
  unset _nvm_node
  nvm() {
    unfunction nvm
    source "$NVM_DIR/nvm.sh"
    [[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"
    nvm "$@"
  }
fi

# pyenv, if installed
export PYENV_ROOT="$HOME/.pyenv"
[[ -d "$PYENV_ROOT/bin" ]] && path=("$PYENV_ROOT/bin" $path)
(( $+commands[pyenv] )) && eval "$(pyenv init - zsh)"

# fzf bindings on Ubuntu, when available
[[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]] && source /usr/share/doc/fzf/examples/key-bindings.zsh
[[ -f /usr/share/doc/fzf/examples/completion.zsh ]] && source /usr/share/doc/fzf/examples/completion.zsh

# Local-only interactive overrides (never committed).
if [[ -f "$HOME/.zshrc.local" ]]; then source "$HOME/.zshrc.local"; fi
