#!/usr/bin/env bash
set -Eeuo pipefail
user_name="$(id -un)"
[[ "$user_name" =~ ^[a-z_][a-z0-9_-]*[$]?$ ]] || exit 1
file="/etc/sudoers.d/90-${user_name}-nopasswd"
if [[ -e "$file" ]]; then
  sudo rm -- "$file"
  echo 'Removed passwordless sudo override.'
else
  echo 'No passwordless sudo override created by these dotfiles was found.'
fi
