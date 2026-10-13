#!/usr/bin/env bash
set -Eeuo pipefail

export DEBIAN_FRONTEND=noninteractive

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() { printf '\n==> %s\n' "$*"; }
backup_and_link() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [[ -L "$dst" ]] && [[ "$(readlink -f "$dst")" == "$(readlink -f "$src")" ]]; then
    log "Already linked: $dst"
    return
  fi
  if [[ -e "$dst" || -L "$dst" ]]; then
    mv "$dst" "${dst}.backup.$(date +%Y%m%d%H%M%S)"
  fi
  ln -s "$src" "$dst"
  log "Linked $dst"
}

if [[ "$EUID" -eq 0 ]]; then
  echo 'Run this script as your regular user, not root.' >&2
  exit 1
fi

if ! command -v apt-get >/dev/null 2>&1; then
  echo 'This script supports Debian/Ubuntu (apt) only.' >&2
  exit 1
fi

log 'Updating system packages'
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get autoremove -y

log 'Installing developer tools'
"$ROOT/scripts/install-dev-tools.sh"

log 'Creating development directories'
mkdir -p "$HOME/Developer"/{work,personal,learning}

log 'Linking dotfiles (existing files backed up)'
backup_and_link "$ROOT/zsh/.zshenv" "$HOME/.zshenv"
backup_and_link "$ROOT/zsh/.zshrc" "$HOME/.zshrc"
backup_and_link "$ROOT/git/.gitconfig" "$HOME/.gitconfig"

log 'Local-only secrets file (~/.zshenv.local, never committed)'
if [[ ! -f "$HOME/.zshenv.local" ]]; then
  cp "$ROOT/zsh/.zshenv.local.example" "$HOME/.zshenv.local"
fi
chmod 600 "$HOME/.zshenv.local"

log 'Git identity (only if not configured)'
if [[ -z "$(git config --global --get user.name || true)" ]]; then
  read -r -p 'Git author name (leave blank to skip): ' git_name
  if [[ -n "$git_name" ]]; then git config --global user.name "$git_name"; fi
fi
if [[ -z "$(git config --global --get user.email || true)" ]]; then
  read -r -p 'Git author email (leave blank to skip): ' git_email
  if [[ -n "$git_email" ]]; then git config --global user.email "$git_email"; fi
fi

log 'GitHub CLI login'
if ! gh auth status >/dev/null 2>&1; then
  gh auth login --hostname github.com --git-protocol ssh --web
else
  log 'gh already authenticated; skipping login'
fi

log 'Setting Zsh as default login shell'
ZSH_BIN="$(command -v zsh)"
if [[ "$SHELL" != "$ZSH_BIN" ]]; then
  chsh -s "$ZSH_BIN" || echo 'Could not change shell automatically; run: chsh -s "$(command -v zsh)"'
fi

cat <<'MSG'

Installed! Log out and log back in (or run: exec zsh).
Verify GitHub: gh auth status
Verify SSH: ssh -T git@github.com

Passwordless sudo is NOT enabled by default. If you want it, first read README.md,
then run: ./scripts/enable-passwordless-sudo.sh
MSG
