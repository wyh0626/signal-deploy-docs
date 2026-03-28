#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export DYNAMODB_ENDPOINT="${DYNAMODB_ENDPOINT:-http://localhost:8000}"
export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-local}"
export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-local}"
export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-east-1}"
export DYNAMODB_RECREATE_ON_MISMATCH="${DYNAMODB_RECREATE_ON_MISMATCH:-1}"

python3 "${SCRIPT_DIR}/init-dynamodb.py"
