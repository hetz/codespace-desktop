#!/bin/bash

set -eux

mkdir -p "$HOME/.vnc"

if [ ! -f "$HOME/.vnc/passwd" ]; then
    printf 'password\n' | vncpasswd -f > "$HOME/.vnc/passwd"
    chmod 600 "$HOME/.vnc/passwd"
fi

cat > "$HOME/.vnc/xstartup" <<'EOF'
#!/bin/sh

unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS

export XDG_CURRENT_DESKTOP=UKUI
export XDG_SESSION_DESKTOP=UKUI
export DESKTOP_SESSION=ukui

exec dbus-run-session -- /usr/bin/ukui-session
EOF

chmod +x "$HOME/.vnc/xstartup"

pkill -f 'Xtigervnc.*:1' || true
pkill -f 'novnc_proxy.*6080' || true

vncserver :1 \
  -geometry 1920x1080 \
  -depth 24 \
  -localhost no

/usr/share/novnc/utils/novnc_proxy \
  --vnc localhost:5901 \
  --listen 0.0.0.0:6080