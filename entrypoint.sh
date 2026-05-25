#!/bin/bash
export DISPLAY=:99
export RESOLUTION=1920x1200x24

# 1. Handle VNC Password Security
mkdir -p /home/toruser/.vnc
if [ -z "$VNC_PASSWORD" ]; then
    VNC_PASSWORD=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 12)
    echo "========================================================="
    echo "🔐 NO VNC PASSWORD PROVIDED. GENERATED: $VNC_PASSWORD"
    echo "========================================================="
else
    echo "========================================================="
    echo "🔐 VNC PASSWORD SECURED VIA ENVIRONMENT VARIABLE."
    echo "========================================================="
fi

# Synchronize system account password (Requires sudo)
echo "toruser:$VNC_PASSWORD" | sudo chpasswd

x11vnc -storepasswd "$VNC_PASSWORD" /home/toruser/.vnc/passwd >/dev/null 2>&1
chmod 600 /home/toruser/.vnc/passwd

# 2. Start X virtual framebuffer and UI (Runs natively as toruser)
Xvfb $DISPLAY -screen 0 $RESOLUTION -ac +extension RANDR &
sleep 2
xsetroot -solid "#2b3d50"

# 3. Create Desktop Menu
mkdir -p /home/toruser/.fluxbox
cat << 'EOF' > /home/toruser/.fluxbox/menu
[begin] (Desktop Menu)
  [exec] (🌐 Launch Tor Browser) {/home/toruser/tor-browser/Browser/start-tor-browser --verbose >> /home/toruser/tor-crash.log 2>&1}
  [exec] (⌨️ Launch Terminal) {xterm -bg black -fg white -geometry 80x24+10+10}
  [separator]
  [restart] (Restart Desktop)
[end]
EOF

fluxbox >/dev/null 2>&1 &
x11vnc -display $DISPLAY -rfbauth /home/toruser/.vnc/passwd -listen localhost -xkb -forever -shared >/dev/null 2>&1 &
websockify --web=/usr/share/novnc/ 5800 localhost:5900 >/dev/null 2>&1 &

# 4. Conditional SOCKS5 Proxy Bridge
if [ "$EXPOSE_PROXY" = "true" ]; then
    echo "========================================================="
    echo "🚀 EXPOSE_PROXY=true: Launching Authenticated Dante Server!"
    echo "========================================================="

    # Write config to a protected system directory (Requires sudo tee)
    cat << 'EOF' | sudo tee /etc/danted.conf >/dev/null
logoutput: stderr
internal: 0.0.0.0 port = 5801
external: 127.0.0.1
clientmethod: none
socksmethod: username

user.privileged: root
user.unprivileged: toruser

client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: error
}

socks pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: error
}

route {
    from: 0.0.0.0/0 to: 0.0.0.0/0 via: 127.0.0.1 port = 9150
    proxyprotocol: socks_v5
}
EOF

    # Start Dante daemon (Requires sudo)
    sudo danted -D &
else
    echo "========================================================="
    echo "🔒 EXPOSE_PROXY is not true. Port 5801 proxy is DISABLED."
    echo "========================================================="
fi

# 5. Start Tor Browser
echo "Starting Tor Browser in debug mode..."
/home/toruser/tor-browser/Browser/start-tor-browser --verbose >> /home/toruser/tor-crash.log 2>&1 &

# 6. Keep container alive
tail -f /dev/null