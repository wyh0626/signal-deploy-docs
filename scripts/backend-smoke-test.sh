#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"

if [[ ! -f "${ENV_FILE}" ]]; then
  cp "${ROOT_DIR}/.env.example" "${ENV_FILE}"
fi

# shellcheck disable=SC1090
source "${ENV_FILE}"

command -v curl >/dev/null 2>&1 || { echo "Missing curl" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "Missing python3" >&2; exit 1; }

API_BASE_URL="http://localhost:${SIGNAL_API_PORT:-8090}"
ADMIN_URL="http://localhost:${SIGNAL_ADMIN_PORT:-8091}/healthcheck"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

suffix="$(printf '%04d' $(( ( $(date +%s) + $$ ) % 10000 )))"
phone_number="${SIGNAL_SMOKE_TEST_NUMBER:-+1415555${suffix}}"
phone_digits="$(printf '%s' "${phone_number}" | tr -cd '0-9')"
verification_code="${phone_digits: -6}"

request_json() {
  local method="$1"
  local url="$2"
  local payload="$3"
  local output_file="$4"

  curl -sS -o "${output_file}" -w '%{http_code}' \
    -X "${method}" \
    -H 'Content-Type: application/json' \
    -H 'User-Agent: signal-deploy-docs-smoke/1.0' \
    -H 'X-Forwarded-For: 127.0.0.1' \
    --data "${payload}" \
    "${url}"
}

json_field() {
  local file="$1"
  local field="$2"

  python3 - "${file}" "${field}" <<'PY'
import json
import pathlib
import sys

body_path = pathlib.Path(sys.argv[1])
field = sys.argv[2]
data = json.loads(body_path.read_text())
value = data
for part in field.split("."):
    value = value[part]
if isinstance(value, bool):
    print("true" if value else "false")
else:
    print(value)
PY
}

assert_status() {
  local actual="$1"
  local expected="$2"
  local step="$3"
  local body_file="$4"

  if [[ "${actual}" != "${expected}" ]]; then
    echo "[fail] ${step}: expected HTTP ${expected}, got ${actual}" >&2
    cat "${body_file}" >&2
    exit 1
  fi
}

curl -fsS "${ADMIN_URL}" >/dev/null

echo "[smoke] phone number: ${phone_number}"
echo "[smoke] verification code: ${verification_code}"

create_body="${TMP_DIR}/create.json"
create_status="$(
  request_json \
    "POST" \
    "${API_BASE_URL}/v1/verification/session" \
    "{\"number\":\"${phone_number}\"}" \
    "${create_body}"
)"
assert_status "${create_status}" "200" "create verification session" "${create_body}"
session_id="$(json_field "${create_body}" "id")"

patch_body="${TMP_DIR}/patch.json"
patch_status="$(
  request_json \
    "PATCH" \
    "${API_BASE_URL}/v1/verification/session/${session_id}" \
    "{\"captcha\":\"noop.noop.registration.localtest\"}" \
    "${patch_body}"
)"
assert_status "${patch_status}" "200" "submit captcha" "${patch_body}"

allowed_after_captcha="$(json_field "${patch_body}" "allowedToRequestCode")"
if [[ "${allowed_after_captcha}" != "true" ]]; then
  echo "[fail] submit captcha: allowedToRequestCode should be true" >&2
  cat "${patch_body}" >&2
  exit 1
fi

code_request_body="${TMP_DIR}/request-code.json"
code_request_status="$(
  request_json \
    "POST" \
    "${API_BASE_URL}/v1/verification/session/${session_id}/code" \
    '{"transport":"sms","client":"android"}' \
    "${code_request_body}"
)"
assert_status "${code_request_status}" "200" "request verification code" "${code_request_body}"

verify_body="${TMP_DIR}/verify.json"
verify_status="$(
  request_json \
    "PUT" \
    "${API_BASE_URL}/v1/verification/session/${session_id}/code" \
    "{\"code\":\"${verification_code}\"}" \
    "${verify_body}"
)"
assert_status "${verify_status}" "200" "submit verification code" "${verify_body}"

verified="$(json_field "${verify_body}" "verified")"
if [[ "${verified}" != "true" ]]; then
  echo "[fail] submit verification code: verified should be true" >&2
  cat "${verify_body}" >&2
  exit 1
fi

echo
echo "Backend smoke test passed."
echo "Session: ${session_id}"
echo "Phone:   ${phone_number}"
