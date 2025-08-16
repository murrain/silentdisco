#!/usr/bin/env fish
# Silent Disco (RTP multicast + local info site) — Arch Linux
# Now with: OS-aware page, QR, playlists (M3U/XSPF), and Lighttpd UA routing for players.

set -l GROUP    239.255.0.1
set -l PORT     1234
set -l BITRATE  192k
set -l SITE_DIR /srv/http/dj.dance
set -l QR       $SITE_DIR/qr.png
set -l URI      udp://@$GROUP:$PORT

function bail
  echo (set_color red)"ERROR:"(set_color normal) " $argv"
  exit 1
end

# Require root for package install / service edits
if test (id -u) -ne 0
  echo (set_color yellow)"[i]"(set_color normal) "Re-running as root with sudo…"
  exec sudo fish $argv[0]
end

# Install deps if missing
for pkg in ffmpeg qrencode lighttpd
  pacman -Q $pkg ^/dev/null; or pacman -Sy --noconfirm $pkg; or bail "Failed to install $pkg"
end

# Discover LAN IP
set -l IP (ip -4 addr show scope global | awk '/inet/{print $2}' | sed 's#/.*##' | head -n1)
test -n "$IP"; or bail "Could not determine LAN IP."

# Make site dir + QR
mkdir -p $SITE_DIR
qrencode -o $QR $URI; or bail "QR generation failed"

