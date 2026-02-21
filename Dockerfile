FROM nvidia/cuda:12.4.1-devel-ubuntu22.04

LABEL maintainer="schnicklfritz"
ENV DEBIAN_FRONTEND=noninteractive
ENV RESOLUTION=1920x1080

# 1. Install System Tools and XFCE (Virtualization packages removed)
RUN apt-get update && apt-get install -y --no-install-recommends \
   xfce4 xfce4-goodies \
   tigervnc-standalone-server \
   novnc websockify \
   supervisor sudo ssh \
   pulseaudio pavucontrol osspd \
   netcat-openbsd git curl wget nano ffmpeg zip unzip htop build-essential \
   python3-pip python3-dev \
   && apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. Configure Audio Bridge (PulseAudio to Web)
RUN apt-get update && apt-get install -y nodejs npm \
   && npm install -g audio-share-server || true \
   && apt-get clean && rm -rf /var/lib/apt/lists/*

# 3. Setup User "fritz"
RUN useradd -m -s /bin/bash fritz && \
   echo "fritz:qwerty" | chpasswd && \
   usermod -aG sudo fritz && \
   echo "fritz ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# 4. Install Miniconda as fritz (wget markdown syntax error fixed)
USER fritz
WORKDIR /home/fritz
RUN wget -q "https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh" -O /tmp/miniconda.sh && \
   bash /tmp/miniconda.sh -b -p /home/fritz/miniconda3 && \
   rm -f /tmp/miniconda.sh

ENV PATH="/home/fritz/miniconda3/bin:${PATH}"

# 5. Configs & Entrypoint (Switch back to root to handle volume logic)
USER root
COPY entrypoint.sh /entrypoint.sh
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
RUN chmod +x /entrypoint.sh

# Ports: SSH(22), VNC(5900), NoVNC(6080), Audio(8081), AI(8188, 7860, 8888), Future(9000-9010)
EXPOSE 22 5900 6080 8081 8188 7860 8888 9000-9010

ENTRYPOINT ["/entrypoint.sh"]

