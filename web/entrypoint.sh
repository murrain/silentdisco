#!/usr/bin/env bash
set -euo pipefail

# Multicast (what ffmpeg sends)
GROUP="${GROUP:-239.255.0.1}"
PORT="${PORT:-1234}"
MCAST_URI="udp://@${GROUP}:${PORT}"

# udpxy (HTTP proxy on the router)
UDPXY_HOST="${UDPXY_HOST:-192.168.8.1}"   # or set to your router IP, e.g. 192.168.8.1
UDPXY_PORT="${UDPXY_PORT:-4022}"
UDPXY_HTTP="http://${UDPXY_HOST}:${UDPXY_PORT}/udp/${GROUP}:${PORT}"

# Paths
SITE_IN="/opt/silentdisco/site/index.html"
SITE_OUT_DIR="/srv/http"
SITE_OUT="${SITE_OUT_DIR}/index.html"

mkdir -p "${SITE_OUT_DIR}"

# Require template
if [[ ! -f "${SITE_IN}" ]]; then
  echo "ERROR: Missing ${SITE_IN}. Mount your template at ./site/index.html."
  exit 1
fi

# If template uses __URI__, inject multicast URI (so the page still shows udp://@x:y where needed)
if grep -q "__URI__" "${SITE_IN}"; then
  sed "s#__URI__#${GROUP}:${PORT}#g" "${SITE_IN}" > "${SITE_OUT}"
else
  cp -f "${SITE_IN}" "${SITE_OUT}"
fi

# ---------- Generate playlists ----------
# Primary (points at udpxy over HTTP) — use this everywhere
cat > "${SITE_OUT_DIR}/stream.m3u" <<EOF
#EXTM3U
#EXTINF:-1,Silent Disco (HTTP via udpxy)
${UDPXY_HTTP}
EOF

cat > "${SITE_OUT_DIR}/stream.xspf" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<playlist version="1" xmlns="http://xspf.org/ns/0/">
  <title>Silent Disco (HTTP via udpxy)</title>
  <trackList>
    <track><location>${UDPXY_HTTP}</location></track>
  </trackList>
</playlist>
EOF

# Optional: also provide raw multicast playlists for power users
cat > "${SITE_OUT_DIR}/stream-udp.m3u" <<EOF
#EXTM3U
#EXTINF:-1,Silent Disco (raw UDP multicast)
${MCAST_URI}
EOF

cat > "${SITE_OUT_DIR}/stream-udp.xspf" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<playlist version="1" xmlns="http://xspf.org/ns/0/">
  <title>Silent Disco (raw UDP multicast)</title>
  <trackList>
    <track><location>${MCAST_URI}</location></track>
  </trackList>
</playlist>
EOF

# ---------- QR code ----------
# Make QR point to the playlist URL (one-tap into VLC). Use the same host that clients will browse.
QR_TARGET="http://dj.dance/stream.m3u"
qrencode -o "${SITE_OUT_DIR}/qr.png" "${QR_TARGET}"

# ---------- Run web server ----------
exec /usr/sbin/lighttpd -D -f /etc/lighttpd/lighttpd.conf