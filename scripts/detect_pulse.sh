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

# Try to detect a PulseAudio monitor source
SRC="$(pactl list short sources 2>/dev/null | awk '{print $2}' | grep -E 'monitor$' | head -n1 || true)"
if [[ -z "${SRC}" ]]; then
  echo "PULSE_SOURCE=" >> "${OUT_FILE}"
  echo "Could not auto-detect a PulseAudio monitor source."
  echo "Fill PULSE_SOURCE in .env (e.g., alsa_output.pci-0000_00_1f.3.analog-stereo.monitor)"
else
  echo "PULSE_SOURCE=${SRC}" >> "${OUT_FILE}"
  echo "Detected PulseAudio source: ${SRC}"
fi

echo "Wrote ${OUT_FILE} with defaults. Edit if needed."
