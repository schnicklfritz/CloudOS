FROM nvidia/cuda:12.4.1-devel-ubuntu22.04

LABEL maintainer="schnicklfritz"
ENV DEBIAN_FRONTEND=noninteractive
ENV RESOLUTION=1920x1080
ENV VNC_PASSWORD=qwerty

# 1. Base packages + ssl-cert (MUST be installed before KasmVNC)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ssl-cert \
    dbus dbus-x11 \
    openssh-server \
    xauth xfonts-base \
    xfce4 xfce4-goodies xfce4-session xfce4-terminal \
    supervisor sudo \
    pulseaudio pavucontrol \
    netcat-openbsd git curl wget nano ffmpeg zip unzip htop build-essential \
    python3-pip python3-dev nodejs npm \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. Setup user fritz (BEFORE KasmVNC install so we can add to ssl-cert)
RUN groupadd -r fritz && \
    useradd -r -m -s /bin/bash -g fritz fritz && \
    echo "fritz:qwerty" | chpasswd && \
    usermod -aG sudo,audio,video,ssl-cert fritz && \
    echo "fritz ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/fritz && \
    chmod 0440 /etc/sudoers.d/fritz

# 3. KasmVNC — install AFTER ssl-cert and user exist
RUN apt-get update && apt-get install -y \
    libyaml-tiny-perl libhash-merge-simple-perl liblist-moreutils-perl \
    libyaml-libyaml-perl libio-socket-ssl-perl libyaml-perl \
    libjson-perl libtry-tiny-perl libjson-xs-perl \
    libfile-slurp-perl libfile-which-perl libswitch-perl libipc-run-perl \
    libwww-perl libhttp-message-perl libhttp-daemon-perl libhttp-negotiate-perl \
    libdatetime-perl libdatetime-timezone-perl \
    && wget -q https://github.com/kasmtech/KasmVNC/releases/download/v1.4.0/kasmvncserver_jammy_1.4.0_amd64.deb \
    && dpkg -i kasmvncserver_jammy_1.4.0_amd64.deb \
    && apt-get -f install -y \
    && apt-get clean && rm -rf /var/lib/apt/lists/* *.deb

# 4. Miniconda as fritz
USER fritz
WORKDIR /home/fritz
RUN wget -q "https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh" -O /tmp/miniconda.sh && \
    bash /tmp/miniconda.sh -b -p /home/fritz/miniconda3 && \
    rm -f /tmp/miniconda.sh
ENV PATH="/home/fritz/miniconda3/bin:${PATH}"

USER root

# 5. Prep dirs
RUN mkdir -p /defaults /etc/kasmvnc /home/fritz/.vnc && \
    touch /home/fritz/.vnc/kasmvnc.passwd && \
    chmod 600 /home/fritz/.vnc/kasmvnc.passwd && \
    chown -R fritz:fritz /home/fritz/.vnc /etc/kasmvnc

# 6. Pass fritz's UID into supervisord env
RUN echo "FRITZ_UID=$(id -u fritz)" >> /etc/environment

# 7. Copy configs
COPY kasmvnc.yaml /defaults/kasmvnc.yaml
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# QuickPod: map port 6901 as HTTP service
EXPOSE 22 6901 8081 8188 7860 8888

ENTRYPOINT ["/entrypoint.sh"]
