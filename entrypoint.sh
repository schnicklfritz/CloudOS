#!/bin/bash
set -e

# 1. KVM Check
if [ ! -e /dev/kvm ]; then
    echo "WARNING: /dev/kvm not found. QEMU will run without hardware acceleration."
else
    chmod 666 /dev/kvm
fi

# 2. Persistence Logic for /workspace
if [ -d "/workspace" ]; then
    if [ ! -d "/workspace/home" ]; then
        echo "Initializing persistent home in /workspace/home..."
        cp -rp /home/fritz /workspace/home
    fi
    # Remove local home and symlink to workspace
    rm -rf /home/fritz
    ln -s /workspace/home /home/fritz
    # Fix ownership in case of UID mismatch
    chown -R fritz:fritz /workspace/home
fi

# 3. Set VNC Password for fritz
mkdir -p /home/fritz/.vnc
echo "qwerty" | vncpasswd -f > /home/fritz/.vnc/passwd
chown -R fritz:fritz /home/fritz/.vnc
chmod 600 /home/fritz/.vnc/passwd

# 4. Start Supervisord
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
