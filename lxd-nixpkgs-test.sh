#!/usr/bin/env bash

set -euo pipefail

CONFIG="$HOME/.config/lxd-nixpkgs-test"
SELF=$(dirname "$(readlink -f "$0")")

cmd_create() {
  if lxc info "$1" 2>/dev/null >/dev/null; then
    # already created
    return 0
  fi

  PRP="$NIXPKGS/$1"

  lxc launch nixos "$1" -c security.nesting=true
  lxc config device add "$1" nixpkgs disk "source=$PRP" "path=/nix/var/nix/profiles/per-user/root/channels/nixpkgs"
  test -d "$PRP/config" || (cp -r "$SELF/inside" "$PRP/config")
  lxc config device add "$1" shared disk "source=$CONFIG/shared" "path=/etc/nixos/shared"
  lxc config device add "$1" config disk "source=$PRP/config" "path=/etc/nixos/config"
  lxc exec "$1" -- /run/current-system/sw/bin/sed "s|./lxd.nix|./lxd.nix ./config ./shared|g" -i /etc/nixos/configuration.nix
  lxc exec "$1" -- /run/current-system/sw/bin/sed "s|../../../modules/virtualisation/lxc-container.nix|<nixpkgs/nixos/modules/virtualisation/lxc-container.nix>|g" -i /etc/nixos/configuration.nix
  cmd_rebuild "$1"
}

cmd_rebuild() {
  lxc exec "$1" -- /bin/sh -l -c "nixos-rebuild switch -k"
}

cmd_enter() {
  REBUILD=false
  CREATE=true

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -c | --create)
        CREATE=true
        ;;
      --no-create)
        CREATE=false
        ;;
      -r | --rebuild)
        REBUILD=true
        ;;
      --no-rebuild)
        REBUILD=false
        ;;
      *)
        if [ -e "$NIXPKGS/$1" ]; then
          C="$1"
        else
          echo "unknown option $1" >&2
          exit 2
        fi
        ;;
    esac
    shift
  done

  if $CREATE; then
    cmd_create "$C"
  fi

  if $REBUILD; then
    cmd_rebuild "$C"
  fi

  lxc exec "$C" -- /run/current-system/sw/bin/bash
}

cmd_init() {
  mkdir -p "$CONFIG"
  if [ $# -gt 0 ]; then
    NIXPKGS="$1"
  else
    read -p "Location of nixpkgs: " NIXPKGS
  fi

  echo "NIXPKGS=$NIXPKGS" > "$CONFIG/config"

  if [ ! -e "$CONFIG/shared" ]; then
    echo "Creating shared config at $CONFIG/shared"
    cp -r "$SELF/shared" "$CONFIG/shared"
  fi

  cmd_update
}

get_build() {
  # it could happen that we fetch a different build for image and meta but usually that's rare and if it happens meta usually works regardless
  BUILD=$(curl -s "https://hydra.nixos.org/job/nixos/trunk-combined/nixos.$1.x86_64-linux" | grep 'alt="Succeeded"' | head -n 1 | grep -o "https://[0-9a-z/.]*" | tail -n 1)
  curl -s "$BUILD" | grep -o "$BUILD/download/[a-z0-9/._-]*" | head -n 1
}

dl() {
  wget "$(get_build "$1")" -O "$2"
}

cmd_update() {
  echo "Updating nixos image from hydra..."

  TMP=$(mktemp -d)

  cleanup() {
    rm -rf "$TMP"
  }

  trap cleanup EXIT

  pushd "$TMP"

  dl lxdImage image.tar.xz
  dl lxdMeta meta.tar.xz

  lxc image import meta.tar.xz image.tar.xz --alias nixos
}

cmd_help() {
  cat "$SELF/help.txt" | sed "s|#SHAREDLOC#|$CONFIG/shared|g"
}

if [ $# -lt 1 ]; then
  cmd_help
  exit 2
fi

if [ ! -e "$CONFIG/config" ] && [ "$1" != "init" ]; then
  echo "Needs to be initialized first. Run \$ $0 init <location-of-nixpkgs>" >&2
  exit 1
fi

cmd_e() {
  cmd_enter "$@"
}

cmd_i() {
  cmd_init "$@"
}

cmd_c() {
  cmd_create "$@"
}

cmd_update() {
  cmd_update "$@"
}

. "$CONFIG/config"

if [ -n "$(LC_ALL=C type -t cmd_$1)" ] && [ "$(LC_ALL=C type -t cmd_$1)" = function ]; then
  CMD="$1"
  shift
  "cmd_$CMD" "$@"
  exit 0
else
  cmd_help
  exit 2
fi
