#!/usr/bin/env bash
set -euo pipefail

GROUP="${GROUP:-239.255.0.1}"
PORT="${PORT:-1234}"
BITRATE="${BITRATE:-192k}"
PULSE_SOURCE="${PULSE_SOURCE:?Missing PULSE_SOURCE (e.g., MixxxMaster.monitor)}"
# Use provided LOCALADDR or auto-detect a sane one
LOCALADDR="${LOCALADDR:-$(ip -4 route get 1.1.1.1 2>/dev/null | awk "/src/ {for(i=1;i<=NF;i++) if (\$i==\"src\") print \$(i+1)}" | head -n1)}"
[[ -z "${LOCALADDR}" ]] && LOCALADDR="0.0.0.0"

: "${PULSE_SERVER:?Missing PULSE_SERVER (expected unix:/run/user/${UID}/pulse/native)}"

URI="udp://${GROUP}:${PORT}?localaddr=${LOCALADDR}&ttl=1&pkt_size=1316&reuse=1&overrun_nonfatal=1&fifo_size=500000"

echo "Starting FFmpeg from Pulse source: ${PULSE_SOURCE}"
echo "Bind local addr: ${LOCALADDR}"
echo "Multicast target: ${GROUP}:${PORT}"

exec ffmpeg -hide_banner -loglevel error \
  -f pulse -i "${PULSE_SOURCE}" \
  -c:a aac -b:a "${BITRATE}" -ar 48000 -ac 2 \
  -f mpegts "${URI}"