#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

apply_patch_if_needed() {
  local repo_dir="$1"
  local patch_file="$2"

  if [[ ! -d "${repo_dir}/.git" ]]; then
    return
  fi

  if git -C "${repo_dir}" apply --reverse --check "${patch_file}" >/dev/null 2>&1; then
    echo "[ok] patch already applied: $(basename "${patch_file}")"
    return
  fi

  echo "[patch] $(basename "${patch_file}")"
  git -C "${repo_dir}" apply --check "${patch_file}"
  git -C "${repo_dir}" apply "${patch_file}"
}

for patch_file in "${ROOT_DIR}"/patches/Signal-Server/*.patch; do
  [[ -e "${patch_file}" ]] || continue
  apply_patch_if_needed "${ROOT_DIR}/upstream/Signal-Server" "${patch_file}"
done

for patch_file in "${ROOT_DIR}"/patches/Signal-Desktop/*.patch; do
  [[ -e "${patch_file}" ]] || continue
  apply_patch_if_needed "${ROOT_DIR}/upstream/Signal-Desktop" "${patch_file}"
done
