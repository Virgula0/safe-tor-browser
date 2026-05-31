FROM debian:bookworm-slim@sha256:0104b334637a5f19aa9c983a91b54c89887c0984081f2068983107a6f6c21eeb

ARG TARGETARCH
ENV DEBIAN_FRONTEND=noninteractive
ENV TOR_VERSION=16.0a6

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
    python3 \
    autocutsel \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /tmp/.X11-unix && chmod 1777 /tmp/.X11-unix

RUN useradd -m -s /bin/bash toruser
RUN ln -s /usr/share/novnc/vnc.html /usr/share/novnc/index.html

USER toruser
WORKDIR /home/toruser

COPY --chown=toruser:toruser script/fetch_tor.sh /home/toruser/fetch_tor.sh
RUN chmod +x /home/toruser/fetch_tor.sh && \
    /home/toruser/fetch_tor.sh "$TARGETARCH" "$TOR_VERSION" && \
    rm /home/toruser/fetch_tor.sh

COPY --chown=toruser:toruser script/proxy_bridge.py /home/toruser/proxy_bridge.py
COPY --chown=toruser:toruser entrypoint.sh /home/toruser/entrypoint.sh
RUN chmod +x /home/toruser/entrypoint.sh

EXPOSE 5800 5801

ENV PYTHONUNBUFFERED=1

CMD ["/home/toruser/entrypoint.sh"]