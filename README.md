Silent Disco LAN Broadcaster

Ultra-low-latency local only audio streaming for silent discos, powered by OpenWrt + ffmpeg + multicast RTP.
No cloud servers, no Internet hop — everything stays on your LAN for perfect sync.

How It Works

DJ plugs in: Mixxx (Linux) / Serato (Windows) → ffmpeg sends RTP multicast.

Router hosts landing page: http://dj.dance

Browsers → see instructions and QR codes.

Media players (VLC/mpv/etc) → auto-fetch stream.m3u and join the stream.

Guests join Wi-Fi: Scan the QR → open VLC/mpv → instant silent disco.

Setup

Flash your router with OpenWrt (GL.iNet Slate AX recommended).

Copy disco.fish onto your router or laptop.

Run: