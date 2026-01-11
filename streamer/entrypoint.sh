#!/usr/bin/env bash
set -euo pipefail

# Validate multicast group address (must be in range 224.0.0.0 - 239.255.255.255)
validate_multicast_group() {
  local group="$1"
  if [[ ! "$group" =~ ^(22[4-9]|23[0-9])\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})$ ]]; then
    echo "ERROR: Invalid multicast group address: $group"
    echo "Must be in range 224.0.0.0 to 239.255.255.255"
    exit 1
  fi
}

# Validate port number (must be 1-65535)
validate_port() {
  local port="$1"
  if [[ ! "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
    echo "ERROR: Invalid port number: $port"
    echo "Must be between 1 and 65535"
    exit 1
  fi
}

GROUP="${GROUP:-239.255.0.1}"
PORT="${PORT:-1234}"
BITRATE="${BITRATE:-192k}"

# Validate configuration
validate_multicast_group "$GROUP"
validate_port "$PORT"
PULSE_SOURCE="${PULSE_SOURCE:?ERROR: Missing PULSE_SOURCE. Run 'make sink && make env' to auto-detect, or set manually in .env (e.g., MixxxMaster.monitor)}"

# Auto-detect local IP address to use for multicast binding
# Uses 'ip route get' to find which interface/IP would be used to reach the default gateway
# Works even without internet access - just needs local network routing
# Then extracts the 'src' field which contains our local IP address
# Falls back to 0.0.0.0 (all interfaces) if detection fails
GATEWAY="${GATEWAY:-$(ip -4 route show default | awk '/default/ {print $3; exit}')}"
LOCALADDR="${LOCALADDR:-$(ip -4 route get "${GATEWAY:-192.168.1.1}" 2>/dev/null | awk "/src/ {for(i=1;i<=NF;i++) if (\$i==\"src\") print \$(i+1)}" | head -n1)}"
[[ -z "${LOCALADDR}" ]] && LOCALADDR="0.0.0.0"

: "${PULSE_SERVER:?ERROR: Missing PULSE_SERVER. Should be set to unix:/run/user/\${UID}/pulse/native in docker-compose.yml}"

# Build multicast URI with performance tuning parameters:
# - ttl=1: Keep packets on local network only (don't cross routers)
# - pkt_size=1316: Optimal UDP packet size (avoids fragmentation: 1500 MTU - IP/UDP headers)
# - reuse=1: Allow multiple sockets to bind to same address
# - overrun_nonfatal=1: Don't fail on buffer overruns (log warning instead)
# - fifo_size=500000: 500KB buffer to handle network jitter (approximately 2-3 seconds at 192kbps)
URI="udp://${GROUP}:${PORT}?localaddr=${LOCALADDR}&ttl=1&pkt_size=1316&reuse=1&overrun_nonfatal=1&fifo_size=500000"

echo "Starting FFmpeg from Pulse source: ${PULSE_SOURCE}"
echo "Bind local addr: ${LOCALADDR}"
echo "Multicast target: ${GROUP}:${PORT}"

exec ffmpeg -hide_banner -loglevel error \
  -f pulse -i "${PULSE_SOURCE}" \
  -c:a aac -b:a "${BITRATE}" -ar 48000 -ac 2 \
  -f mpegts "${URI}"