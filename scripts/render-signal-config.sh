#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE_FILE="${ROOT_DIR}/deploy/config/signal-server.yml.tmpl"
OUTPUT_FILE="${ROOT_DIR}/deploy/generated/signal-server.yml"
UPSTREAM_TEST_CONFIG="${ROOT_DIR}/upstream/Signal-Server/service/src/test/resources/config/test.yml"
ENV_FILE="${ROOT_DIR}/.env"

if [[ ! -f "${UPSTREAM_TEST_CONFIG}" ]]; then
  echo "Missing ${UPSTREAM_TEST_CONFIG}" >&2
  echo "Run: ./scripts/bootstrap-upstream.sh" >&2
  exit 1
fi

SIGNAL_HTTPS_PORT=9443
if [[ -f "${ENV_FILE}" ]]; then
  # shellcheck disable=SC1090
  source "${ENV_FILE}"
fi

ZK_SERVER_PUBLIC="$(
  python3 - "${UPSTREAM_TEST_CONFIG}" <<'PY'
import pathlib
import re
import sys

config = pathlib.Path(sys.argv[1]).read_text()
match = re.search(r'(?m)^\s{2}serverPublic:\s*(\S+)\s*$', config)
if not match:
    raise SystemExit("Could not find zkConfig.serverPublic in upstream test config")
print(match.group(1))
PY
)"

PUBLIC_HTTPS_BASE_URL="https://localhost:${SIGNAL_HTTPS_PORT:-9443}"

mkdir -p "$(dirname "${OUTPUT_FILE}")"

python3 - "${TEMPLATE_FILE}" "${OUTPUT_FILE}" "${ZK_SERVER_PUBLIC}" "${PUBLIC_HTTPS_BASE_URL}" <<'PY'
import pathlib
import sys

template_path = pathlib.Path(sys.argv[1])
output_path = pathlib.Path(sys.argv[2])
server_public = sys.argv[3]
public_https_base_url = sys.argv[4]

contents = template_path.read_text()
contents = contents.replace("__ZK_SERVER_PUBLIC__", server_public)
contents = contents.replace("__PUBLIC_HTTPS_BASE_URL__", public_https_base_url)
output_path.write_text(contents)
PY

echo "Rendered ${OUTPUT_FILE}"
