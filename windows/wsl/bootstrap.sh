#!/usr/bin/env bash
set -euo pipefail

DISTRO_USER="ningen"
REPOSITORY_URL="https://github.com/ningen/dotfiles.git"
REPOSITORY_DIR="$HOME/ghq/github.com/ningen/dotfiles"

if [[ "$(id -un)" != "$DISTRO_USER" ]]; then
  echo "Run this script as $DISTRO_USER, not $(id -un)." >&2
  exit 1
fi

echo '==> Updating Ubuntu bootstrap packages (sudo may ask for your Linux password)'
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y curl git ca-certificates xz-utils

if [[ "$(ps -p 1 -o comm=)" != systemd ]]; then
  echo 'systemd is not PID 1. Run wsl.exe --shutdown in Windows and rerun bootstrap.' >&2
  exit 1
fi

if ! command -v nix >/dev/null 2>&1 && [[ ! -e /nix/var/nix/profiles/default/bin/nix ]]; then
  echo '==> Installing Nix in multi-user mode'
  installer="$(mktemp)"
  trap 'rm -f "$installer"' EXIT
  curl --fail --location https://nixos.org/nix/install --output "$installer"
  sh "$installer" --daemon --yes
fi

if [[ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
  # shellcheck disable=SC1091
  source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi
command -v nix >/dev/null 2>&1 || { echo 'Nix is installed but unavailable. Restart WSL and rerun bootstrap.' >&2; exit 1; }
sudo systemctl start nix-daemon.service
systemctl is-active --quiet nix-daemon.service || { echo 'nix-daemon is not active. Restart WSL and rerun bootstrap.' >&2; exit 1; }

echo '==> Cloning or updating the WSL dotfiles checkout'
mkdir -p "$(dirname "$REPOSITORY_DIR")"
if [[ -d "$REPOSITORY_DIR/.git" ]]; then
  git -C "$REPOSITORY_DIR" pull --ff-only
else
  git clone --recurse-submodules "$REPOSITORY_URL" "$REPOSITORY_DIR"
fi
git -C "$REPOSITORY_DIR" submodule update --init --recursive

cd "$REPOSITORY_DIR"
echo '==> Applying Home Manager'
nix --extra-experimental-features 'nix-command flakes' run .#switch-wsl

echo '==> Validating and applying Unix dotfiles'
./setup-dotfiles.sh --dry-run
./setup-dotfiles.sh

echo '==> Verifying required CLI tools'
for command in zsh starship direnv tmux git gh ghq nvim emacs node python go; do
  command -v "$command" >/dev/null 2>&1 || { echo "Missing command after setup: $command" >&2; exit 1; }
done

echo 'WSL bootstrap completed successfully.'
