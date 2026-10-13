# Ubuntu Developer Dotfiles

Minimal, readable dotfiles for a fresh Ubuntu workstation.

## Setup

```bash
git clone https://github.com/kprince28/dotfiles.git ~/dotfiles
cd ~/dotfiles
chmod +x install.sh scripts/*.sh
./install.sh
```

The installer installs basic tools (`git`, `gh`, `zsh`, and shell utilities), creates `~/Developer`, backs up existing `~/.zshrc` and `~/.gitconfig` before symlinking, prompts for missing Git name/email, starts GitHub CLI browser login, and changes your login shell to Zsh. **Log out and log back in** after installing. The GitHub SSH login can offer to generate/upload a key.

Verify:

```bash
gh auth status
ssh -T git@github.com
zsh --version
```

## Passwordless sudo (optional; higher risk)

Enabling passwordless sudo means any application/code running as your user can potentially run root commands without a password challenge. Avoid on shared machines, with untrusted scripts, or where policy forbids it. An alternative is retaining Ubuntu's default timed credential cache.

To enable *only after reviewing the script*:

```bash
./scripts/enable-passwordless-sudo.sh
```

The script confirms intent, validates the generated sudoers rule with `visudo`, and creates `/etc/sudoers.d/90-YOURUSER-nopasswd` with mode 0440. It does **not** edit `/etc/sudoers` directly. To undo:

```bash
./scripts/disable-passwordless-sudo.sh
```

## Notes

- The installer does **not** enable passwordless sudo by default.
- `scripts/install-dev-tools.sh` installs: git, gh, jq, yq, nvm + Node, Docker Engine + Compose v2 (+ `docker-compose` alias), VS Code, kubectl, helm, Python 3 (+ venv, pip, pipx, uv), Claude Code, plus ripgrep, fd, bat, fzf, tmux, htop, sqlite3 and build tools. Nothing is pinned: each run installs the latest stable release (Node uses the latest LTS). Override with env vars, e.g. `NODE_VERSION=22 HELM_VERSION=v3.19.0 ./scripts/install-dev-tools.sh`.
- Install or upgrade one tool only: `./scripts/install-dev-tools.sh helm kubectl`. It is safe to re-run.
- Docker needs a log out/in after install (docker group membership).
- The Git configuration template does not include your personal name or email; the installer prompts for missing values.
- Existing dotfiles are saved as `.backup.TIMESTAMP` next to their originals.
