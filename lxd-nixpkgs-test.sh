#!/usr/bin/env bash

set -euo pipefail

CONFIG="$HOME/.config/lxd-nixpkgs-test"
SELF=$(dirname "$(readlink -f "$0")")

exists() {
  if incus info "$1" 2>/dev/null >/dev/null; then
    return 0
  else
    return 1
  fi
}

die() {
  echo "ERROR: $*" >&2
}

running() {
  if incus info "$1" | grep "Status: RUNNING" 2>/dev/null >/dev/null; then
    return 0
  else
    return 1
  fi
}

cmd_create() {
  if exists "$1"; then
    # already created
    return 0
  fi

  PRP="$NIXPKGS/$1"

  incus launch images:nixos/unstable "$1" -c security.nesting=true
  incus config device add "$1" nixpkgs disk "source=$PRP" "path=/nix/var/nix/profiles/per-user/root/channels/nixpkgs"
  test -d "$PRP/config" || (cp -r "$SELF/inside" "$PRP/config" && chmod +w -R "$PRP/config")
  incus config device add "$1" shared disk "source=$CONFIG/shared" "path=/etc/nixos/shared"
  incus config device add "$1" config disk "source=$PRP/config" "path=/etc/nixos/config"
  sleep 3s # allow it to boot
  incus exec "$1" -- /run/current-system/sw/bin/sed "s|./lxd.nix|./lxd.nix ./config ./shared|g" -i /etc/nixos/configuration.nix
}

cmd_rebuild() {
  incus exec "$1" -- /bin/sh -l -c "nixos-rebuild switch -k"
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

  if ! exists "$C"; then
    die "Container does not exist"
  fi

  if ! running "$C"; then
    incus start "$C"
    sleep 3s
  fi

  if $REBUILD; then
    cmd_rebuild "$C"
  fi

  incus exec "$C" -- /run/current-system/sw/bin/bash
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
}

cmd_help() {
  cat "$SELF/help.txt" | sed "s|#SHAREDLOC#|$CONFIG/shared|g"
}

cmd_edit-shared() {
  "${EDITOR:+nano}" "$CONFIG/shared/default.nix"
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

cmd_u() {
  cmd_update "$@"
}

if [ -e "$CONFIG/config" ]; then
  . "$CONFIG/config"
fi

if [ -n "$(LC_ALL=C type -t cmd_$1)" ] && [ "$(LC_ALL=C type -t cmd_$1)" = function ]; then
  CMD="$1"
  shift
  "cmd_$CMD" "$@"
  exit 0
else
  cmd_help
  exit 2
fi
