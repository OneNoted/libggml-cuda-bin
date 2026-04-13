#!/usr/bin/env bash
set -euo pipefail

asset=${1:?usage: smoke-asset.sh <asset>}
root=$(mktemp -d)
trap 'rm -rf "$root"' EXIT

bsdtar -xf "$asset" -C "$root"

required_paths=(
  "usr/include/ggml.h"
  "usr/lib/cmake/ggml/ggml-config.cmake"
  "usr/lib/libggml.so"
  "usr/lib/libggml-base.so"
  "usr/lib/libggml-cpu.so"
  "usr/lib/libggml-cuda.so"
  "usr/share/licenses/libggml-cuda-bin/LICENSE"
)

for path in "${required_paths[@]}"; do
  if [[ ! -e "$root/$path" ]]; then
    printf 'missing required path: %s\n' "$path" >&2
    exit 1
  fi
done

if [[ ! -d "$root/usr/lib/glibc-hwcaps/x86-64-v3" ]]; then
  printf 'missing x86-64-v3 hwcaps directory\n' >&2
  exit 1
fi

readelf -d "$root/usr/lib/libggml-cuda.so" | grep -Eq 'libcudart|libcublas'
printf 'Asset smoke check passed for %s\n' "$asset"

