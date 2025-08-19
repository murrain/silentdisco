FROM debian:stable-slim

RUN apt-get update &&     apt-get install -y --no-install-recommends ffmpeg pulseaudio-utils ca-certificates &&     rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENV GROUP=239.255.0.1 PORT=1234 BITRATE=192k     PULSE_SOURCE=     PULSE_SERVER=

ENTRYPOINT ["/entrypoint.sh"]
