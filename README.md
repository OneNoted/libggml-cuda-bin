# libggml-cuda-bin

Binary-packaging repo for the Arch User Repository package
`libggml-cuda-bin`.

This repo builds a Linux `x86_64` release asset from upstream `ggml`, publishes
that asset on GitHub Releases, commits the matching metadata back to `main`,
and syncs the AUR package from the same GitHub-driven release flow.

## Why this exists

`libggml-cuda-git` currently builds from source in the AUR. That is expensive
for CUDA users and slow for downstream consumers like `whisper.cpp-cuda`.

This repo packages a prebuilt install tree instead:

- broad CUDA compatibility by building with `GGML_NATIVE=OFF`
- baseline `x86-64` shared libraries for the published release path
- shared OpenBLAS, Vulkan, and CUDA backends
- AUR-friendly `-bin` layout backed by GitHub Releases

## Repository layout

- `PKGBUILD`: AUR package recipe
- `.SRCINFO`: generated AUR metadata
- `scripts/build-asset.sh`: build the staged `/usr` tree and archive it
- `scripts/smoke-asset.sh`: verify the built release asset contents
- `scripts/detect-release.sh`: resolve the latest upstream release and decide
  whether a new package release is needed
- `scripts/publish-aur.sh`: publish a flat `PKGBUILD`/`.SRCINFO` snapshot to
  the AUR repo
- `scripts/update-aur-metadata.sh`: update `pkgver`, `pkgrel`, checksum, and
  `.SRCINFO`
- `.github/workflows/release.yml`: scheduled and manual GitHub-driven release
  workflow
- `.github/workflows/validate.yml`: metadata and shell validation

## Release flow

1. The release workflow polls the latest upstream `ggml` GitHub release on a
   schedule, or you can run it manually.
2. If upstream changed, or if a manual rebuild was forced, the workflow builds
   `libggml-cuda-bin-<pkgver>-<pkgrel>-x86_64.tar.zst`.
3. The workflow smoke-tests the asset, rewrites `PKGBUILD` and `.SRCINFO`,
   commits those metadata updates back to `main`, and publishes a GitHub
   Release tagged `v<pkgver>-<pkgrel>`.
4. The workflow then clones the existing AUR repo, replaces its contents with
   the flat `PKGBUILD`/`.SRCINFO` snapshot, and pushes the update to AUR.

To let GitHub Actions publish to AUR, add an `AUR_SSH_PRIVATE_KEY` repository
secret containing a private key authorized for the package on
`aur.archlinux.org`.

## Runtime contract

The packaged libraries are dynamically linked against Arch's CUDA toolkit and
driver libraries, so the package depends on:

- `cuda`
- `nvidia-utils`
- `openblas`
- `vulkan-icd-loader`
- `vulkan-driver`

## Performance note

The first release path intentionally builds only the baseline `x86-64` install
tree so GitHub-hosted CI can finish in a practical amount of time. If you want
to experiment with an additional `x86-64-v3` hwcaps tree locally, set
`LIBGGML_BUILD_X86_64_V3=true` when running `scripts/build-asset.sh`.

The published CI path pins CUDA code generation to
`75-real;80-real;86-real;89-real;120a-real` by default. That keeps the build
practical on GitHub-hosted runners while still covering Turing-through-Blackwell
cards. You can override that locally with `LIBGGML_CUDA_ARCHITECTURES=...`.
