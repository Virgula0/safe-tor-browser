FROM debian:bookworm-slim

ARG TARGETARCH
ENV DEBIAN_FRONTEND=noninteractive
ENV TOR_VERSION=16.0a6

# Added 'sudo' to the list
RUN apt-get update && apt-get install -y --no-install-recommends \
    xvfb \
    x11vnc \
    novnc \
    websockify \
    fluxbox \
    wget \
    tar \
    xz-utils \
    ca-certificates \
    procps \
    libgtk-3-0 \
    libdbus-glib-1-2 \
    libx11-xcb1 \
    libxt6 \
    libpci3 \
    libasound2 \
    fonts-liberation \
    fonts-dejavu \
    x11-xserver-utils \
    xterm \
    dante-server \
    sudo \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash toruser
# Grant toruser passwordless sudo rights for initialization
RUN echo "toruser ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

RUN ln -s /usr/share/novnc/vnc.html /usr/share/novnc/index.html

USER toruser
WORKDIR /home/toruser

RUN if [ "$TARGETARCH" = "amd64" ]; then \
        TOR_ARCH="x86_64"; \
    elif [ "$TARGETARCH" = "386" ]; then \
        TOR_ARCH="i686"; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
        TOR_ARCH="aarch64"; \
    else \
        echo "CRITICAL ERROR: Architecture $TARGETARCH not supported by Tor Project." && exit 1; \
    fi && \
    wget -O tor.tar.xz --progress=bar:force "https://dist.torproject.org/torbrowser/${TOR_VERSION}/tor-browser-linux-${TOR_ARCH}-${TOR_VERSION}.tar.xz" && \
    tar -xJf tor.tar.xz && \
    rm tor.tar.xz

COPY --chown=toruser:toruser entrypoint.sh /home/toruser/entrypoint.sh
RUN chmod +x /home/toruser/entrypoint.sh

EXPOSE 5800 5801

# The Dockerfile now safely ends as the unprivileged user
CMD ["/home/toruser/entrypoint.sh"]