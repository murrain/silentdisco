#!/usr/bin/env bash
set -euo pipefail

GROUP="${GROUP:-239.255.0.1}"
PORT="${PORT:-1234}"
URI="udp://@${GROUP}:${PORT}"

SITE_IN="/opt/silentdisco/site/index.html"
SITE_OUT_DIR="/srv/http/dj.dance"
SITE_OUT="${SITE_OUT_DIR}/index.html"

mkdir -p "${SITE_OUT_DIR}"

if [[ ! -f "${SITE_IN}" ]]; then
  echo "ERROR: Missing ${SITE_IN}. Mount your template at ./site/index.html."
  exit 1
fi

sed "s#__URI__#${GROUP}:${PORT}#g" "${SITE_IN}" > "${SITE_OUT}"

qrencode -o "${SITE_OUT_DIR}/qr.png" "${URI}"

cat > "${SITE_OUT_DIR}/stream.m3u" <<EOF
#EXTM3U
#EXTINF:-1,Silent Disco
${URI}
EOF

cat > "${SITE_OUT_DIR}/stream.xspf" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<playlist version="1" xmlns="http://xspf.org/ns/0/">
  <title>Silent Disco</title>
  <trackList>
    <track><location>${URI}</location></track>
  </trackList>
</playlist>
EOF

exec /usr/sbin/lighttpd -D -f /etc/lighttpd/lighttpd.conf
