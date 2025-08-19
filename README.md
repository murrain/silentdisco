# Silent Disco LAN Broadcaster (Docker)

Local-only multicast audio for silent discos. No cloud, tight sync.

## Quick Start
1) Generate `.env` with your UID and Pulse source:
```bash
make env
# edit .env to set PULSE_SOURCE if not auto-detected
```
2) Launch:
```bash
make up
```
3) Point router DNS: `dj.dance` -> your host LAN IP.

- Users open `http://dj.dance/` in a browser (instructions + QR), or just type `dj.dance` in VLC/mpv.
- Media players that fetch `http://dj.dance/` auto-receive the playlist and join the stream.

## Useful
- Change stream: edit `.env` (GROUP/PORT/BITRATE), `make up` again.
- Stop:
```bash
make down
```
- Tail logs:
```bash
make logs
```
