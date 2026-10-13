#!/usr/bin/env bash
# Validates a machine set up by install.sh. Read-only; exits non-zero if any check FAILs.
# shellcheck disable=SC2088  # literal "~" in messages is intentional
# Usage: ./scripts/verify.sh [--docker-run]   (--docker-run also pulls/runs hello-world)
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="$HOME/.local/bin:$PATH"
[[ -s "$HOME/.nvm/nvm.sh" ]] && { set +u; source "$HOME/.nvm/nvm.sh"; set -u; }

pass=0 fail=0 warn=0
ok()   { printf '  \033[32mPASS\033[0m %s\n' "$*"; pass=$((pass+1)); }
bad()  { printf '  \033[31mFAIL\033[0m %s\n' "$*"; fail=$((fail+1)); }
note() { printf '  \033[33mWARN\033[0m %s\n' "$*"; warn=$((warn+1)); }
sec()  { printf '\n== %s\n' "$*"; }

# tool <label> <command> <version command...>
tool() {
  local label="$1" cmd="$2"; shift 2
  if command -v "$cmd" >/dev/null 2>&1; then
    ok "$label: $("$@" 2>&1 | head -n1)"
  else
    bad "$label: '$cmd' not found"
  fi
}

sec 'Tools'
tool git git git --version
tool 'GitHub CLI' gh gh --version
tool jq jq jq --version
tool yq yq yq --version
tool node node node --version
tool npm npm npm --version
tool docker docker docker --version
tool kubectl kubectl kubectl version --client
tool helm helm helm version --short
tool python3 python3 python3 --version
tool uv uv uv --version
tool 'Claude Code' claude claude --version
tool zsh zsh zsh --version
tool ripgrep rg rg --version
tool VS\ Code code code --version
python3 -m venv --help >/dev/null 2>&1 && ok 'python3-venv available' || bad 'python3-venv missing'
python3 -m pip --version >/dev/null 2>&1 && ok 'pip available' || bad 'pip missing'

sec 'nvm / Node'
if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
  ok "nvm $(set +u; nvm --version)"
  node --version 2>/dev/null | grep -q . && ok "default node: $(node --version)" || bad 'no node installed via nvm'
  lts="$(set +u; nvm version-remote --lts 2>/dev/null)"
  [[ -n "$lts" && "$(node --version 2>/dev/null)" == "$lts" ]] && ok "node is latest LTS ($lts)" || note "node is not the latest LTS (latest: ${lts:-unknown})"
else
  bad '~/.nvm/nvm.sh missing'
fi

sec 'Docker'
if command -v docker >/dev/null 2>&1; then
  docker compose version >/dev/null 2>&1 && ok "compose: $(docker compose version | head -n1)" || bad 'docker compose plugin missing'
  command -v docker-compose >/dev/null 2>&1 && ok 'docker-compose command present' || note 'no legacy docker-compose command'
  docker buildx version >/dev/null 2>&1 && ok 'buildx present' || note 'buildx missing'
  if docker info >/dev/null 2>&1; then
    ok 'daemon reachable without sudo'
  elif sudo -n docker info >/dev/null 2>&1; then
    bad 'daemon works only with sudo: add yourself to the docker group and log out/in'
  else
    bad 'daemon not reachable (is it running? systemctl status docker)'
  fi
  id -nG | grep -qw docker && ok 'user in docker group' || note 'user not in docker group (or needs re-login)'
  [[ "${1:-}" == --docker-run ]] && { docker run --rm hello-world >/dev/null 2>&1 && ok 'hello-world container ran' || bad 'hello-world failed'; }
fi

sec 'GitHub / Git'
gh auth status >/dev/null 2>&1 && ok 'gh authenticated' || bad 'gh not authenticated (gh auth login)'
ssh -o BatchMode=yes -o ConnectTimeout=8 -T git@github.com 2>&1 | grep -q 'successfully authenticated' && ok 'ssh to github.com works' || note 'ssh to github.com not verified (needs an SSH key added to GitHub)'
[[ -n "$(git config --global user.name)" ]] && ok "git user.name: $(git config --global user.name)" || bad 'git user.name unset'
[[ -n "$(git config --global user.email)" ]] && ok "git user.email: $(git config --global user.email)" || bad 'git user.email unset'

sec 'Kubernetes / Helm'
kubectl config current-context >/dev/null 2>&1 && ok "kube context: $(kubectl config current-context)" || note 'no kube context configured (expected on a fresh machine)'
helm env >/dev/null 2>&1 && ok 'helm runs' || bad 'helm env failed'

sec 'Dotfiles'
for f in .zshenv .zshrc .gitconfig; do
  src="$(find "$ROOT/zsh" "$ROOT/git" -maxdepth 1 -name "$f" | head -n1)"
  if [[ -L "$HOME/$f" && "$(readlink -f "$HOME/$f")" == "$(readlink -f "$src")" ]]; then ok "~/$f -> repo"; else bad "~/$f is not linked to the repo"; fi
done
if [[ -f "$HOME/.zshenv.local" ]]; then
  [[ "$(stat -c %a "$HOME/.zshenv.local")" == 600 ]] && ok '~/.zshenv.local mode 600' || bad '~/.zshenv.local should be mode 600'
else
  bad '~/.zshenv.local missing'
fi
[[ "$(getent passwd "$USER" | cut -d: -f7)" == *zsh ]] && ok 'login shell is zsh' || note "login shell is not zsh (chsh -s $(command -v zsh))"
if command -v zsh >/dev/null 2>&1; then
  start=$(date +%s%N); zerr="$(zsh -i -c 'exit 0' 2>&1 >/dev/null)"; rc=$?; ms=$(( ($(date +%s%N)-start)/1000000 ))
  [[ $rc -eq 0 && -z "$zerr" ]] && ok "zsh starts cleanly (${ms}ms)" || bad "zsh -i reported problems: ${zerr:-exit code $rc}"
  (( ms > 1000 )) && note 'zsh startup is slow (>1s)'
  dup="$(zsh -i -c 'print -l $path' 2>/dev/null | sort | uniq -d)"
  [[ -z "$dup" ]] && ok 'no duplicate PATH entries' || note "duplicate PATH entries: $dup"
fi
sudo -n true 2>/dev/null && note 'passwordless sudo is ENABLED (intended?)' || ok 'sudo requires a password (default)'

printf '\n%d passed, %d warnings, %d failed\n' "$pass" "$warn" "$fail"
(( fail == 0 ))
