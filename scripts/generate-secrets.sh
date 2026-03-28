#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UPSTREAM_TEST_SECRETS="${ROOT_DIR}/upstream/Signal-Server/service/src/test/resources/config/test-secrets-bundle.yml"

if [[ ! -f "${UPSTREAM_TEST_SECRETS}" ]]; then
  echo "Missing ${UPSTREAM_TEST_SECRETS}" >&2
  echo "Run: ./scripts/bootstrap-upstream.sh" >&2
  exit 1
fi

b64() {
  local n="${1:-32}"
  openssl rand -base64 "${n}" | tr -d '\n'
}

extract_upstream_secret() {
  local key="$1"
  python3 - "${UPSTREAM_TEST_SECRETS}" "${key}" <<'PY'
import pathlib
import re
import sys

contents = pathlib.Path(sys.argv[1]).read_text()
key = re.escape(sys.argv[2])
match = re.search(rf"(?m)^{key}:\s*(\S+)\s*$", contents)
if not match:
    raise SystemExit(f"Could not find {sys.argv[2]} in upstream test secrets")
print(match.group(1))
PY
}

indent() {
  sed 's/^/  /'
}

zk_secret="$(extract_upstream_secret "zkConfig-libsignal-0.42.serverSecret")"
calling_zk_secret="$(extract_upstream_secret "callingZkConfig.serverSecret")"
backups_zk_secret="$(extract_upstream_secret "backupsZkConfig.serverSecret")"

apn_signing_key="$(
  openssl ecparam -name prime256v1 -genkey -noout 2>/dev/null \
    | openssl pkcs8 -topk8 -nocrypt 2>/dev/null
)"

apple_app_store_key="$(
  openssl ecparam -name prime256v1 -genkey -noout 2>/dev/null \
    | openssl pkcs8 -topk8 -nocrypt 2>/dev/null
)"

gcp_attachments_key="$(openssl genrsa 2048 2>/dev/null)"
kt_client_key="$(
  openssl ecparam -name prime256v1 -genkey -noout 2>/dev/null \
    | openssl pkcs8 -topk8 -nocrypt 2>/dev/null
)"

dummy_google_service_account='{"type": "service_account", "project_id": "signal-local", "private_key_id": "local-key-1", "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQCkAtB9NJmuBgmk\n4uIQiyACjBkbdUq5+NSFU5fwBYCL4gpKBv9fEzzq2orqzwbVupog4WrUk5FJ4MKl\niKtaSz6/dDS9voFqhTUid3lwgzxTg3E+oqLSmCXfYMZIQvpNgfQK5tMVZr7nRIGf\nVtCo5g0OXQxEqCa0Q6bQD1lZ2vbSbJOWpBG6FeRZTP2HrMG6eUow8x7DpBMk/vOV\nQDrozpL7o1fsOO3OgX7U7JPRaVCg+g8b3GHnEMabiChfyeVY0ixYlSXR/AF7W0s9\n+4wBnjd4437EW4cYaK15BMt/o0gMyOSURLd6jwrrh6/kdMY90Ncsvnk1vwNP0mWG\nDT1fX6SVAgMBAAECggEACwDo718eKMrdG2CUOl6DKF7+EW88mYTxIskzELAZA2/u\nZDB0/wvbRexuO1OzCZej3vnddEnUPdvw/MpSQlQTCSUPcGPkHeGDAsveOQC50hnB\nX5DpkjreXs68CHDjhyiyI7sZxVe0p7wOY3Wfhf1gbREsET0kBgSvhknJVloQJJmq\niDp5KoOp9fGHZATUNZSnbPev948LyHYynwW5D/IkmrusLy7I8pnf0cehJkrIzCB7\nfebl6KT2ziE3Aqui35hz7gKfHAmyOy6isBQbgEJluvugLp43xULnp6pzt/JpJ+ck\n7yUY1I4GiPP1AfVIX0LjNRoD+byASVow3ifo+8KFrwKBgQDULpz0jpN4HCuEpgxP\nFmL0k0F5o3F9Wl+HdIeKUOHHk5bG1Q4S+bMo/RdQBMTFE8GcSufB5rOjmhUsPGdo\nXydN9TSffGieC0+zYGHglYBBLgkYDbsmXSdvkZgDLsxGYRF5WYo2KTu9TNDgQP/O\ntE0TPxOrpfU9mOln9vg9/NL90wKBgQDF4YzYp29eMG7WMrllCKJoFUD236+ZSM9q\nnOQGpgyuJp6eJA3MwnbrGZrEQtDQA+W0+css8GCdlqBledBVrEmrhuDbvmTbyRlb\n3b2DRhd//BeCFNY8EdtfypkwoLzD7LXrngIgYqG92gC9KdvrrjEOSRBnNW76cZ1X\nIcyN8IOK9wKBgQDMx+wdr5kuO+nYTTXmApIgwBpaHl+C/vzhy5qg6KzvpEbJwYii\n0bGTJqkgRmnuVsHuaPDCWDkZ9bTni6i1t9hEShqurjB+ECas1aHBUiiFP7vxJhdw\n0EkmSZsvvzPR3Q8zUjKtUSBh88hIFxOMWMFmiOMgL7y/5VunRlmR4fd0lwKBgCAP\nTPyFFBwUiMCXc0YVQgrO9rmIwDB7hW9mf+M73+4PP7+rY7j7AL1SZqrJkH9DQmIx\n3mMnht/BWbdXJxPaWA08Sw4PKNQbHsqtgFjWcFRCCaT/rz4IPpykfHFOeYbcwRSt\ngvawRDg4K8p6D7F9hWElIU03cQWOhslpJnUQtJ89AoGBAKCzsKSI56Dlepp35u98\nyxuSAuxfItQErNQWWaGNCnav8xX6pZ9OOyYz7SUNdtKiYVvCtm2DXgQhT6Gbkj/B\nBBbmtDiMUlgF6syoQnVZ7yntutTbP3n4NK2oAIC4zvXhiNbEklCS3kKd03QhB2cF\ng3Z0NUdopa9B4RirmEl8NZ+G\n-----END PRIVATE KEY-----\n", "client_email": "firebase-adminsdk@signal-local.iam.gserviceaccount.com", "client_id": "000000000000000000001", "auth_uri": "https://accounts.google.com/o/oauth2/auth", "token_uri": "https://oauth2.googleapis.com/token"}'

