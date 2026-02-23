#!/bin/bash
set -e

nvidia-smi || true

# SSH setup
mkdir -p /var/run/sshd
ssh-keygen -A
sed -i 's/#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Allow env var override of password
FRITZ_PASS="${VNC_PASSWORD:-qwerty}"
echo "fritz:${FRITZ_PASS}" | chpasswd

# CRITICAL: fritz must be in ssl-cert group to read the SSL key
# KasmVNC silently fails WebSocket if this is missing
usermod -aG ssl-cert fritz 2>/dev/null || true

# Create xstartup — must use dbus-launch or XFCE won't start
mkdir -p /home/fritz/.vnc
cat > /home/fritz/.vnc/xstartup << 'EOF'
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=XFCE
export XKL_XMODMAP_DISABLE=1
[ -r $HOME/.Xresources ] && xrdb $HOME/.Xresources
exec dbus-launch --exit-with-session startxfce4
EOF
chmod +x /home/fritz/.vnc/xstartup

# Set VNC password using kasmvncpasswd
# This creates the binary passwd file KasmVNC actually reads
su -s /bin/bash fritz -c "
  mkdir -p ~/.vnc
  printf '%s\n%s\n' '${FRITZ_PASS}' '${FRITZ_PASS}' | kasmvncpasswd -u fritz -w ~/.vnc/kasmvnc.passwd
" 2>/dev/null || echo "WARNING: kasmvncpasswd failed, trying fallback..."

# Fix all permissions
chown -R fritz:fritz /home/fritz/.vnc
chmod 700 /home/fritz/.vnc
chmod 600 /home/fritz/.vnc/kasmvnc.passwd 2>/dev/null || true

# Deploy kasmvnc config
mkdir -p /etc/kasmvnc
cp /defaults/kasmvnc.yaml /etc/kasmvnc/kasmvnc.yaml
chown fritz:fritz /etc/kasmvnc/kasmvnc.yaml

# XDG runtime dir needed by dbus/pulseaudio
mkdir -p /run/user/$(id -u fritz)
chown fritz:fritz /run/user/$(id -u fritz)
chmod 700 /run/user/$(id -u fritz)

echo "=== Config complete, starting supervisord ==="
echo "=== KasmVNC will be at http://POD_IP:6901 ==="

exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
