FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV TOR_VERSION=16.0a6

# Added x11-xserver-utils for background color and xterm for debugging
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
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash toruser
RUN ln -s /usr/share/novnc/vnc.html /usr/share/novnc/index.html

USER toruser
WORKDIR /home/toruser

RUN wget -O tor.tar.xz --progress=bar:force "https://dist.torproject.org/torbrowser/${TOR_VERSION}/tor-browser-linux-aarch64-${TOR_VERSION}.tar.xz" \
    && tar -xJf tor.tar.xz \
    && rm tor.tar.xz

COPY --chown=toruser:toruser entrypoint.sh /home/toruser/entrypoint.sh
RUN chmod +x /home/toruser/entrypoint.sh

EXPOSE 5800

CMD ["/home/toruser/entrypoint.sh"]