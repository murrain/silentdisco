#!/usr/bin/env bash
set -euo pipefail

# Works for both PulseAudio and PipeWire (pipewire-pulse).
# Creates a persistent virtual sink "MixxxMaster" and prints the monitor name.

SINK_NAME="MixxxMaster"

# Ensure pactl is present and a Pulse server is up
if ! command -v pactl >/dev/null 2>&1; then
  echo "ERROR: pactl not found. Install pulseaudio-utils or pipewire-pulse."
  exit 1
fi
if ! pactl info >/dev/null 2>&1; then
  echo "ERROR: No running Pulse server (PulseAudio or pipewire-pulse). Start your desktop session first."
  exit 1
fi

# Does the sink already exist?
if pactl list short sinks | awk '{print $2}' | grep -Fxq "$SINK_NAME"; then
  echo "Sink '$SINK_NAME' already exists."
else
  # Try to create a null sink (PulseAudio + PipeWire both support module-null-sink)
  # The description is just a friendly label you’ll see in mixer UIs.
  pactl load-module module-null-sink sink_name="$SINK_NAME" sink_properties=device.description="$SINK_NAME" >/dev/null
  echo "Created sink '$SINK_NAME'."
fi

MON="${SINK_NAME}.monitor"
echo "Monitor source: ${MON}"

# Optional: create a user systemd unit to ensure the sink exists after login (reboots)
# This is robust for PipeWire too.
UNIT_DIR="${HOME}/.config/systemd/user"
UNIT_FILE="${UNIT_DIR}/mixxxmaster.service"
mkdir -p "${UNIT_DIR}"
cat > "${UNIT_FILE}" <<EOF
[Unit]
Description=Create Pulse virtual sink: ${SINK_NAME}
After=default.target

[Service]
Type=oneshot
ExecStart=/usr/bin/pactl load-module module-null-sink sink_name=${SINK_NAME} sink_properties=device.description=${SINK_NAME}
# It's okay if it already exists
SuccessExitStatus=0

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now mixxxmaster.service >/dev/null 2>&1 || true

echo "Persistent unit installed: systemctl --user status mixxxmaster.service"
echo "Set your Mixxx Master output to '${SINK_NAME}'. Headphones to your controller/headset."
echo "Streamer should use PULSE_SOURCE=${MON}"