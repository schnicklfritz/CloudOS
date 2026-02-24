#!/bin/bash

## ── one-time init ──────────────────────────────────────────────────────────
if [ ! -f "/init_flag" ]; then

    USER="${USER:-fritz}"
    PASSWORD="${PASSWORD:-qwerty}"
    UID_VAL="${UID:-1000}"
    GID_VAL="${GID:-1000}"

    update-alternatives --install /usr/bin/python python /usr/bin/python3 2

    groupadd -g "$GID_VAL" "$USER" 2>/dev/null || true
    useradd --create-home --no-log-init -u "$UID_VAL" -g "$GID_VAL" "$USER" 2>/dev/null || true
    usermod -aG sudo,ssl-cert "$USER"
    chsh -s /bin/bash "$USER"

    echo "root:${PASSWORD}" | chpasswd
    echo "${USER}:${PASSWORD}" | chpasswd

    echo "export PATH=/opt/miniconda3/bin:\$PATH" >> "/home/${USER}/.bashrc"

    echo "ok" > /init_flag
fi

USER="${USER:-fritz}"
PASSWORD="${PASSWORD:-qwerty}"

## ── SSH ────────────────────────────────────────────────────────────────────
ssh-keygen -A
/usr/sbin/sshd

## ── dbus ───────────────────────────────────────────────────────────────────
/etc/init.d/dbus start

## ── KasmVNC ────────────────────────────────────────────────────────────────
bash /start_kasmvnc.sh
