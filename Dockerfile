FROM nvidia/cuda:12.4.1-devel-ubuntu22.04

LABEL maintainer="schnicklfritz"
ENV DEBIAN_FRONTEND=noninteractive

# Stage 1: pre-install
RUN apt-get update && \
    apt-get install -y sudo vim gedit locales gnupg2 wget curl zip lsb-release bash-completion && \
    apt-get install -y net-tools iputils-ping mesa-utils software-properties-common build-essential && \
    apt-get install -y python3 python3-pip python3-numpy && \
    apt-get install -y openssh-server openssl git git-lfs tmux && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Stage 2: desktop packages (exact order from working image history)
RUN apt-get update && \
    apt-get install -y xfce4 terminator fonts-wqy-zenhei ffmpeg firefox dbus-x11 ssl-cert && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Stage 3: KasmVNC 1.3.2 (mirrors working install_kasmvnc.sh)
RUN apt-get update && \
    codename=$(lsb_release --short --codename) && \
    arch=$(dpkg --print-architecture) && \
    curl -fSL "https://github.com/kasmtech/KasmVNC/releases/download/v1.3.2/kasmvncserver_${codename}_1.3.2_${arch}.deb" \
        -o /tmp/kasmvncserver.deb && \
    apt-get install -y /tmp/kasmvncserver.deb && \
    rm /tmp/kasmvncserver.deb && \
    sed -i 's/exec xfce4-session/xset s off;&/' /usr/lib/kasmvncserver/select-de.sh && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Stage 4: Miniconda (system-wide)
RUN wget -q "https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh" -O /tmp/miniconda.sh && \
    bash /tmp/miniconda.sh -b -p /opt/miniconda3 && \
    rm -f /tmp/miniconda.sh
ENV PATH="/opt/miniconda3/bin:${PATH}"

# Stage 5: nodejs/npm
RUN apt-get update && \
    apt-get install -y nodejs npm && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# SSH config
RUN mkdir -p /var/run/sshd && \
    sed -i 's/#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Copy scripts from repo root
COPY entrypoint.sh /entrypoint.sh
COPY start_kasmvnc.sh /start_kasmvnc.sh
RUN chmod +x /entrypoint.sh /start_kasmvnc.sh

EXPOSE 22 6901 8188 7860 8888

ENTRYPOINT ["/entrypoint.sh"]
