#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"
COMPOSE_FILE="${ROOT_DIR}/deploy/docker-compose.yml"

if [[ ! -f "${ENV_FILE}" ]]; then
  cp "${ROOT_DIR}/.env.example" "${ENV_FILE}"
fi

# shellcheck disable=SC1090
source "${ENV_FILE}"

if ! "${ROOT_DIR}/scripts/docker-ready.sh" 10; then
  exit 1
fi

docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" ps
echo
curl -fsS "http://localhost:${SIGNAL_ADMIN_PORT:-8091}/healthcheck" && echo || true
