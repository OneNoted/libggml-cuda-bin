#!/usr/bin/env bash
set -euo pipefail

if [[ $# -eq 0 ]]; then
  printf 'usage: %s <shell-command>\n' "${0##*/}" >&2
  exit 1
fi

image=${ARCH_CONTAINER_IMAGE:-archlinux:base-devel}
workspace=/workspace
container_command=$*

container_prelude='set -euo pipefail'

if [[ -n "${ARCH_SNAPSHOT_DATE:-}" ]]; then
  snapshot_date=${ARCH_SNAPSHOT_DATE//-//}

  if [[ ! $snapshot_date =~ ^[0-9]{4}/[0-9]{2}/[0-9]{2}$ ]]; then
    printf 'ARCH_SNAPSHOT_DATE must use YYYY/MM/DD or YYYY-MM-DD, got: %s\n' "$ARCH_SNAPSHOT_DATE" >&2
    exit 1
  fi

  container_prelude=$(cat <<EOF
${container_prelude}
printf 'Using Arch Linux Archive snapshot %s\n' '${snapshot_date}'
printf 'Server = https://archive.archlinux.org/repos/${snapshot_date}/\$repo/os/\$arch\n' > /etc/pacman.d/mirrorlist
EOF
)
fi

container_command=$(cat <<EOF
${container_prelude}
${container_command}
EOF
)

docker run --rm \
  --network host \
  --volume "$PWD":"$workspace" \
  --workdir "$workspace" \
  --env CI=true \
  --env HOME=/tmp/home \
  --env ARCH_SNAPSHOT_DATE \
  "$image" \
  bash -lc "$container_command"
