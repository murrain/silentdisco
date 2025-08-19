FROM debian:stable-slim

RUN apt-get update &&     apt-get install -y --no-install-recommends lighttpd qrencode ca-certificates &&     rm -rf /var/lib/apt/lists/*

COPY lighttpd.conf /etc/lighttpd/lighttpd.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

VOLUME ["/srv/http/dj.dance", "/opt/silentdisco/site"]

ENV GROUP=239.255.0.1 PORT=1234

ENTRYPOINT ["/entrypoint.sh"]
