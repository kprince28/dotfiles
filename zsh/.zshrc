# Interactive zsh configuration. PATH/EDITOR live in ~/.zshenv.
# History: big, shared across terminals, timestamped, de-duplicated.
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt EXTENDED_HISTORY HIST_EXPIRE_DUPS_FIRST HIST_IGNORE_DUPS HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS HIST_VERIFY SHARE_HISTORY AUTO_CD

bindkey -e

# Up/Down search history by what you've already typed ("git " + Up = last git commands).
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
for _k in '^[[A' '^[OA' "${terminfo[kcuu1]}"; do [[ -n "$_k" ]] && bindkey "$_k" up-line-or-beginning-search; done
for _k in '^[[B' '^[OB' "${terminfo[kcud1]}"; do [[ -n "$_k" ]] && bindkey "$_k" down-line-or-beginning-search; done
unset _k

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

# Inline suggestions from history (Right arrow / End accepts) and syntax colouring.
# Packages: zsh-autosuggestions, zsh-syntax-highlighting. Highlighting must load last.
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
for _p in /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
          "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"; do
  [[ -r "$_p" ]] && { source "$_p"; break; }
done
for _p in /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
          "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"; do
  [[ -r "$_p" ]] && { source "$_p"; break; }
done
unset _p

# Local-only interactive overrides (never committed).
if [[ -f "$HOME/.zshrc.local" ]]; then source "$HOME/.zshrc.local"; fi
