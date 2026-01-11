#!/usr/bin/env bash
set -euo pipefail

OUT_FILE=".env"

UID_VAL="$(id -u)"
echo "UID=${UID_VAL}" > "${OUT_FILE}"

GROUP_DEFAULT="${GROUP:-239.255.0.1}"
PORT_DEFAULT="${PORT:-1234}"
BITRATE_DEFAULT="${BITRATE:-192k}"

echo "GROUP=${GROUP_DEFAULT}" >> "${OUT_FILE}"
echo "PORT=${PORT_DEFAULT}" >> "${OUT_FILE}"
echo "BITRATE=${BITRATE_DEFAULT}" >> "${OUT_FILE}"

# Prefer the dedicated sink if present
if pactl list short sources 2>/dev/null | awk '{print $2}' | grep -Fxq "MixxxMaster.monitor"; then
  SRC="MixxxMaster.monitor"
else
  # Fallback: first monitor source
  SRC="$(pactl list short sources 2>/dev/null | awk '{print $2}' | grep -E 'monitor$' | head -n1 || true)"
fi

if [[ -z "${SRC:-}" ]]; then
  echo "PULSE_SOURCE=" >> "${OUT_FILE}"
  echo "WARNING: Could not auto-detect a PulseAudio monitor source."
  echo "Run 'make sink' to create MixxxMaster sink, then re-run 'make env'"
else
  echo "PULSE_SOURCE=${SRC}" >> "${OUT_FILE}"
  echo "Using PulseAudio source: ${SRC}"
fi

echo "Wrote ${OUT_FILE}. Review it if needed."