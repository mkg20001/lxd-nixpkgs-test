#!/bin/sh

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <worktree>" >&2
  exit 2
fi

if lxc info "$1" 2>/dev/null >/dev/null; then
  # already created, just enter it
  lxc exec "$1" /run/current-system/sw/bin/bash
fi

NIXPKGS="/home/maciej/Projekte/nixpkgsv"
SELF=$(dirname "$(readlink -f "$0")")

PRP="$NIXPKGS/$1"

lxc launch nixos "$1" -c security.nesting=true
lxc config device add "$1" nixpkgs disk "source=$PRP" "path=/nix/var/nix/profiles/per-user/root/channels/nixpkgs"
test -d "$PRP/config" || (cp -r "$SELF/inside" "$PRP/config")
lxc config device add "$1" shared disk "source=$SELF/shared" "path=/etc/nixos/shared"
lxc config device add "$1" config disk "source=$PRP/config" "path=/etc/nixos/config"
lxc exec "$1" -- /run/current-system/sw/bin/sed "s|./lxd.nix|./lxd.nix ./config ./shared|g" -i /etc/nixos/configuration.nix
lxc exec "$1" -- /run/current-system/sw/bin/sed "s|../../../modules/virtualisation/lxc-container.nix|<nixpkgs/nixos/modules/virtualisation/lxc-container.nix>|g" -i /etc/nixos/configuration.nix
lxc exec "$1" -- /bin/sh -l -c "nixos-rebuild switch -k"
