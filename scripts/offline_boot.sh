#!/usr/bin/env bash
set -euo pipefail

CACHE_TAR="cache/silentdisco-images.tar"
CACHE_TARGZ="${CACHE_TAR}.gz"

if docker compose config >/dev/null 2>&1; then :; else
  echo "Run from the project root (where docker-compose.yml lives)."
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
    echo "Cache not found: $CACHE_TAR(.gz)"; exit 1
  fi
fi

echo "[i] Starting containers without build…"
exec docker compose up -d --no-build