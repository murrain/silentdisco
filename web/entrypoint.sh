#!/usr/bin/env bash
set -euo pipefail

GROUP="${GROUP:-239.255.0.1}"
PORT="${PORT:-1234}"
URI="udp://@${GROUP}:${PORT}"

SITE_IN="/opt/silentdisco/site/index.html"
SITE_OUT_DIR="/srv/http"
SITE_OUT="${SITE_OUT_DIR}/index.html"

mkdir -p "${SITE_OUT_DIR}"

# Require template
if [[ ! -f "${SITE_IN}" ]]; then
  echo "ERROR: Missing ${SITE_IN}. Mount your template at ./site/index.html."
  exit 1
fi

# If template uses __URI__, inject; otherwise just copy
if grep -q "__URI__" "${SITE_IN}"; then
  sed "s#__URI__#${GROUP}:${PORT}#g" "${SITE_IN}" > "${SITE_OUT}"
else
  cp -f "${SITE_IN}" "${SITE_OUT}"
fi

# Generate QR + playlists
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

# Start lighttpd in foreground
exec /usr/sbin/lighttpd -D -f /etc/lighttpd/lighttpd.conf