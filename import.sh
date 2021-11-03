#!/bin/sh

set -euo pipefail

get_build() {
  # it could happen that we fetch a different build for image and meta but usually that's rare and if it happens meta usually works regardless
  BUILD=$(curl -s "https://hydra.nixos.org/job/nixos/trunk-combined/nixos.$1.x86_64-linux" | grep 'alt="Succeeded"' | head -n 1 | grep -o "https://[0-9a-z/.]*" | tail -n 1)
  curl -s "$BUILD" | grep -o "$BUILD/download/[a-z0-9/._-]*" | head -n 1
}

dl() {
  wget "$(get_build "$1")" -O "$2"
}

TMP=$(mktemp -d)

cleanup() {
  rm -rf "$TMP"
}

trap cleanup EXIT

pushd "$TMP"

dl lxdImage image.tar.xz
dl lxdMeta meta.tar.xz

lxc image import meta.tar.xz image.tar.xz --alias nixos
