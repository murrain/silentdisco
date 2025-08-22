#!/bin/bash
set -e

# Name of our virtual sink
SINK="MixxxMaster"

# Check if MixxxMaster sink already exists
if ! pactl list short sinks | grep -q "$SINK"; then
  echo "Creating PulseAudio null sink: $SINK"
  pactl load-module module-null-sink sink_name=$SINK sink_properties=device.description=$SINK
fi

echo "Launching Mixxx..."
mixxx &
MIXXX_PID=$!

# Give Mixxx some time to boot up
sleep 5

# Force Mixxx Master output to MixxxMaster sink
echo "Routing Mixxx Master output to $SINK"
pactl list short sink-inputs | grep "Mixxx" | while read -r line; do
  ID=$(echo $line | awk '{print $1}')
  pactl move-sink-input $ID $SINK
done

echo "Mixxx running with Master output locked to $SINK"
echo "Docker container can now stream from ${SINK}.monitor"
wait $MIXXX_PID
