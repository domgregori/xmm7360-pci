#!/bin/bash

set -euo pipefail

SCRIPT_PATH=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
REPO_ROOT=$(readlink -f "$SCRIPT_DIR/..")

PACKAGE_NAME="xmm7360-pci"

cleanup_dir() {
  local dir=${1:-}

  if [[ -n "$dir" && -d "$dir" ]]; then
    rm -rf "$dir"
  fi
}

usage() {
  cat <<'EOF'
Usage: ./scripts/dkms.sh <install|remove|status|version>

Commands:
  install  Copy the current checkout into /usr/src and register it with DKMS
  remove   Remove the current checkout version from DKMS and /usr/src
  status   Show DKMS status for xmm7360-pci
  version  Print the DKMS package version derived from git
EOF
}

package_version() {
  local version

  version=$(git -C "$REPO_ROOT" describe --always --dirty --abbrev=12 2>/dev/null || true)
  if [[ -z "$version" ]]; then
    version=$(git -C "$REPO_ROOT" rev-parse --short=12 HEAD 2>/dev/null || true)
  fi
  if [[ -z "$version" ]]; then
    echo "failed to derive package version from git" >&2
    exit 1
  fi

  version=${version//[[:space:]]/}
  echo "${version//\//_}"
}

copy_source_tree() {
  local destination=$1

  mkdir -p "$destination"
  tar \
    --exclude=.git \
    --exclude='*.o' \
    --exclude='*.ko' \
    --exclude='*.mod' \
    --exclude='*.mod.c' \
    --exclude='*.symvers' \
    --exclude='.*.cmd' \
    --exclude='modules.order' \
    --exclude='Module.symvers' \
    --exclude='dmesg.log' \
    -cf - \
    -C "$REPO_ROOT" . | tar -xf - -C "$destination"
}

install_dkms() {
  local version install_root staging_root

  version=$(package_version)
  install_root="/usr/src/$PACKAGE_NAME-$version"
  staging_root=$(mktemp -d)
  trap 'cleanup_dir "'"$staging_root"'"' EXIT

  copy_source_tree "$staging_root/$PACKAGE_NAME-$version"
  sed "s/COMMIT_ID_VERSION/$version/g" "$REPO_ROOT/dkms.tmpl.conf" > "$staging_root/$PACKAGE_NAME-$version/dkms.conf"

  sudo dkms remove "$PACKAGE_NAME/$version" --all >/dev/null 2>&1 || true
  sudo rm -rf "$install_root"
  sudo mkdir -p "$install_root"
  sudo cp -r "$staging_root/$PACKAGE_NAME-$version/." "$install_root/"
  sudo dkms install "$PACKAGE_NAME/$version"
}

remove_dkms() {
  local version install_root

  version=$(package_version)
  install_root="/usr/src/$PACKAGE_NAME-$version"

  sudo dkms remove "$PACKAGE_NAME/$version" --all
  sudo rm -rf "$install_root"
}

status_dkms() {
  dkms status -m "$PACKAGE_NAME" || true
}

case "${1:-}" in
  install)
    install_dkms
    ;;
  remove)
    remove_dkms
    ;;
  status)
    status_dkms
    ;;
  version)
    package_version
    ;;
  *)
    usage
    exit 1
    ;;
esac
