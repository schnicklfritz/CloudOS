#!/bin/bash

## ── one-time init ──────────────────────────────────────────────────────────
if [ ! -f "/docker_config/init_flag" ]; then

    # defaults if QuickPod env vars not set
    USER="${USER:-fritz}"
    PASSWORD="${PASSWORD:-qwerty}"
    UID="${UID:-1000}"
    GID="${GID:-1000}"

    # python3 default
    update-alternatives --install /usr/bin/python python /usr/bin/python3 2

    # create group/user
    groupadd -g "$GID" "$USER" 2>/dev/null || true
    useradd --create-home --no-log-init -u "$UID" -g "$GID" "$USER" 2>/dev/null || true
    usermod -aG sudo,ssl-cert "$USER"
    chsh -s /bin/bash "$USER"

    # passwords
    echo "root:${PASSWORD}" | chpasswd
    echo "${USER}:${PASSWORD}" | chpasswd

    # miniconda available to user
    echo "export PATH=/opt/miniconda3/bin:\$PATH" >> "/home/${USER}/.bashrc"

    # persist env (minus secrets) for child processes
    env | grep -Ev "CMD=|PWD=|SHLVL=|_=|DEBIAN_FRONTEND=|HOME=|GID=|UID=|PASSWORD=" \
        > /etc/environment

    echo "ok" > /docker_config/init_flag
fi

## ── reload vars after init ─────────────────────────────────────────────────
USER="${USER:-fritz}"
PASSWORD="${PASSWORD:-qwerty}"

## ── SSH ────────────────────────────────────────────────────────────────────
ssh-keygen -A
/usr/sbin/sshd

## ── dbus ───────────────────────────────────────────────────────────────────
/etc/init.d/dbus start

## ── KasmVNC ────────────────────────────────────────────────────────────────
bash /docker_config/start_kasmvnc.sh
