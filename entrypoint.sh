#!/bin/bash
export DISPLAY=:99
export RESOLUTION=1920x1200x24 

# 1. Start X virtual framebuffer
Xvfb $DISPLAY -screen 0 $RESOLUTION -ac +extension RANDR &
sleep 2

# 2. Paint the root window a dark blue
xsetroot -solid "#2b3d50"

# 3. Create a custom Right-Click Desktop Menu for Fluxbox
mkdir -p /home/toruser/.fluxbox
cat << 'EOF' > /home/toruser/.fluxbox/menu
[begin] (Desktop Menu)
  [exec] (🌐 Launch Tor Browser) {/home/toruser/tor-browser/Browser/start-tor-browser --verbose >> /home/toruser/tor-crash.log 2>&1}
  [exec] (⌨️ Launch Terminal) {xterm -bg black -fg white -geometry 80x24+10+10}
  [separator]
  [restart] (Restart Desktop)
[end]
EOF

# 4. Start Fluxbox window manager
fluxbox >/dev/null 2>&1 &

# 5. Start VNC and Web VNC
x11vnc -display $DISPLAY -nopw -listen localhost -xkb -forever -shared >/dev/null 2>&1 &
websockify --web=/usr/share/novnc/ 5800 localhost:5900 >/dev/null 2>&1 &

# 6. Start Tor Browser in the background for the first launch
echo "Starting Tor Browser in debug mode..."
/home/toruser/tor-browser/Browser/start-tor-browser --verbose >> /home/toruser/tor-crash.log 2>&1 &

# 7. Keep the container running indefinitely
# (This prevents the container from shutting down when you close Tor, allowing you to reopen it)
tail -f /dev/null