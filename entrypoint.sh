#!/bin/bash
set -e

nvidia-smi || true

chown -R fritz:fritz /home/fritz/.vnc /etc/kasmvnc
[ ! -f /etc/kasmvnc/kasmvnc.yaml ] && cp /defaults/kasmvnc.yaml /etc/kasmvnc/ && chown fritz:fritz /etc/kasmvnc/kasmvnc.yaml

# PulseAudio config
su - fritz -c "mkdir -p ~/.config/pulse && echo 'load-module module-detect' > ~/.config/pulse/default.pa"

# DBus + XFCE pre-launch
export XDG_RUNTIME_DIR=/run/user/$(id -u fritz)
mkdir -p $XDG_RUNTIME_DIR
chown fritz:fritz $XDG_RUNTIME_DIR
su - fritz -c "dbus-daemon --session --fork --print-address > ~/.dbus-session && export $(cat ~/.dbus-session) && xfce4-session &" || true
sleep 5

exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
