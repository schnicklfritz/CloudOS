#!/bin/bash
set -e

# GPU check (non-fatal)
nvidia-smi || true

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
exec startxfce4
EOF
chmod +x /home/fritz/.vnc/xstartup
chown -R fritz:fritz /home/fritz/.vnc

# Set VNC password via kasmvncpasswd (required - plaintext yaml doesn't work)
echo -e "${FRITZ_PASS}\n${FRITZ_PASS}" | su -s /bin/bash fritz -c "kasmvncpasswd -u fritz -w /home/fritz/.vnc/kasmvnc.passwd" 2>/dev/null || \
    su -s /bin/bash fritz -c "echo '${FRITZ_PASS}' | vncpasswd -f > /home/fritz/.vnc/passwd && chmod 600 /home/fritz/.vnc/passwd"

# Fix permissions
chown -R fritz:fritz /home/fritz
chmod 700 /home/fritz/.vnc

# Copy default kasmvnc config if missing
mkdir -p /etc/kasmvnc
[ ! -f /etc/kasmvnc/kasmvnc.yaml ] && cp /defaults/kasmvnc.yaml /etc/kasmvnc/kasmvnc.yaml
chown -R fritz:fritz /etc/kasmvnc

echo "=== Starting supervisord ==="
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
