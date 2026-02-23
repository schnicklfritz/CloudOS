# 1. Replace entrypoint.sh (your script perfect)
cat > entrypoint.sh << 'EOF'
[PASTE YOUR FULL SCRIPT HERE - truncated vncpasswd line]
EOF
chmod +x entrypoint.sh

# 2. supervisord.conf ADD dbus (priority 1)
cat >> /etc/supervisor/conf.d/supervisord.conf << 'EOF'
[program:dbus]
command=su - fritz -c "dbus-daemon --session --print-address"
priority=1
autostart=true
EOF

# 3. Rebuild layers
docker build -t kasm-fixed .
docker run -d --name kasm-fixed -p 6080:6080 -p 6901:6901 -p 22:22 --privileged --restart unless-stopped kasm-fixed && docker logs -f kasm-fixed

# 4. Test
curl -I http://localhost:6080/vnc.html

