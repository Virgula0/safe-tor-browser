#!/bin/bash
export DISPLAY=:99
export RESOLUTION=1920x1200x24

# 1. Handle VNC Password Security
mkdir -p /home/toruser/.vnc
if [ -z "$VNC_PASSWORD" ]; then
    # Generate a random 12-character password if the variable is empty
    VNC_PASSWORD=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 12)
    echo "========================================================="
    echo "🔐 NO VNC PASSWORD PROVIDED."
    echo "🔐 GENERATED RANDOM VNC PASSWORD: $VNC_PASSWORD"
    echo "========================================================="
else
    echo "========================================================="
    echo "🔐 VNC PASSWORD SECURED VIA ENVIRONMENT VARIABLE."
    echo "========================================================="
fi

# Store the password securely for x11vnc to use
x11vnc -storepasswd "$VNC_PASSWORD" /home/toruser/.vnc/passwd >/dev/null 2>&1
chmod 600 /home/toruser/.vnc/passwd

# 2. Start X virtual framebuffer
Xvfb $DISPLAY -screen 0 $RESOLUTION -ac +extension RANDR &
sleep 2

# 3. Paint the root window a dark blue
xsetroot -solid "#2b3d50"

# 4. Create a custom Right-Click Desktop Menu for Fluxbox
mkdir -p /home/toruser/.fluxbox
cat << 'EOF' > /home/toruser/.fluxbox/menu
[begin] (Desktop Menu)
  [exec] (🌐 Launch Tor Browser) {/home/toruser/tor-browser/Browser/start-tor-browser --verbose >> /home/toruser/tor-crash.log 2>&1}
  [exec] (⌨️ Launch Terminal) {xterm -bg black -fg white -geometry 80x24+10+10}
  [separator]
  [restart] (Restart Desktop)
[end]
EOF

# 5. Start Fluxbox window manager
fluxbox >/dev/null 2>&1 &

# 6. Start VNC and Web VNC (Notice -nopw is gone, replaced with -rfbauth)
x11vnc -display $DISPLAY -rfbauth /home/toruser/.vnc/passwd -listen localhost -xkb -forever -shared >/dev/null 2>&1 &
websockify --web=/usr/share/novnc/ 5800 localhost:5900 >/dev/null 2>&1 &

# 7. Start Tor Browser in the background for the first launch
echo "Starting Tor Browser in debug mode..."
/home/toruser/tor-browser/Browser/start-tor-browser --verbose >> /home/toruser/tor-crash.log 2>&1 &

# 8. Keep the container running indefinitely
tail -f /dev/null