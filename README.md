# Silent Disco LAN Broadcaster (Docker)

Local-only multicast audio for silent discos. No cloud, tight sync.

Stream DJ audio from your laptop to dozens of phones/devices on the same WiFi network with ultra-low latency (typically 50-200ms). Perfect for silent disco parties, outdoor events, or anywhere you need synchronized audio without cables.

## Features

- **Ultra-low latency**: UDP multicast for real-time audio (~50-200ms delay)
- **No internet required**: Everything runs on your local network
- **Easy client setup**: Scan QR code → open in VLC/media player
- **Cross-platform**: Works with iOS, Android, Windows, macOS, Linux
- **Dockerized**: Simple deployment, no complex dependencies
- **HTTP fallback**: Uses udpxy proxy for WiFi compatibility

## Prerequisites

### Required
- **Linux host** with Docker and Docker Compose installed
- **PulseAudio** or **PipeWire** audio system (standard on most Linux desktops)
- **Router with multicast support** and optionally udpxy for HTTP streaming
- **Same WiFi network** for DJ laptop and all clients

### Optional but Recommended
- **udpxy** running on your router (converts UDP multicast to HTTP for better WiFi compatibility)
- **DNS override** capability on your router (to point `dj.dance` to the DJ laptop)

## Quick Start

### 1. Create Virtual Audio Sink

This creates a "MixxxMaster" virtual audio device that captures your DJ software output:

```bash
make sink
```

This installs a systemd user service that persists across reboots.

### 2. Generate Configuration

Auto-detect your system UID and PulseAudio sources:

```bash
make env
```

This creates `.env` with your configuration. If auto-detection fails:

```bash
# List available audio sources
pactl list short sources

# Edit .env and set PULSE_SOURCE manually
# Example: PULSE_SOURCE=alsa_output.pci-0000_00_1f.3.analog-stereo.monitor
nano .env
```

### 3. Configure Your Router

#### DNS Configuration
Point `dj.dance` to your DJ laptop's LAN IP address (e.g., `192.168.8.100`). How to do this depends on your router:

- **OpenWrt/LEDE**: Add entry in `/etc/hosts` or use DNS override
- **DD-WRT**: Services → Additional DNSMasq Options: `address=/dj.dance/192.168.8.100`
- **pfSense**: Services → DNS Resolver → Host Overrides
- **Consumer routers**: Look for "DNS Override" or "Custom DNS entries" in settings

#### udpxy Configuration (Recommended)

If your router supports udpxy, enable it on port 4022. This provides HTTP access to UDP multicast streams, which works better across WiFi.

If using a different IP or port, update `.env`:
```bash
UDPXY_HOST=192.168.8.1
UDPXY_PORT=4022
```

Without udpxy, clients must use the raw UDP multicast playlists (`stream-udp.m3u`).

### 4. Launch the System

```bash
make up
```

This builds and starts two Docker containers:
- **web**: Serves the landing page, playlists, and QR code (port 80)
- **streamer**: Captures audio and broadcasts via multicast

### 5. Configure Your DJ Software

Set your DJ software (Mixxx, Traktor, etc.) to output audio to:
- **Master Output**: MixxxMaster (the virtual sink)
- **Headphones/Monitor**: Your physical audio device

### 6. Clients Connect

Users on the same WiFi network:

1. Open browser to `http://dj.dance/`
2. Follow instructions for their device (iOS, Android, Windows, etc.)
3. Scan QR code or manually open `http://dj.dance/stream.m3u` in VLC/nPlayer/mpv

## Configuration

All settings are in `.env`:

```bash
# System
UID=1000                          # Your user ID (auto-detected)

# Audio streaming
GROUP=239.255.0.1                 # Multicast group (224.0.0.0 - 239.255.255.255)
PORT=1234                         # Multicast port (1-65535)
BITRATE=192k                      # Audio bitrate (128k, 192k, 256k, 320k)
PULSE_SOURCE=MixxxMaster.monitor  # PulseAudio source (auto-detected)

# HTTP proxy (optional, recommended)
UDPXY_HOST=192.168.8.1           # Router IP running udpxy
UDPXY_PORT=4022                  # udpxy port
```

### Bitrate Guide