cat <<EOF
# Auto-generated local secrets for Signal dev deployment.
# Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
# ZK secrets are sourced from the pinned upstream Signal-Server test fixtures
# so they stay compatible with the matching serverPublic params.

stripe.apiKey: local_stripe_disabled
stripe.idempotencyKeyGenerator: $(b64 32)

braintree.publicKey: local_disabled
braintree.privateKey: local_disabled

directoryV2.client.userAuthenticationTokenSharedSecret: $(b64 32)
directoryV2.client.userIdTokenSharedSecret: $(b64 32)

svr2.userAuthenticationTokenSharedSecret: $(b64 32)
svr2.userIdTokenSharedSecret: $(b64 32)

svrb.userAuthenticationTokenSharedSecret: $(b64 32)
svrb.userIdTokenSharedSecret: $(b64 32)

tus.userAuthenticationTokenSharedSecret: $(b64 32)

gcpAttachments.rsaSigningKey: |
$(printf '%s\n' "${gcp_attachments_key}" | indent)

apn.teamId: local
apn.keyId: local
apn.signingKey: |
$(printf '%s\n' "${apn_signing_key}" | indent)

fcm.credentials: |
  ${dummy_google_service_account}

cdn.accessKey: minioadmin
cdn.accessSecret: minioadmin

cdn3StorageManager.clientSecret: local_disabled

unidentifiedDelivery.privateKey: $(b64 32)

keyTransparencyService.clientPrivateKey: |
$(printf '%s\n' "${kt_client_key}" | indent)

storageService.userAuthenticationTokenSharedSecret: $(b64 32)

zkConfig-libsignal-0.42.serverSecret: ${zk_secret}
callingZkConfig.serverSecret: ${calling_zk_secret}
backupsZkConfig.serverSecret: ${backups_zk_secret}

paymentsService.userAuthenticationTokenSharedSecret: $(b64 32)
paymentsService.fixerApiKey: local_disabled
paymentsService.coinGeckoApiKey: local_disabled

registrationService.collationKeySalt: $(b64 8)

turn.cloudflare.apiToken: local_disabled

linkDevice.secret: $(b64 8)

tlsKeyStore.password: changeit

hlrLookup.apiKey: local
hlrLookup.apiSecret: local

appleAppStore.encodedKey: |
$(printf '%s\n' "${apple_app_store_key}" | indent)

awsCredentials.accessKeyId: minioadmin
awsCredentials.secretAccessKey: minioadmin
EOF
