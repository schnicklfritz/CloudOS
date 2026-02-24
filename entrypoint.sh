#!/bin/bash

if [ ! -f "/init_flag" ]; then
    USER="${USER:-quickpod}"
    PASSWORD="${PASSWORD:-abcd1234}"
    UID_VAL="${UID:-1000}"
    GID_VAL="${GID:-1000}"

    update-alternatives --install /usr/bin/python python /usr/bin/python3 2

    groupadd -g "$GID_VAL" "$USER" 2>/dev/null || true
    useradd --create-home --no-log-init -u "$UID_VAL" -g "$GID_VAL" "$USER" 2>/dev/null || true
    # ssl-cert group is REQUIRED — lets user read /etc/ssl/private/ssl-cert-snakeoil.key
    usermod -aG sudo,ssl-cert "$USER"
    chsh -s /bin/bash "$USER"

    echo "root:${PASSWORD}" | chpasswd
    echo "${USER}:${PASSWORD}" | chpasswd

    echo "export PATH=/opt/miniconda3/bin:\$PATH" >> "/home/${USER}/.bashrc"

    echo "ok" > /init_flag
fi

USER="${USER:-quickpod}"
PASSWORD="${PASSWORD:-abcd1234}"
REMOTE_DESKTOP="${REMOTE_DESKTOP:-kasmvnc}"

ssh-keygen -A
/usr/sbin/sshd
/etc/init.d/dbus start

if [ "${REMOTE_DESKTOP}" = "kasmvnc" ]; then
    bash /start_kasmvnc.sh
else
    echo "REMOTE_DESKTOP=${REMOTE_DESKTOP} not supported"
    tail -f /dev/null
fi
