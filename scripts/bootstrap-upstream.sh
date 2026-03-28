#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSIONS_FILE="${ROOT_DIR}/versions/current.env"
UPSTREAM_DIR="${ROOT_DIR}/upstream"
INCLUDE_DESKTOP=0

for arg in "$@"; do
  case "$arg" in
    --include-desktop)
      INCLUDE_DESKTOP=1
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      exit 1
      ;;
  esac
done

if [[ ! -f "${VERSIONS_FILE}" ]]; then
  echo "Missing ${VERSIONS_FILE}" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "${VERSIONS_FILE}"

mkdir -p "${UPSTREAM_DIR}"

repo_has_expected_patchset() {
  local name="$1"
  local repo_dir="$2"
  local patch_dir=

  case "${name}" in
    Signal-Server)
      patch_dir="${ROOT_DIR}/patches/Signal-Server"
      ;;
    Signal-Desktop)
      patch_dir="${ROOT_DIR}/patches/Signal-Desktop"
      ;;
    *)
      return 1
      ;;
  esac

  local found_patch=0
  local patch_file
  for patch_file in "${patch_dir}"/*.patch; do
    [[ -e "${patch_file}" ]] || continue
    found_patch=1
    if ! git -C "${repo_dir}" apply --reverse --check "${patch_file}" >/dev/null 2>&1; then
      return 1
    fi
  done

  [[ "${found_patch}" == "1" ]]
}

ensure_repo() {
  local name="$1"
  local repo_url="$2"
  local ref="$3"
  local commit="$4"
  local repo_dir="${UPSTREAM_DIR}/${name}"

  if [[ ! -d "${repo_dir}/.git" ]]; then
    echo "[clone] ${name} -> ${repo_url}"
    git clone --filter=blob:none "${repo_url}" "${repo_dir}"
  fi

  if [[ -n "$(git -C "${repo_dir}" status --porcelain)" ]]; then
    if repo_has_expected_patchset "${name}" "${repo_dir}"; then
      echo "[ok] ${name} already has the local dev patchset applied"
      return
    fi
    echo "[skip]  ${name} has unexpected local changes; keeping current worktree" >&2
    return 0
  fi

  echo "[fetch] ${name}"
  git -C "${repo_dir}" fetch --tags origin

  local current_commit
  current_commit="$(git -C "${repo_dir}" rev-parse --short=12 HEAD)"
  if [[ "${current_commit}" != "${commit}" ]]; then
    echo "[checkout] ${name} -> ${ref} (${commit})"
    git -C "${repo_dir}" checkout --detach "${commit}"
  else
    echo "[ok] ${name} already at ${ref} (${commit})"
  fi
}

ensure_repo "Signal-Server" "${SIGNAL_SERVER_REPO}" "${SIGNAL_SERVER_REF}" "${SIGNAL_SERVER_COMMIT}"
ensure_repo "registration-service" "${REGISTRATION_SERVICE_REPO}" "${REGISTRATION_SERVICE_REF}" "${REGISTRATION_SERVICE_COMMIT}"

if [[ "${INCLUDE_DESKTOP}" == "1" ]]; then
  ensure_repo "Signal-Desktop" "${SIGNAL_DESKTOP_REPO}" "${SIGNAL_DESKTOP_REF}" "${SIGNAL_DESKTOP_COMMIT}"
fi

"${ROOT_DIR}/scripts/apply-local-patches.sh"

echo
echo "Upstream repositories are ready."