| Bitrate | Quality | Network Bandwidth | Recommended For |
|---------|---------|-------------------|-----------------|
| 128k | Good | ~128 kbps | Large events (50+ users), weak WiFi |
| 192k | Very Good | ~192 kbps | Standard (default) |
| 256k | Excellent | ~256 kbps | Small events, strong WiFi |
| 320k | Maximum | ~320 kbps | Audiophile, wired connections |

## Useful Commands

```bash
# View logs
make logs

# Stop everything
make down

# Rebuild after code changes
make rebuild

# Change configuration (after editing .env)
make down
make up
```

## Troubleshooting

### No Audio / Stream Not Working

1. **Check PulseAudio source**:
   ```bash
   pactl list short sources | grep monitor
   ```
   Ensure your PULSE_SOURCE in `.env` matches an available monitor source.

2. **Verify containers are running**:
   ```bash
   docker ps
   ```
   Both `silentdisco-web` and `silentdisco-streamer` should be running.

3. **Check container logs**:
   ```bash
   make logs
   ```
   Look for FFmpeg errors or PulseAudio connection issues.

4. **Test direct multicast** (on DJ laptop):
   ```bash
   ffplay udp://@239.255.0.1:1234
   ```

### Clients Can't Connect

1. **Verify DNS resolution**:
   ```bash
   # On client device
   ping dj.dance
   ```
   Should resolve to your DJ laptop's IP.

2. **Check web server**:
   ```bash
   curl http://dj.dance/
   ```
   Should return the landing page HTML.

3. **Verify same network**: DJ laptop and clients must be on the same WiFi network.

4. **Check firewall**: Ensure ports 80 (HTTP) and 1234 (UDP) are not blocked.

### Audio Crackles or Drops

1. **Increase buffer size**: Edit `streamer/entrypoint.sh` and increase `fifo_size` (default: 500000)
2. **Lower bitrate**: Change `BITRATE=128k` in `.env`
3. **Check WiFi signal strength**: Clients should be close to access point
4. **Use HTTP mode**: Ensure udpxy is configured (better reliability than raw multicast)

### "Invalid multicast group address" Error

The multicast group must be in range `224.0.0.0` to `239.255.255.255`. The default `239.255.0.1` is recommended for local networks.

### "Missing PULSE_SOURCE" Error

Run `make sink` to create the virtual audio sink, then `make env` to regenerate configuration.

### Container Fails to Start

1. **Check Docker is running**:
   ```bash
   docker ps
   ```

2. **Verify .env exists**:
   ```bash
   cat .env
   ```

3. **Check PulseAudio socket**:
   ```bash
   ls /run/user/$(id -u)/pulse/native
   ```

## Offline Deployment

For events without internet access, you can pre-cache Docker images:

```bash
# On a machine with internet
make save-cache-gz

# Transfer cache/silentdisco-images.tar.gz to event location

# On offline machine
make load-cache
make up-offline
```

## Advanced Configuration

### Using a Different Multicast Group

Edit `.env`:
```bash
GROUP=239.192.0.1
PORT=5000
```

Then restart: `make down && make up`

### Multiple Streams

Run multiple instances on different multicast groups/ports. Copy the project directory and edit `.env` for each stream.

### Recording the Stream

On any client machine:
```bash
ffmpeg -i udp://@239.255.0.1:1234 -c copy recording.aac
```

## Architecture

- **streamer container**: Captures from PulseAudio, encodes to AAC with FFmpeg, broadcasts via UDP multicast
- **web container**: Runs lighttpd, serves landing page, generates playlists and QR code
- **host networking**: Required for multicast to work properly
- **udpxy proxy**: Optional HTTP proxy for multicast (runs on router)

See [CLAUDE.md](CLAUDE.md) for detailed architecture documentation.

## Supported Clients

### iOS / iPadOS
- VLC for Mobile (recommended)
- nPlayer
- OPlayer
- Infuse Pro

### Android
- VLC (recommended)
- MX Player
- BSPlayer
- Kodi

### Desktop (Windows/macOS/Linux)
- VLC (recommended)
- mpv
- ffplay (FFmpeg)
- Kodi

**Note**: Web browsers cannot play UDP streams directly. Users must install a compatible media player app.
