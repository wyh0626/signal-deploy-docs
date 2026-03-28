#!/bin/sh

set -eu

REDIS_PORT="${REDIS_PORT:-6379}"
DATA_DIR="/data"

redis-server \
  --cluster-enabled yes \
  --cluster-config-file "${DATA_DIR}/nodes.conf" \
  --cluster-node-timeout 5000 \
  --appendonly no \
  --save "" \
  --port "${REDIS_PORT}" &

REDIS_PID=$!

until redis-cli -p "${REDIS_PORT}" ping 2>/dev/null | grep -q PONG; do
  sleep 0.3
done

if ! redis-cli -p "${REDIS_PORT}" cluster info 2>/dev/null | grep -q "cluster_state:ok"; then
  echo "Initializing single-node cluster on port ${REDIS_PORT}..."
  redis-cli -p "${REDIS_PORT}" cluster addslotsrange 0 16383
fi

echo "Redis single-node cluster ready on port ${REDIS_PORT}"
wait "${REDIS_PID}"
