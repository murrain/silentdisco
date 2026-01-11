# streamer/Dockerfile
FROM debian:stable-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg pulseaudio-utils iproute2 procps ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Add entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
