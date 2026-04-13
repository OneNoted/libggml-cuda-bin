#!/usr/bin/env bash
set -euo pipefail

pkgver=${1:?usage: update-aur-metadata.sh <pkgver> <pkgrel> <asset>}
pkgrel=${2:?usage: update-aur-metadata.sh <pkgver> <pkgrel> <asset>}
asset=${3:?usage: update-aur-metadata.sh <pkgver> <pkgrel> <asset>}
checksum=$(sha256sum "$asset" | awk '{print $1}')

perl -0pi -e "s/^pkgver=.*/pkgver=${pkgver}/m; s/^pkgrel=.*/pkgrel=${pkgrel}/m; s/^sha256sums=\('[^']*'\)/sha256sums=('${checksum}')/m" PKGBUILD
makepkg --printsrcinfo > .SRCINFO

printf 'Updated PKGBUILD and .SRCINFO for %s-%s\n' "$pkgver" "$pkgrel"

