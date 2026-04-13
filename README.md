# libggml-cuda-bin

Binary-packaging repo for the Arch User Repository package
`libggml-cuda-bin`.

This repo builds a Linux `x86_64` release asset from upstream `ggml`, publishes
that asset on GitHub Releases, and keeps the AUR metadata in the same repo.

## Why this exists

`libggml-cuda-git` currently builds from source in the AUR. That is expensive
for CUDA users and slow for downstream consumers like `whisper.cpp-cuda`.

This repo packages a prebuilt install tree instead:

- broad CUDA compatibility by building with `GGML_NATIVE=OFF`
- base `x86-64` libraries plus `x86-64-v3` hwcaps libraries
- shared OpenBLAS, Vulkan, and CUDA backends
- AUR-friendly `-bin` layout backed by GitHub Releases

## Repository layout

- `PKGBUILD`: AUR package recipe
- `.SRCINFO`: generated AUR metadata
- `scripts/build-asset.sh`: build the staged `/usr` tree and archive it
- `scripts/smoke-asset.sh`: verify the built release asset contents
- `scripts/update-aur-metadata.sh`: update `pkgver`, `pkgrel`, checksum, and
  `.SRCINFO`
- `.github/workflows/release.yml`: manual build-and-release workflow
- `.github/workflows/validate.yml`: metadata and shell validation

## Release flow

1. Run the release workflow with the upstream `ggml` version and desired
   `pkgrel`.
2. The workflow builds `libggml-cuda-bin-<pkgver>-<pkgrel>-x86_64.tar.zst`.
3. The workflow smoke-tests the asset, rewrites `PKGBUILD` and `.SRCINFO`, and
   attaches the asset plus metadata files to a GitHub Release tagged
   `v<pkgver>-<pkgrel>`.
4. Review the generated `PKGBUILD` and `.SRCINFO`, then commit them and push
   the matching AUR update.

## Runtime contract

The packaged libraries are dynamically linked against Arch's CUDA toolkit and
driver libraries, so the package depends on:

- `cuda`
- `nvidia-utils`
- `openblas`
- `vulkan-icd-loader`
- `vulkan-driver`

