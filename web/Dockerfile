# web/Dockerfile
FROM debian:stable-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    lighttpd \
    qrencode \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy lighttpd configuration
COPY lighttpd.conf /etc/lighttpd/lighttpd.conf

# Add entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
