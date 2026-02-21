FROM nvidia/cuda:12.4.1-devel-ubuntu22.04

LABEL maintainer="schnicklfritz"
ENV DEBIAN_FRONTEND=noninteractive
ENV RESOLUTION=1920x1080

# 1. Install minimal XFCE + essentials
RUN apt-get update && apt-get install -y --no-install-recommends \
    xfce4 xfce4-goodies xfce4-session \
    supervisor sudo ssh \
    pulseaudio pavucontrol \
    netcat-openbsd git curl wget nano ffmpeg zip unzip htop build-essential \
    python3-pip python3-dev nodejs npm \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# STRIP BLOOT (~3GB): manpages, docs, locales, cache
RUN apt-get purge -y man-db manpages-dev && \
    apt-get autoremove -y && \
    find /usr/share/doc -depth -type f -delete && \
    find /usr/share/man -depth -type f -delete && \
    rm -rf /usr/share/locale/* /usr/share/i18n/locales/* \
           /var/cache/apt/* /tmp/* /var/tmp/* && \
    apt-get clean && df -h

# 2. Setup User "fritz"
RUN useradd -m -s /bin/bash fritz && \
    echo "fritz:qwerty" | chpasswd && \
    usermod -aG sudo,audio,video fritz && \
    echo "fritz ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# 3. Miniconda as fritz
USER fritz
WORKDIR /home/fritz
RUN wget -q "https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh" -O /tmp/miniconda.sh && \
    bash /tmp/miniconda.sh -b -p /home/fritz/miniconda3 && \
    rm -f /tmp/miniconda.sh
ENV PATH="/home/fritz/miniconda3/bin:${PATH}"

USER root
# KasmVNC from GitHub .deb (not apt)
RUN apt-get update && apt-get install -y wget gnupg && \
    wget https://github.com/kasmtech/KasmVNC/releases/download/v1.4.0/kasmvncserver_jammy_1.4.0_amd64.deb && \
    sudo dpkg -i kasmvncserver_jammy_1.4.0_amd64.deb && \
    apt-get install -f -y && apt-get clean && \
    rm kasmvncserver_jammy_1.4.0_amd64.deb

    mkdir -p /usr/share/novnc /defaults && \
    chown -R fritz:fritz /etc/kasmvnc /home/fritz && \
    echo "fritz:qwerty" | kasmvncpasswd -f > /home/fritz/.vnc/passwd && \
    chmod 600 /home/fritz/.vnc/passwd

# Copy configs
COPY kasmvnc.yaml /etc/kasmvnc/kasmvnc.yaml
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 22 3000 6901 6080 8081 8188 7860 8888 9000-9010
ENTRYPOINT ["/entrypoint.sh"]