# ---------- OS-aware landing page ----------
set -l HTML $SITE_DIR/index.html
cat > $HTML <<'HTML'
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Silent Disco — Join the Stream</title>
<style>
  :root { --bg:#0e0e12; --fg:#f6f7fb; --muted:#a9adbb; --card:#171923; --accent:#87e }
  * { box-sizing:border-box }
  body{margin:0;font-family:system-ui,-apple-system,Segoe UI,Roboto,Arial,sans-serif;background:var(--bg);color:var(--fg)}
  .wrap{max-width:980px;margin:0 auto;padding:24px}
  .card{background:var(--card);border-radius:18px;padding:24px;box-shadow:0 10px 30px rgba(0,0,0,.25)}
  h1{margin:0 0 8px;font-size:clamp(28px,5vw,40px)}
  p{color:var(--muted);line-height:1.5}
  .grid{display:grid;gap:16px;grid-template-columns:1fr}
  @media(min-width:900px){.grid{grid-template-columns:1.2fr .8fr}}
  .qr{display:flex;align-items:center;justify-content:center;padding:16px;background:#0b0c12;border-radius:16px}
  .qr img{width:min(320px,90%);height:auto}
  .uri{font-family:ui-monospace,Menlo,Consolas,monospace;background:#0b0c12;color:#eaeaff;padding:12px 14px;border-radius:12px;word-break:break-all}
  .btns{display:flex;flex-wrap:wrap;gap:10px;margin:12px 0}
  a.btn{text-decoration:none;padding:12px 14px;border-radius:12px;background:#22243a;color:#fff;border:1px solid #2e3150}
  a.btn:hover{border-color:var(--accent)}
  .badge{display:inline-block;padding:6px 10px;border-radius:10px;background:#101225;color:#b8baf2;font-size:12px;margin-right:8px;border:1px solid #23264a}
  .hint{font-size:13px;color:#bcbfd2}
  .section-title{margin:18px 0 8px;font-weight:700}
  .subtle{font-size:12px;color:#a3a7bb}
  details{margin-top:10px}
  details>summary{cursor:pointer;color:#b8baf2;margin:6px 0}
</style>
</head>
<body>
  <div class="wrap">
    <div class="card">
      <div class="badge">Ultra-low latency (RTP/UDP multicast)</div>
      <h1>🎧 Join the Silent Disco</h1>
      <p>Install a compatible player for your device, then open the stream below for in-sync audio with minimal delay.</p>

      <div class="grid" style="margin-top:18px">
        <div>
          <div class="section-title">1) Get the player (detected for your device)</div>
          <div class="btns" id="primaryBtns"></div>
          <p class="hint" id="primaryHint"></p>

          <details>
            <summary>Show all player options</summary>
            <div style="margin-top:8px">
              <div class="subtle">Android</div>
              <div class="btns">
                <a class="btn" href="https://play.google.com/store/apps/details?id=org.videolan.vlc">VLC</a>
                <a class="btn" href="https://play.google.com/store/apps/details?id=com.mxtech.videoplayer.ad">MX Player</a>
                <a class="btn" href="https://play.google.com/store/apps/details?id=media.bsplayer.bspandroid.free">BSPlayer</a>
                <a class="btn" href="https://play.google.com/store/apps/details?id=org.xbmc.kodi">Kodi</a>
              </div>
              <div class="subtle" style="margin-top:8px">iOS / iPadOS</div>
              <div class="btns">
                <a class="btn" href="https://apps.apple.com/app/vlc-for-mobile/id650377962">VLC</a>
                <a class="btn" href="https://apps.apple.com/app/nplayer/id1116905928">nPlayer</a>
                <a class="btn" href="https://apps.apple.com/app/oplayer-video-player/id344784375">OPlayer</a>
                <a class="btn" href="https://apps.apple.com/app/infuse-video-player/id1136220934">Infuse (Pro)</a>
              </div>
              <div class="subtle" style="margin-top:8px">Desktop</div>
              <div class="btns">
                <a class="btn" href="https://www.videolan.org/vlc/">VLC (Win/macOS/Linux)</a>
                <a class="btn" href="https://mpv.io/installation/">mpv</a>
                <a class="btn" href="https://ffmpeg.org/download.html">ffplay (FFmpeg)</a>
                <a class="btn" href="https://kodi.tv/download">Kodi</a>
              </div>
            </div>
          </details>

          <div class="section-title" style="margin-top:16px">2) Open this stream</div>
          <p>Scan the QR → choose your player app, or copy/paste this into your player’s <em>Open Network Stream</em>:</p>
          <div class="uri" id="uri">udp://@__URI__</div>
          <p class="hint">If your camera doesn’t offer an app choice, open the app first and paste the address above.</p>
        </div>

        <div>
          <div class="qr"><img src="./qr.png" alt="QR for player apps (udp://@__URI__)"></div>
        </div>
      </div>

      <div class="section-title" style="margin-top:20px">Troubleshooting</div>
      <ul class="hint">
        <li>Join the event Wi-Fi (same network as <strong>dj.dance</strong>).</li>
        <li>If audio crackles, move closer to the DJ Wi-Fi or try again.</li>
        <li>Browsers can’t play UDP — use an app (VLC/nPlayer/MX Player/mpv, etc.).</li>
        <li>Pro tip: in VLC/mpv you can also just enter <strong>dj.dance</strong> — it will auto-load the stream.</li>
      </ul>
    </div>
  </div>

<script>
(function(){
  const uri = 'udp://@__URI__';
  function isIOS(){ return /iphone|ipod|ipad/i.test(navigator.userAgent) }
  function isAndroid(){ return /android/i.test(navigator.userAgent) }
  function isMac(){ return /macintosh|mac os x/i.test(navigator.userAgent) && !isIOS() }
  function isWindows(){ return /windows/i.test(navigator.userAgent) }
  function isLinux(){ return /linux/i.test(navigator.userAgent) && !isAndroid() }

  const primary = document.getElementById('primaryBtns');
  const hint = document.getElementById('primaryHint');

  function addBtn(label, href){
    const a = document.createElement('a');
    a.className = 'btn'; a.textContent = label; a.href = href; a.rel = 'noopener';
    primary.appendChild(a);
  }

  if (isAndroid()) {
    addBtn('Android: Get VLC', 'https://play.google.com/store/apps/details?id=org.videolan.vlc');
    addBtn('Android: MX Player', 'https://play.google.com/store/apps/details?id=com.mxtech.videoplayer.ad');
    hint.textContent = 'After install, open VLC/MX Player → Open Network Stream → paste: ' + uri;
  } else if (isIOS()) {
    addBtn('iOS: Get VLC', 'https://apps.apple.com/app/vlc-for-mobile/id650377962');
    addBtn('iOS: nPlayer', 'https://apps.apple.com/app/nplayer/id1116905928');
    hint.textContent = 'Open the app → Network → Open Stream (MRL) → paste: ' + uri;
  } else if (isWindows()) {
    addBtn('Windows: VLC', 'https://www.videolan.org/vlc/');
    addBtn('Windows: mpv', 'https://mpv.io/installation/');
    hint.textContent = 'In VLC/mpv: Media → Open Network Stream → paste: ' + uri;
  } else if (isMac()) {
    addBtn('macOS: VLC', 'https://www.videolan.org/vlc/');
    addBtn('macOS: mpv', 'https://mpv.io/installation/');
    hint.textContent = 'In VLC/mpv: Open Network Stream → paste: ' + uri;
  } else if (isLinux()) {
    addBtn('Linux: VLC', 'https://www.videolan.org/vlc/');
    addBtn('Linux: mpv', 'https://mpv.io/installation/');
    addBtn('Linux: ffplay', 'https://ffmpeg.org/download.html');
    hint.textContent = 'In VLC/mpv/ffplay: Open Network Stream → paste: ' + uri;
  } else {
    addBtn('Get VLC', 'https://www.videolan.org/vlc/');
    hint.textContent = 'Open VLC → Open Network Stream → paste: ' + uri;
  }
})();
</script>
</body>
</html>
HTML

# Inject multicast URI
sed -i "s#__URI__#$GROUP:$PORT#g" $HTML

# ---------- Playlists for players ----------
cat > $SITE_DIR/stream.m3u <<EOF
#EXTM3U
#EXTINF:-1,Silent Disco
$URI
EOF

cat > $SITE_DIR/stream.xspf <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<playlist version="1" xmlns="http://xspf.org/ns/0/">
  <title>Silent Disco</title>
  <trackList>
    <track><location>$URI</location></track>
  </trackList>
</playlist>
EOF

# ---------- Lighttpd config: docroot + UA-based rewrite for players ----------
set -l LCONF /etc/lighttpd/lighttpd.conf
# Set docroot -> /srv/http (idempotent)
sed -i 's|^server.document-root = .*|server.document-root = "/srv/http"|' $LCONF

# Add UA rewrite block once
set -l MARK "# === silent-disco UA routing ==="
if not grep -q "$MARK" $LCONF
  cp $LCONF $LCONF.bak-$(date +%s)
  cat >> $LCONF <<'CONF'

# === silent-disco UA routing ===
# Media players hitting "/" get the M3U playlist; browsers still see HTML.
$HTTP["useragent"] =~ "(VLC|mpv|Kodi|MXPlayer|nPlayer|OPlayer|Infuse|BSPlayer)" {
  url.rewrite-once = ( "^/$" => "/dj.dance/stream.m3u" )
  index-file.names = ( "stream.m3u" )
}
CONF
end

# Start/restart Lighttpd
systemctl enable --now lighttpd; or bail "Failed to start lighttpd"
systemctl restart lighttpd

# Try to suggest a PulseAudio source
set -l USERNAME (logname)
set -l SRC (sudo -u $USERNAME bash -lc 'pactl list short sources 2>/dev/null | awk "{print \$2}" | grep -E "monitor|loopback" | head -n1')
if test -z "$SRC"
  set SRC (sudo -u $USERNAME bash -lc 'pactl info 2>/dev/null | awk -F": " "/Default Source/{print \$2}"')
end

clear
echo "================ OS-Aware Silent Disco Site Ready ================"
echo " Info page (browser):  http://dj.dance/   (or http://$IP/dj.dance/)"
echo " Player auto-open:     In VLC/mpv, enter just: dj.dance"
echo " Stream URI (direct):  $URI"
echo " QR image:             $QR"
echo " Playlists:            $SITE_DIR/stream.m3u  |  $SITE_DIR/stream.xspf"
echo
echo "=== Start the multicast stream (run as your normal user) ==="
if test -n "$SRC"
  echo "Detected PulseAudio source: $SRC"
else
  echo (set_color yellow)"[i]"(set_color normal) "No monitor/loopback auto-detected."
  echo "  Linux tip: sudo modprobe snd-aloop; Mixxx Master -> ALSA Loopback; use the loopback MONITOR as -i"
  set SRC YOUR_SOURCE_NAME
end
echo
echo (set_color cyan)"ffmpeg -f pulse -i \"$SRC\" -c:a aac -b:a $BITRATE -ar 48000 -ac 2 -f mpegts \"udp://$GROUP:$PORT?ttl=1&pkt_size=1316&reuse=1&overrun_nonfatal=1&fifo_size=500000\""(set_color normal)
echo
echo "=== OpenWrt (GL.iNet Slate AX) — paste over SSH (adjust iface indexes & MAC) ==="
echo (set_color magenta)"
# 1) Static lease for DJ laptop ($IP)
uci add dhcp host
uci set dhcp.@host[-1].name='dj-laptop'
uci set dhcp.@host[-1].mac='AA:BB:CC:DD:EE:FF'   # <-- your laptop Ethernet MAC
uci set dhcp.@host[-1].ip='$IP'
uci commit dhcp
/etc/init.d/dnsmasq restart

# 2) dj.dance -> $IP
uci add dhcp hostrecord
uci set dhcp.@hostrecord[-1].name='dj.dance'
uci set dhcp.@hostrecord[-1].ip='$IP'
uci commit dhcp
/etc/init.d/dnsmasq restart

# 3) Efficient multicast on LAN
uci set network.lan.igmp_snooping='1'
uci commit network
/etc/init.d/network restart

# 4) 5 GHz radio tuning (choose correct device/iface indexes)
uci set wireless.@wifi-device[1].htmode='HE80'
uci set wireless.@wifi-iface[1].multicast_to_unicast='0'
uci set wireless.@wifi-iface[1].mcast_rate='12000'
uci set wireless.@wifi-iface[1].basic_rate='12000 18000 24000'
uci commit wireless
wifi reload
"(set_color normal)
echo "Notes:"
echo " - Audience on 5 GHz SSID; Ethernet the DJ laptop."
echo " - Players: VLC/mpv/Kodi/MX Player/nPlayer/etc. Browsers get the HTML page."
echo "=================================================================="