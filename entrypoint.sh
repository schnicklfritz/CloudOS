#!/bin/bash
set -e

# Wait for GPU
nvidia-smi || true

# Init KasmVNC config if missing
if [ ! -f /etc/kasmvnc/kasmvnc.yaml ]; then
  cp /defaults/kasmvnc.yaml /etc/kasmvnc/kasmvnc.yaml
  chown fritz:fritz /etc/kasmvnc/kasmvnc.yaml
fi

# Fix perms
chown -R fritz:fritz /home/fritz/.vnc /etc/kasmvnc

# Start dbus for XFCE (Kasm needs it)
export XDG_RUNTIME_DIR=/run/user/1000
mkdir -p $XDG_RUNTIME_DIR
chown fritz:fritz $XDG_RUNTIME_DIR

# Sleep for deps
sleep 3

# Supervisor
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
