#!/bin/bash
set -e

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

# 3. Start Supervisord
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
