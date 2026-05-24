#!/bin/bash
export DISPLAY=:99
export RESOLUTION=1920x1200x24 

# 1. Start X virtual framebuffer
Xvfb $DISPLAY -screen 0 $RESOLUTION -ac +extension RANDR &
sleep 2

# 2. Paint the root window a dark blue so it doesn't look like a black void
xsetroot -solid "#2b3d50"

# 3. Start Fluxbox window manager
fluxbox >/dev/null 2>&1 &

# 4. Start VNC and Web VNC
x11vnc -display $DISPLAY -nopw -listen localhost -xkb -forever -shared >/dev/null 2>&1 &
websockify --web=/usr/share/novnc/ 5800 localhost:5900 >/dev/null 2>&1 &

# 5. (Optional) Open a terminal in the background for live debugging via VNC
xterm -bg black -fg white -geometry 80x24+10+10 &

# 6. Start Tor Browser with verbose logging
echo "Starting Tor Browser in debug mode..."
# We pipe the output to both the Docker log stream AND a file inside the container
/home/toruser/tor-browser/Browser/start-tor-browser --verbose 2>&1 | tee /home/toruser/tor-crash.log

# If the browser closes or crashes, this triggers to shut down the container cleanly
pkill Xvfb