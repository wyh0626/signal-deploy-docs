#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"
DESKTOP_DIR="${ROOT_DIR}/upstream/Signal-Desktop"

if [[ ! -f "${ENV_FILE}" ]]; then
  cp "${ROOT_DIR}/.env.example" "${ENV_FILE}"
fi

# shellcheck disable=SC1090
source "${ENV_FILE}"

if ! curl -fsS "http://localhost:${SIGNAL_ADMIN_PORT:-8091}/healthcheck" >/dev/null 2>&1; then
  echo "Backend is not healthy; starting the dev stack first..."
  "${ROOT_DIR}/scripts/dev-up.sh"
fi

"${ROOT_DIR}/scripts/bootstrap-upstream.sh" --include-desktop

if [[ -s "${HOME}/.nvm/nvm.sh" ]]; then
  # shellcheck disable=SC1090
  source "${HOME}/.nvm/nvm.sh"
  nvm use >/dev/null || true
fi

command -v node >/dev/null 2>&1 || { echo "Missing node" >&2; exit 1; }
command -v pnpm >/dev/null 2>&1 || { echo "Missing pnpm" >&2; exit 1; }

cd "${DESKTOP_DIR}"

pnpm install --ignore-scripts
node node_modules/electron/install.js

RINGRTC_DIR="$(node -p "require('path').dirname(require.resolve('@signalapp/ringrtc/package.json'))")"
(
  cd "${RINGRTC_DIR}"
  npm_package_json="${PWD}/package.json" \
    npm_package_version="$(node -p "require('./package.json').version")" \
    node scripts/fetch-prebuild.js
)

FS_XATTR_DIR="$(node -p "require('path').dirname(require.resolve('fs-xattr/package.json'))")"
(
  cd "${FS_XATTR_DIR}"
  npx node-gyp rebuild || true
)

pnpm run generate

exec bash ./scripts/start-local-dev.sh
