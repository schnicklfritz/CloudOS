#!/bin/bash

USER="${USER:-fritz}"
PASSWORD="${PASSWORD:-qwerty}"
VNC_PORT="${VNC_PORT:-6901}"
VNC_THREADS="${VNC_THREADS:-4}"

# Set VNC password on first run
if [ ! -f "/home/${USER}/.vnc/passwd" ]; then
    su "$USER" -c "printf '%s\n%s\n' '${PASSWORD}' '${PASSWORD}' | kasmvncpasswd -u ${USER} -o -w -r"
fi

# Clean stale locks
rm -rf /tmp/.X1000-lock /tmp/.X11-unix/X1000

# Start KasmVNC
# -select-de xfce  → kasmvnc writes its own xstartup (reliable)
# -interface 0.0.0.0 → required for QuickPod port mapping
# -websocketPort   → port QuickPod exposes (no SSL, QuickPod proxies TLS)
su "$USER" -c "kasmvncserver :1000 \
    -select-de xfce \
    -interface 0.0.0.0 \
    -websocketPort ${VNC_PORT} \
    -RectThreads ${VNC_THREADS}"

su "$USER" -c "pulseaudio --start --exit-idle-time=-1"

echo "=== KasmVNC running on port ${VNC_PORT} ==="
echo "=== Login: ${USER} / ${PASSWORD} ==="

tail -f "/home/${USER}/.vnc/"*.log
