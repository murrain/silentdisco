# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Silent Disco LAN Broadcaster is a Docker-based system for streaming audio over a local network using UDP multicast. It enables synchronized, low-latency audio streaming for silent disco events without requiring cloud services.

## Architecture

### Two-Container Design

1. **streamer** (`streamer/`):
   - Captures audio from a PulseAudio/PipeWire source
   - Encodes to AAC using FFmpeg
   - Broadcasts via UDP multicast (default: `239.255.0.1:1234`)
   - Runs as the host user to access PulseAudio socket
   - Key file: `streamer/entrypoint.sh` builds the FFmpeg command with multicast URI

2. **web** (`web/`):
   - Runs lighttpd web server on port 80 (host mode)
   - Generates playlist files (M3U/XSPF) pointing to udpxy HTTP proxy
   - Creates QR code for easy mobile access
   - Serves landing page with player instructions
   - Key file: `web/entrypoint.sh` generates playlists and QR codes at startup

### Networking Strategy

The system supports two playback modes:

- **Primary (HTTP via udpxy)**: Uses a udpxy proxy running on the router to convert UDP multicast to HTTP. This works across WiFi and doesn't require multicast-capable client devices. Playlists: `stream.m3u`, `stream.xspf`
- **Direct (raw UDP multicast)**: For advanced users with multicast-capable networks. Playlists: `stream-udp.m3u`, `stream-udp.xspf`

Both containers use `network_mode: host` to access the host's network stack directly for multicast operations.

### Audio Pipeline

```
DJ Software (Mixxx, etc.)
  ↓ (output to PulseAudio/PipeWire sink "MixxxMaster")
PulseAudio/PipeWire Monitor Source
  ↓ (captured by FFmpeg in streamer container)
FFmpeg Encoder (AAC, 48kHz)
  ↓ (UDP multicast to 239.255.0.1:1234)
Router with udpxy
  ↓ (HTTP proxy for multicast stream)
Client Media Players (VLC, mpv, etc.)
```

## Common Commands

### Initial Setup

```bash
# Create PulseAudio/PipeWire virtual sink and auto-detect audio source
make sink        # Creates "MixxxMaster" sink
make env         # Writes .env with detected PULSE_SOURCE

# Edit .env to set PULSE_SOURCE manually if detection fails
# or to configure UDPXY_HOST/UDPXY_PORT for your router
```

### Running the System

```bash
make up          # Build images and start containers
make down        # Stop containers
make logs        # Follow container logs
make rebuild     # Force rebuild images (no cache) and restart
```

### Offline Deployment

```bash
make save-cache-gz                    # Build and save images to cache/silentdisco-images.tar.gz
make up-offline                       # Load from cache and start (no build)
# or: scripts/offline_boot.sh
```

### Development

```bash
docker compose build                  # Build images only
docker compose up -d                  # Start in detached mode
docker compose logs -f streamer       # Follow logs for specific service
docker compose exec web sh            # Shell into web container
```

## Configuration

All runtime configuration is in `.env`:

- `UID`: User ID for PulseAudio access (auto-detected)
- `GROUP`: Multicast group address (default: `239.255.0.1`)
- `PORT`: Multicast port (default: `1234`)
- `BITRATE`: Audio bitrate (default: `192k`)
- `PULSE_SOURCE`: PulseAudio source name (e.g., `MixxxMaster.monitor`)
- `UDPXY_HOST`: Router IP running udpxy (default: `192.168.8.1`)
- `UDPXY_PORT`: udpxy port (default: `4022`)

## Scripts

- `scripts/detect_pulse.sh`: Generates `.env` with auto-detected PulseAudio source (prefers `MixxxMaster.monitor`)
- `scripts/setup_mixxx_sink.sh`: Creates persistent virtual sink "MixxxMaster" and installs systemd user unit
- `scripts/offline_boot.sh`: Loads cached images and starts containers without building

## DNS Configuration

The system expects clients to access `dj.dance`. Configure your router/DNS server to point `dj.dance` to the host's LAN IP. The lighttpd server includes User-Agent detection to redirect media players (VLC, mpv, etc.) directly to the playlist file when accessing the root URL.

## Web Server Behavior

`web/lighttpd.conf` includes smart routing:
- Media player User-Agents (VLC, mpv, Kodi, etc.) requesting `/` get redirected to `/stream.m3u`
- Browser requests to `/` serve the landing page (`index.html`)
- `/stream` redirects to `/stream.m3u` for convenience

## Important Notes

- Both containers must use `network_mode: host` for multicast to work properly
- The streamer container runs as the host user (`user: "${UID}:${UID}"`) to access the PulseAudio socket at `/run/user/${UID}/pulse/native`
- The system uses TTL=1 for multicast to keep traffic local
- FFmpeg parameters in `streamer/entrypoint.sh` include buffer tuning (`fifo_size`, `pkt_size`) for reliable streaming
- The web entrypoint generates all playlists and QR codes at startup, not build time, so configuration changes only require restart
