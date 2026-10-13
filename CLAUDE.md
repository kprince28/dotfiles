# Repository Guidelines

Ubuntu workstation bootstrap: zsh/git dotfiles plus an idempotent tool installer.

## Layout
- `install.sh`: entrypoint. Updates apt, runs the tool installer, symlinks dotfiles, sets up git identity, `gh` login, zsh as login shell.
- `scripts/install-dev-tools.sh`: one `install_<tool>` function per tool; run all or name some (`./scripts/install-dev-tools.sh yq helm`). Opt-in extras (`ohmyzsh`, `krew`) are not in the default list.
- `scripts/verify.sh`: read-only post-install validation (PASS/WARN/FAIL, non-zero exit on FAIL); `--docker-run` also runs hello-world.
- `scripts/{enable,disable}-passwordless-sudo.sh`: optional and security-sensitive; never called automatically.
- `zsh/.zshenv` (PATH/EDITOR, all shells), `zsh/.zshrc` (interactive only), `git/.gitconfig`.
- `~/.zshenv.local` (secrets) and `~/.zshrc.local` (overrides) are machine-local and never committed.

## Conventions
- Bash with `set -Eeuo pipefail`, 2-space indent, small commented sections.
- Check before installing (`have <cmd>` or a path test) so re-runs skip cleanly.
- Do not pin versions: resolve the latest stable at run time, with an env-var override (e.g. `HELM_VERSION=`).
- Prefer official apt repos or checksummed release downloads; avoid piping remote scripts to a shell where a clone or download works.
- Never hardcode a git identity, secrets, or enable passwordless sudo by default.
- Keep `.zshenv` minimal; heavy setup belongs in `.zshrc`.

## Testing
- `bash -n install.sh scripts/*.sh` and `shellcheck -S warning install.sh scripts/*.sh`.
- Check zsh config: `zsh -n zsh/.zshenv zsh/.zshrc`, and time startup with `time zsh -i -c exit`.
- Functional: run in a fresh Ubuntu VM/container, then run again to confirm nothing breaks or reinstalls.

## Commits
Short imperative subjects ("Add krew installer"); group related changes.
