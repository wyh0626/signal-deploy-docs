#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"
COMPOSE_FILE="${ROOT_DIR}/deploy/docker-compose.yml"
GENERATED_DIR="${ROOT_DIR}/deploy/generated"

if [[ ! -f "${ENV_FILE}" ]]; then
  cp "${ROOT_DIR}/.env.example" "${ENV_FILE}"
  echo "Created ${ENV_FILE} from .env.example"
fi

# shellcheck disable=SC1090
source "${ENV_FILE}"

if ! docker info >/dev/null 2>&1; then
  echo "Docker daemon is not running." >&2
  exit 1
fi

"${ROOT_DIR}/scripts/bootstrap-upstream.sh"
"${ROOT_DIR}/scripts/render-signal-config.sh"

mkdir -p "${GENERATED_DIR}"

if [[ ! -f "${GENERATED_DIR}/secrets-bundle.yml" ]]; then
  "${ROOT_DIR}/scripts/generate-secrets.sh" > "${GENERATED_DIR}/secrets-bundle.yml"
  echo "Generated ${GENERATED_DIR}/secrets-bundle.yml"
fi

if [[ ! -f "${GENERATED_DIR}/localhost-keystore.p12" ]]; then
  "${ROOT_DIR}/scripts/generate-localhost-cert.sh"
fi

docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" up -d --build

HEALTH_URL="http://localhost:${SIGNAL_ADMIN_PORT:-8091}/healthcheck"
echo "Waiting for Signal-Server health at ${HEALTH_URL} ..."

for _ in $(seq 1 180); do
  if curl -fsS "${HEALTH_URL}" >/dev/null 2>&1; then
    echo
    echo "Signal local dev stack is ready."
    echo "API:        http://localhost:${SIGNAL_API_PORT:-8090}"
    echo "HTTPS API:  https://localhost:${SIGNAL_HTTPS_PORT:-9443}"
    echo "Admin:      ${HEALTH_URL}"
    echo "MinIO:      http://localhost:${MINIO_CONSOLE_PORT:-9001}"
    echo
    echo "Verification code rule: phone last 6 digits"
    echo "Captcha token: noop.noop.registration.localtest"
    exit 0
  fi
  sleep 5
  printf '.'
done

echo
echo "Signal-Server did not become healthy in time." >&2
docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" ps >&2
docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" logs --tail=200 signal-server >&2 || true
exit 1
