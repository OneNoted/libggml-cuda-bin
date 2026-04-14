# libggml-cuda-bin

Binary AUR packaging repo for `libggml-cuda-bin`.

This repo builds a precompiled `x86_64` ggml install tree with CUDA, OpenBLAS,
and Vulkan, publishes it on GitHub Releases, and syncs the AUR package from the
same workflow.

## Release flow

- `validate.yml` checks packaging metadata
- `release.yml` tracks upstream `ggml` releases
- when a release is needed, it builds and smoke-tests
  `libggml-cuda-bin-<pkgver>-<pkgrel>-x86_64.tar.zst`
- the workflow updates `PKGBUILD` and `.SRCINFO`, commits them to `main`,
  publishes the GitHub release, and pushes the flat AUR snapshot

## Package details

- target: `x86_64`
- backends: CUDA, OpenBLAS, Vulkan
- runtime deps: `cuda`, `nvidia-utils`, `openblas`, `vulkan-icd-loader`,
  `vulkan-driver`
- default CUDA archs:
  `75-real;80-real;86-real;89-real;120a-real`

## Maintainer

Jonatan Jonasson `<notes@madeingotland.com>`

GitHub AUR publishing requires an `AUR_SSH_PRIVATE_KEY` repository secret.
