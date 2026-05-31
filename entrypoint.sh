#!/bin/bash
export DISPLAY=:99
export RESOLUTION=1920x1200x24

mkdir -p /home/toruser/.vnc
if [ -z "$VNC_PASSWORD" ]; then
    VNC_PASSWORD=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 12)
    echo "========================================================="
    echo "🔐 NO VNC PASSWORD PROVIDED. GENERATED: $VNC_PASSWORD"
    echo "========================================================="
else
    echo "========================================================="
    echo "VNC PASSWORD SECURED VIA ENVIRONMENT VARIABLE."
    echo "========================================================="
fi

x11vnc -storepasswd "$VNC_PASSWORD" /home/toruser/.vnc/passwd >/dev/null 2>&1
chmod 600 /home/toruser/.vnc/passwd

echo "Starting Xvfb..."
Xvfb $DISPLAY -screen 0 $RESOLUTION -ac +extension RANDR &
sleep 3

if ! xsetroot -solid "#2b3d50" 2>/dev/null; then
    echo "❌ ERROR: Xvfb failed to start. Check your configurations."
    exit 1
fi

echo "Setting desktop background..."
xsetroot -solid "#2b3d50" || true

echo "Starting clipboard synchronization..."
autocutsel -s PRIMARY >/dev/null 2>&1 &
autocutsel -s CLIPBOARD >/dev/null 2>&1 &

echo "Configuring xterm shortcuts (Ctrl+Shift+C / Ctrl+Shift+V)..."
cat << 'EOF' > /home/toruser/.Xresources
XTerm*VT100.Translations: #override \n\
    Ctrl Shift <Key>C: copy-selection(CLIPBOARD) \n\
    Ctrl Shift <Key>V: insert-selection(CLIPBOARD)
EOF
xrdb -merge /home/toruser/.Xresources || true

echo "Setting up desktop menu..."
mkdir -p /home/toruser/.fluxbox
cat << 'EOF' > /home/toruser/.fluxbox/menu
[begin] (Desktop Menu)
  [exec] (Launch Tor Browser) {/home/toruser/tor-browser/Browser/start-tor-browser --verbose >> /home/toruser/tor-crash.log 2>&1}
  [exec] (Launch Terminal) {xterm -bg black -fg white -geometry 80x24+10+10}
  [separator]
  [restart] (Restart Desktop)
[end]
EOF

echo "Starting Fluxbox, x11vnc, and websockify..."
fluxbox >/dev/null 2>&1 &
x11vnc -display $DISPLAY -rfbauth /home/toruser/.vnc/passwd -xkb -forever -shared >/dev/null 2>&1 &
websockify --web=/usr/share/novnc/ 5800 localhost:5900 >/dev/null 2>&1 &

if [ "$EXPOSE_PROXY" = "true" ]; then
    echo "========================================================="
    echo "EXPOSE_PROXY=true: Launching Custom Python SOCKS5 Bridge!"
    echo "========================================================="
    python3 /home/toruser/proxy_bridge.py &
else
    echo "========================================================="
    echo "EXPOSE_PROXY is not true. Port 5801 proxy is DISABLED."
    echo "========================================================="
fi

echo "Starting Tor Browser in debug mode /home/toruser/tor-crash.log"
/home/toruser/tor-browser/Browser/start-tor-browser --verbose >> /home/toruser/tor-crash.log 2>&1 &

echo "Container successfully started. Entering idle loop."
tail -f /dev/null