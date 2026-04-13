#!/usr/bin/env bash
set -euo pipefail

pkgver=${1:?usage: build-asset.sh <pkgver> <pkgrel> [out-dir]}
pkgrel=${2:?usage: build-asset.sh <pkgver> <pkgrel> [out-dir]}
out_dir=${3:-"$PWD/dist"}

pkgname="libggml-cuda-bin"
upstream_repo="https://github.com/ggml-org/ggml"
work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT

src_dir="$work_dir/ggml-$pkgver"
base_stage="$work_dir/stage/base"
install_root="$work_dir/install-root"
asset_name="${pkgname}-${pkgver}-${pkgrel}-x86_64.tar.zst"
asset_path="${out_dir}/${asset_name}"
build_x86_64_v3=${LIBGGML_BUILD_X86_64_V3:-false}
cuda_architectures=${LIBGGML_CUDA_ARCHITECTURES:-75-real;80-real;86-real;89-real;120a-real}

mkdir -p "$out_dir" "$base_stage" "$install_root"

# Arch's cuda package installs nvcc under /opt/cuda/bin but does not expose it
# in non-login CI shells.
if [[ -x /opt/cuda/bin/nvcc ]]; then
  export PATH="/opt/cuda/bin:${PATH}"
  : "${CUDAToolkit_ROOT:=/opt/cuda}"
  export CUDAToolkit_ROOT
fi

curl -fsSL "${upstream_repo}/archive/refs/tags/v${pkgver}.tar.gz" | tar -xz -C "$work_dir"

# Allow the build script to control the CPU baseline explicitly.
sed -E -i '/(set|APPEND).ARCH_FLAGS/d' "$src_dir/src/ggml-cpu/CMakeLists.txt"

cmake_common=(
  -S "$src_dir"
  -G Ninja
  -DCMAKE_BUILD_TYPE=None
  -DCMAKE_INSTALL_PREFIX=/usr
  "-DCMAKE_CUDA_ARCHITECTURES=${cuda_architectures}"
  -DGGML_NATIVE=OFF
  -DGGML_LTO=ON
  -DGGML_RPC=ON
  -DGGML_ALL_WARNINGS=OFF
  -DGGML_ALL_WARNINGS_3RD_PARTY=OFF
  -DGGML_BLAS=ON
  -DGGML_BLAS_VENDOR=OpenBLAS
  -DGGML_CUDA=ON
  -DGGML_CUDA_F16=ON
  -DGGML_VULKAN=ON
  -DGGML_STATIC=OFF
  -DBUILD_SHARED_LIBS=ON
  -Wno-dev
)

base_cflags=$(sed -E -e 's&-(march|mtune)=\S+\b&&g' -e 's&-O[0-9]+\b&&g' <<<"${CFLAGS:-}")
base_cxxflags=$(sed -E -e 's&-(march|mtune)=\S+\b&&g' -e 's&-O[0-9]+\b&&g' <<<"${CXXFLAGS:-}")

build_variant() {
  local arch=$1
  local libdir=$2
  local build_dir="$work_dir/build_${arch//-/_}"
  local dest_dir=$3

  CFLAGS="${base_cflags} -march=${arch} -O3" \
  CXXFLAGS="${base_cxxflags} -march=${arch} -O3" \
    cmake -B "$build_dir" "${cmake_common[@]}" -DCMAKE_INSTALL_LIBDIR="$libdir"

  cmake --build "$build_dir"
  DESTDIR="$dest_dir" cmake --install "$build_dir"
}

build_variant "x86-64" "lib" "$base_stage"

cp -a "$base_stage/." "$install_root/"

if [[ "$build_x86_64_v3" == true ]]; then
  v3_stage="$work_dir/stage/x86-64-v3"
  mkdir -p "$v3_stage"
  build_variant "x86-64-v3" "lib/glibc-hwcaps/x86-64-v3" "$v3_stage"

  if [[ -d "$v3_stage/usr/lib/glibc-hwcaps" ]]; then
    mkdir -p "$install_root/usr/lib/glibc-hwcaps"
    cp -a "$v3_stage/usr/lib/glibc-hwcaps/." "$install_root/usr/lib/glibc-hwcaps/"
  fi
fi

rm -rf "$install_root/usr/lib/glibc-hwcaps"/*/cmake
rm -rf "$install_root/usr/share/licenses/ggml" "$install_root/usr/share/licenses/libggml"
install -Dm644 "$src_dir/LICENSE" "$install_root/usr/share/licenses/$pkgname/LICENSE"

TZ=UTC LC_ALL=C tar \
  --sort=name \
  --mtime='UTC 1970-01-01' \
  --owner=0 \
  --group=0 \
  --numeric-owner \
  --zstd \
  -cf "$asset_path" \
  -C "$install_root" \
  usr

sha256sum "$asset_path" > "${asset_path}.sha256"
printf 'Built %s\n' "$asset_path"
