# Environment for ALL zsh shells (interactive or not). Keep it small and fast;
# interactive setup belongs in ~/.zshrc.

# Local-only secrets and per-machine overrides (never committed, mode 600).
[[ -f "$HOME/.zshenv.local" ]] && source "$HOME/.zshenv.local"

# Avoid duplicate PATH entries in subshells.
typeset -U path PATH

path=(
  "$HOME/.local/bin"
  "$HOME/go/bin"
  "${KREW_ROOT:-$HOME/.krew}/bin"   # kubectl plugins (krew)
  $path
)

: "${EDITOR:=nano}"
export EDITOR VISUAL="${VISUAL:-$EDITOR}"
