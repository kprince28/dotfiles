#!/usr/bin/env bash
set -Eeuo pipefail

if [[ "$EUID" -eq 0 ]]; then
  echo 'Run as the regular user whose sudo privileges should be changed.' >&2
  exit 1
fi
if ! id -nG "$USER" | grep -qw sudo; then
  echo 'Your account is not in the sudo group. Aborting.' >&2
  exit 1
fi

printf '%s\n' 'WARNING: This gives your user passwordless access to ALL sudo commands.' \
  'Any process running as your user can potentially gain root privileges.' \
  'This is NOT recommended for shared systems or machines containing sensitive data.'
read -r -p "Type ENABLE PASSWORDLESS SUDO to proceed: " answer
[[ "$answer" == 'ENABLE PASSWORDLESS SUDO' ]] || { echo 'Cancelled.'; exit 1; }

user_name="$(id -un)"
# Only accept safe account names before writing a sudoers entry.
[[ "$user_name" =~ ^[a-z_][a-z0-9_-]*[$]?$ ]] || { echo 'Unsupported username format.' >&2; exit 1; }
file="/etc/sudoers.d/90-${user_name}-nopasswd"
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
printf '%s ALL=(ALL:ALL) NOPASSWD: ALL\n' "$user_name" > "$tmp"
visudo -cf "$tmp" >/dev/null
sudo install -m 0440 -o root -g root "$tmp" "$file"
if ! sudo visudo -cf /etc/sudoers >/dev/null; then
  sudo rm -f "$file"
  echo 'Sudoers validation failed. Change reverted.' >&2
  exit 1
fi
echo "Enabled passwordless sudo for $user_name. To undo: sudo rm '$file'"
