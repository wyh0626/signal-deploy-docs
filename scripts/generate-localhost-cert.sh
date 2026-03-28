#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GENERATED_DIR="${ROOT_DIR}/deploy/generated"
KEY_PATH="${GENERATED_DIR}/localhost-key.pem"
CERT_PATH="${GENERATED_DIR}/localhost-cert.pem"
P12_PATH="${GENERATED_DIR}/localhost-keystore.p12"

mkdir -p "${GENERATED_DIR}"

openssl req \
  -x509 \
  -newkey ec \
  -pkeyopt ec_paramgen_curve:prime256v1 \
  -nodes \
  -days 3650 \
  -subj "/CN=localhost" \
  -addext "subjectAltName=DNS:localhost,IP:127.0.0.1,IP:::1" \
  -keyout "${KEY_PATH}" \
  -out "${CERT_PATH}"

openssl pkcs12 \
  -export \
  -name signal-localhost \
  -inkey "${KEY_PATH}" \
  -in "${CERT_PATH}" \
  -out "${P12_PATH}" \
  -passout pass:changeit

echo "Generated localhost certificate set in ${GENERATED_DIR}"
