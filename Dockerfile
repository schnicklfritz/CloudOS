FROM kasmweb/ubuntu-jammy-desktop:1.18.0

USER root

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        nano \
        netcat-openbsd && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

USER 1000
