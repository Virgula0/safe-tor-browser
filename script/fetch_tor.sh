#!/bin/bash
TARGETARCH=$1
FALLBACK_VERSION=$2

if [ "$TARGETARCH" = "amd64" ]; then
    TOR_ARCH="x86_64"
elif [ "$TARGETARCH" = "386" ]; then
    TOR_ARCH="i686"
elif [ "$TARGETARCH" = "arm64" ]; then
    TOR_ARCH="aarch64"
else
    exit 1
fi

LATEST_VERSION=$(wget -qO- https://dist.torproject.org/torbrowser/ | grep -oE 'href="[0-9]+(\.[0-9]+)+[a-z0-9.-]*/"' | sed -e 's/href="//' -e 's/\/"//' | sort -rV | head -n 1)

if [ -n "$LATEST_VERSION" ] && wget -q --spider "https://dist.torproject.org/torbrowser/${LATEST_VERSION}/tor-browser-linux-${TOR_ARCH}-${LATEST_VERSION}.tar.xz"; then
    TOR_VERSION=$LATEST_VERSION
else
    TOR_VERSION=$FALLBACK_VERSION
fi

wget -O tor.tar.xz --progress=bar:force "https://dist.torproject.org/torbrowser/${TOR_VERSION}/tor-browser-linux-${TOR_ARCH}-${TOR_VERSION}.tar.xz"
tar -xJf tor.tar.xz
rm tor.tar.xz

echo "========================================================="
echo "Intalled $TOR_VERSION for arch $TOR_ARCH"
echo "========================================================="