# Maintainer: OneNoted <38808968+OneNoted@users.noreply.github.com>

pkgname=libggml-cuda-bin
_upstream_pkgname=ggml
pkgver=0.9.11
pkgrel=1
pkgdesc="Tensor library for machine learning with OpenBLAS, Vulkan, and CUDA"
arch=('x86_64')
url="https://github.com/OneNoted/libggml-cuda-bin"
license=('MIT')
depends=(
  'cuda'
  'nvidia-utils'
  'openblas'
  'vulkan-driver'
  'vulkan-icd-loader'
)
provides=(
  "libggml=${pkgver}"
  "libggml-cuda-git=${pkgver}"
)
conflicts=(
  'libggml'
  'libggml-cuda-git'
)

_asset_name="${pkgname}-${pkgver}-${pkgrel}-x86_64.tar.zst"
source=(
  "${_asset_name}::${url}/releases/download/v${pkgver}-${pkgrel}/${_asset_name}"
)
sha256sums=('__SHA256__')

package() {
  bsdtar -xf "${srcdir}/${_asset_name}" -C "${pkgdir}"
}

