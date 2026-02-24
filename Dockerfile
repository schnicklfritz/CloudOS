FROM nvidia/cuda:12.4.1-devel-ubuntu22.04

LABEL maintainer="schnicklfritz"
ENV DEBIAN_FRONTEND=noninteractive

# Stage 1: pre-install (mirrors working pre_install.sh exactly)
RUN apt-get update && \
    apt-get install -y sudo vim gedit locales gnupg2 wget curl zip lsb-release bash-completion && \
    apt-get install -y net-tools iputils-ping mesa-utils software-properties-common build-essential && \
    apt-get install -y python3 python3-pip python3-numpy && \
    apt-get install -y openssh-server openssl git git-lfs tmux && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Stage 2: desktop packages (exact order from working history log)
RUN apt-get update && \
    apt-get install -y xfce4 terminator fonts-wqy-zenhei ffmpeg firefox dbus-x11 && \
    apt-get install -y ssl-cert && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Stage 3: KasmVNC (mirrors working install_kasmvnc.sh)
RUN apt-get update && \
    codename=$(lsb_release --short --codename) && \
    version=1.3.2 && \
    arch=$(dpkg --print-architecture) && \
    curl -fSL "https://github.com/kasmtech/KasmVNC/releases/download/v${version}/kasmvncserver_${codename}_${version}_${arch}.deb" \
        -o /tmp/kasmvncserver.deb && \
    apt-get install -y /tmp/kasmvncserver.deb && \
    rm /tmp/kasmvncserver.deb && \
    sed -i 's/exec xfce4-session/xset s off;&/' /usr/lib/kasmvncserver/select-de.sh && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Stage 4: Miniconda (system-wide so any user can use it)
RUN wget -q "https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh" -O /tmp/miniconda.sh && \
    bash /tmp/miniconda.sh -b -p /opt/miniconda3 && \
    rm -f /tmp/miniconda.sh && \
    /opt/miniconda3/bin/conda init bash
ENV PATH="/opt/miniconda3/bin:${PATH}"

# Stage 5: nodejs/npm extras
RUN apt-get update && \
    apt-get install -y nodejs npm && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy startup scripts
COPY docker_config/ /docker_config/
RUN chmod +x /docker_config/*.sh

# SSH config
RUN mkdir -p /var/run/sshd && \
    sed -i 's/#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config

# QuickPod: 6901=KasmVNC web, 22=SSH, 8188=ComfyUI, 7860=Gradio, 8888=Jupyter
EXPOSE 22 6901 8188 7860 8888

ENTRYPOINT ["/docker_config/entrypoint.sh"]
