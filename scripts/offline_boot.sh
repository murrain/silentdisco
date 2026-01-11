#!/usr/bin/env bash
set -euo pipefail

CACHE_TAR="cache/silentdisco-images.tar"
CACHE_TARGZ="${CACHE_TAR}.gz"

if ! docker compose config >/dev/null 2>&1; then
  echo "ERROR: Cannot find docker-compose.yml or docker is not running"
  echo "Run from the project root directory, or check that Docker is installed and running"
  exit 1
fi

if docker image inspect silentdisco-web:offline >/dev/null 2>&1 && \
   docker image inspect silentdisco-streamer:offline >/dev/null 2>&1; then
  echo "[i] Images already present."
else
  echo "[i] Loading cached images…"
  if [[ -f "$CACHE_TARGZ" ]]; then
    gunzip -c "$CACHE_TARGZ" | docker load
  elif [[ -f "$CACHE_TAR" ]]; then
    docker load -i "$CACHE_TAR"
  else
    echo "ERROR: Cache not found at $CACHE_TAR or $CACHE_TARGZ"
    echo "Run 'make save-cache-gz' first to create the image cache"
    exit 1
  fi
fi

echo "[i] Starting containers without build…"
exec docker compose up -d --no-build