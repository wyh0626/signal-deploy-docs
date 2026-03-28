#!/usr/bin/env bash

set -euo pipefail

TIMEOUT_SECONDS="${1:-10}"

python3 - "${TIMEOUT_SECONDS}" <<'PY'
import subprocess
import sys

timeout = int(sys.argv[1])

try:
    subprocess.run(
        ["docker", "info"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=True,
        timeout=timeout,
    )
except subprocess.TimeoutExpired:
    print(f"Docker daemon did not respond within {timeout} seconds.", file=sys.stderr)
    raise SystemExit(1)
except Exception:
    print("Docker daemon is not reachable.", file=sys.stderr)
    raise SystemExit(1)
PY
