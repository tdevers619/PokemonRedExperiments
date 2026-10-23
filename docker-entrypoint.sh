#!/bin/sh
set -e
rm -f /tmp/.X99-lock /tmp/.X11-unix/X99
Xvfb :99 -screen 0 800x600x24 &
sleep 1
fluxbox >/dev/null 2>&1 &
x11vnc -display :99 -forever -nopw -quiet &
websockify --web /usr/share/novnc 6080 localhost:5900 &
echo "Open http://localhost:6080/vnc.html"
exec "$@"
