#!/bin/bash
set -e

# GPU check
nvidia-smi || true

# Perms + config init
chown -R fritz:fritz /home/fritz/.vnc /etc/kasmvnc /usr/share/novnc
[ ! -f /etc/kasmvnc/kasmvnc.yaml ] && cp /defaults/kasmvnc.yaml /etc/kasmvnc/ && chown fritz:fritz /etc/kasmvnc/kasmvnc.yaml

# SSH keys (unblocks sshd 255)
mkdir -p /var/run/sshd && \
ssh-keygen -A && \
sed -i 's/#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
sed -i 's/#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config

exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
