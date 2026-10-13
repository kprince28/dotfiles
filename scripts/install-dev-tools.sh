#!/usr/bin/env bash
# Installs developer tooling on Ubuntu. Idempotent: safe to re-run.
# Usage: ./scripts/install-dev-tools.sh [tool ...]
#   tools: base gh jq yq nvm docker vscode kubectl helm python claude   (default: all)
#   opt-in (name them explicitly): ohmyzsh krew
set -Eeuo pipefail

# Nothing is pinned: each tool resolves its latest stable release when run.
# Optional overrides via env, e.g. HELM_VERSION=v3.19.0 NODE_VERSION=22 ./scripts/install-dev-tools.sh
NODE_VERSION="${NODE_VERSION:---lts}"

log() { printf '\n==> %s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }
# latest_gh_tag <owner/repo>: latest release tag, via redirect (no API rate limit)
latest_gh_tag() { curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/$1/releases/latest" | sed 's|.*/||'; }

export DEBIAN_FRONTEND=noninteractive
command -v apt-get >/dev/null 2>&1 || { echo 'Debian/Ubuntu (apt) only.' >&2; exit 1; }
[[ "$EUID" -ne 0 ]] || { echo 'Run as your regular user, not root.' >&2; exit 1; }

ARCH="$(dpkg --print-architecture)"            # amd64 | arm64
CODENAME="$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")"
KEYRINGS=/etc/apt/keyrings
sudo install -m 0755 -d "$KEYRINGS"

# add_apt_repo <name> <key-url> <repo-line>
add_apt_repo() {
  local name="$1" key="$2" line="$3"
  curl -fsSL "$key" | sudo gpg --dearmor --yes -o "$KEYRINGS/$name.gpg"
  sudo chmod a+r "$KEYRINGS/$name.gpg"
  echo "$line" | sudo tee "/etc/apt/sources.list.d/$name.list" >/dev/null
  sudo apt-get update
}

install_base() {
  log 'Base packages'
  sudo apt-get update
  sudo apt-get install -y git zsh curl wget unzip zip gnupg ca-certificates \
    apt-transport-https software-properties-common build-essential pkg-config \
    jq ripgrep fd-find bat fzf tmux tree htop xclip openssh-client \
    sqlite3 libssl-dev libffi-dev
}

install_gh() {
  log 'GitHub CLI (official repo)'
  add_apt_repo githubcli https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    "deb [arch=$ARCH signed-by=$KEYRINGS/githubcli.gpg] https://cli.github.com/packages stable main"
  sudo apt-get install -y gh
}

install_jq() { log 'jq'; sudo apt-get install -y jq; }

install_yq() {
  local YQ_VERSION="${YQ_VERSION:-$(latest_gh_tag mikefarah/yq)}"
  log "yq $YQ_VERSION"
  if have yq && [[ "$(yq --version)" == *"${YQ_VERSION}"* ]]; then echo 'already installed'; return; fi
  sudo curl -fsSL "https://github.com/mikefarah/yq/releases/download/$YQ_VERSION/yq_linux_$ARCH" -o /usr/local/bin/yq
  sudo chmod +x /usr/local/bin/yq
}

install_nvm() {
  local NVM_VERSION="${NVM_VERSION:-$(latest_gh_tag nvm-sh/nvm)}"
  log "nvm $NVM_VERSION + Node ($NODE_VERSION)"
  if [[ ! -s "$HOME/.nvm/nvm.sh" ]]; then
    # PROFILE=/dev/null: our .zshrc already loads nvm; don't let the installer edit rc files
    curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh" | PROFILE=/dev/null bash
  fi
  export NVM_DIR="$HOME/.nvm"
  # shellcheck disable=SC1091
  set +u; source "$NVM_DIR/nvm.sh"; nvm install "$NODE_VERSION"
  [[ "$NODE_VERSION" == --lts ]] && nvm alias default 'lts/*' >/dev/null || nvm alias default "$NODE_VERSION" >/dev/null
  set -u
}

install_docker() {
  log 'Docker Engine + Compose v2 + Buildx (official repo)'
  if have docker; then
    echo 'docker already installed; skipping install (remove it first to switch to the official repo)'
  else
    add_apt_repo docker https://download.docker.com/linux/ubuntu/gpg \
      "deb [arch=$ARCH signed-by=$KEYRINGS/docker.gpg] https://download.docker.com/linux/ubuntu $CODENAME stable"
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo systemctl enable --now docker
  fi
  if getent group docker >/dev/null && ! id -nG "$USER" | grep -qw docker; then
    sudo usermod -aG docker "$USER"
    echo 'Added you to the docker group: log out/in for it to take effect.'
  fi
  # Compose v2 is `docker compose`; provide the legacy `docker-compose` name too.
  if ! have docker-compose; then
    sudo ln -sf /usr/libexec/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose
  fi
}

install_vscode() {
  log 'VS Code (Microsoft repo)'
  if have code; then echo 'already installed ('"$(command -v code)"')'; return; fi
  echo 'code code/add-microsoft-repo boolean false' | sudo debconf-set-selections
  add_apt_repo microsoft https://packages.microsoft.com/keys/microsoft.asc \
    "deb [arch=$ARCH signed-by=$KEYRINGS/microsoft.gpg] https://packages.microsoft.com/repos/code stable main"
  sudo apt-get install -y code
}

install_kubectl() {
  # newest stable minor, e.g. v1.37.1 -> v1.37 (override with KUBECTL_MINOR=v1.36)
  local KUBECTL_MINOR="${KUBECTL_MINOR:-$(curl -fsSL https://dl.k8s.io/release/stable.txt | cut -d. -f1,2)}"
  log "kubectl $KUBECTL_MINOR"
  add_apt_repo kubernetes "https://pkgs.k8s.io/core:/stable:/$KUBECTL_MINOR/deb/Release.key" \
    "deb [signed-by=$KEYRINGS/kubernetes.gpg] https://pkgs.k8s.io/core:/stable:/$KUBECTL_MINOR/deb/ /"
  sudo apt-get install -y kubectl
}

install_helm() {
  local HELM_VERSION="${HELM_VERSION:-$(latest_gh_tag helm/helm)}"
  log "helm $HELM_VERSION"
  if have helm && [[ "$(helm version --short)" == "${HELM_VERSION}"* ]]; then echo 'already installed'; return; fi
  local tmp; tmp="$(mktemp -d)"
  curl -fsSL "https://get.helm.sh/helm-$HELM_VERSION-linux-$ARCH.tar.gz" -o "$tmp/helm.tgz"
  tar -xzf "$tmp/helm.tgz" -C "$tmp"
  sudo install -m 0755 "$tmp/linux-$ARCH/helm" /usr/local/bin/helm
  rm -rf "$tmp"
}

install_python() {
  log 'Python (system python3 + venv/pip) + pipx + uv'
  sudo apt-get install -y python3 python3-venv python3-pip python3-dev pipx
  pipx ensurepath >/dev/null 2>&1 || true
  have uv || curl -fsSL https://astral.sh/uv/install.sh | sh
}

install_claude() {
  log 'Claude Code (native installer)'
  have claude && { echo 'already installed'; return; }
  curl -fsSL https://claude.ai/install.sh | bash
}

# --- opt-in extras (not part of the default run) ---
install_ohmyzsh() {
  log 'Oh My Zsh (git clone, no remote script piped to a shell)'
  have git || sudo apt-get install -y git
  if [[ -d "$HOME/.oh-my-zsh" ]]; then git -C "$HOME/.oh-my-zsh" pull --ff-only
  else git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"; fi
}

install_krew() {
  log 'krew (kubectl plugin manager)'
  have kubectl || { echo 'install kubectl first' >&2; return 1; }
  [[ -x "${KREW_ROOT:-$HOME/.krew}/bin/kubectl-krew" ]] && { echo 'already installed'; return; }
  local tmp os arch; tmp="$(mktemp -d)"; os=linux; arch="$ARCH"
  curl -fsSL "https://github.com/kubernetes-sigs/krew/releases/latest/download/krew-${os}_${arch}.tar.gz" -o "$tmp/krew.tgz"
  tar -xzf "$tmp/krew.tgz" -C "$tmp"
  "$tmp/krew-${os}_${arch}" install krew
  rm -rf "$tmp"
}

summary() {
  log 'Installed versions'
  export PATH="$HOME/.local/bin:$PATH"
  [[ -s "$HOME/.nvm/nvm.sh" ]] && { set +u; source "$HOME/.nvm/nvm.sh"; set -u; }
  for c in "git --version" "gh --version" "jq --version" "yq --version" "node --version" "npm --version" \
           "docker --version" "docker compose version" "code --version" "kubectl version --client" \
           "helm version --short" "python3 --version" "uv --version" "claude --version"; do
    printf '%-26s' "${c%% *}:"; ( eval "$c" 2>&1 | head -n1 ) || echo 'NOT FOUND'
  done
}

ALL=(base gh jq yq nvm docker vscode kubectl helm python claude)
TARGETS=("${@:-${ALL[@]}}")
for t in "${TARGETS[@]}"; do
  declare -F "install_$t" >/dev/null || { echo "Unknown tool: $t (available: ${ALL[*]})" >&2; exit 1; }
  "install_$t"
done
summary
