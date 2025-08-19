#!/usr/bin/env bash
set -euo pipefail

GROUP="${GROUP:-239.255.0.1}"
PORT="${PORT:-1234}"
BITRATE="${BITRATE:-192k}"
PULSE_SOURCE="${PULSE_SOURCE:-}"
URI="udp://${GROUP}:${PORT}?ttl=1&pkt_size=1316&reuse=1&overrun_nonfatal=1&fifo_size=500000"

if [[ -z "${PULSE_SERVER:-}" ]]; then
  echo "ERROR: PULSE_SERVER not set. Compose sets it to unix:/run/user/${UID}/pulse/native"
  exit 1
fi

if [[ -z "${PULSE_SOURCE}" ]]; then
  echo "ERROR: PULSE_SOURCE not set. On the host, run: pactl list short sources | grep monitor"
  exit 2
fi

echo "Starting FFmpeg from Pulse source: ${PULSE_SOURCE}"
echo "Multicast target: udp://${GROUP}:${PORT}"
exec ffmpeg -hide_banner -loglevel error   -f pulse -i "${PULSE_SOURCE}"   -c:a aac -b:a "${BITRATE}" -ar 48000 -ac 2   -f mpegts "${URI}"
