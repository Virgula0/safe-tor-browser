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

# 4. Conditional SOCKS5 Proxy Bridge using Native Python Core
if [ "$EXPOSE_PROXY" = "true" ]; then
    echo "========================================================="
    echo "🚀 EXPOSE_PROXY=true: Launching Custom Python SOCKS5 Bridge!"
    echo "========================================================="
    python3 /home/toruser/proxy_bridge.py &
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