#!/bin/bash
set -e

rm -f /tmp/.X1-lock /tmp/.X11-unix/X1

# GPU check (non-fatal)
nvidia-smi || true

mkdir -p /run/user/1000
chown -R fritz:fritz /run/user/1000 /home/fritz
chmod 700 /home.fritz/.vnc

# SSH host keys
mkdir -p /var/run/sshd
ssh-keygen -A
sed -i 's/#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Set fritz password (allows QuickPod env var override)
FRITZ_PASS="${VNC_PASSWORD:-qwerty}"
echo "fritz:${FRITZ_PASS}" | chpasswd

# Create xstartup for XFCE session - THIS is what was missing
mkdir -p /home/fritz/.vnc
cat > /home/fritz/.vnc/xstartup << 'EOF'
#!/bin/bash
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=XFCE
exec dbus-launch --exit-with-session startxfce4
EOF
chmod +x /home/fritz/.vnc/xstartup
chown -R fritz:fritz /home/fritz/.vnc

# Set VNC password via kasmvncpasswd (required - plaintext yaml doesn't work)
echo -e "${FRITZ_PASS}\n${FRITZ_PASS}" | kasmvncpasswd -u fritz -w /home/fritz/.vnc/kasmvnc.passwd \


# Fix permissions
chown -R fritz:fritz /home/fritz/.vnc/kasmvnc.passwd
chmod 600 /home/fritz/.vnc/kasmvnc.passwd

# Copy default kasmvnc config if missing
mkdir -p /etc/kasmvnc
[ ! -f /etc/kasmvnc/kasmvnc.yaml ] && cp /defaults/kasmvnc.yaml /etc/kasmvnc/kasmvnc.yaml
chown -R fritz:fritz /etc/kasmvnc

echo "=== Starting supervisord ==="
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
