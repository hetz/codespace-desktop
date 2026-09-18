#!/bin/bash
#
# openKylin 3.0 桌面 VNC 启动脚本
#
# 两个必须注意的平台差异：
# 1. TigerVNC 1.15 已将用户目录迁到 XDG 路径 ~/.config/tigervnc。若 ~/.vnc 是真实目录会触发迁移逻辑，
#    而 openKylin 自带的 perl 5.36 中 File::Copy 并未导出 mv，迁移必然失败并导致 vncserver 直接退出。
#    因此这里直接使用新版目录，从源头绕开迁移代码。
# 2. vncserver 经 update-alternatives 指向 tigervncserver，支持 -geometry / -depth / -localhost no。

set -eux

VNC_DIR="$HOME/.config/tigervnc"
mkdir -p "$VNC_DIR"

if [ ! -f "$VNC_DIR/passwd" ]; then
    printf '%s\n' "${VNC_PASSWORD:-password}" | vncpasswd -f > "$VNC_DIR/passwd"
    chmod 600 "$VNC_DIR/passwd"
fi

cat > "$VNC_DIR/xstartup" <<'EOF'
#!/bin/sh

unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS

export XDG_CURRENT_DESKTOP=UKUI
export XDG_SESSION_DESKTOP=UKUI
export DESKTOP_SESSION=ukui

exec dbus-run-session -- /usr/bin/ukui-session
EOF

chmod +x "$VNC_DIR/xstartup"

# 清理残留进程，避免重复启动时端口被占用
pkill -f 'Xtigervnc.*:1' || true
pkill -f 'novnc_proxy.*6080' || true

tigervncserver :1 \
  -geometry "${VNC_GEOMETRY:-1920x1080}" \
  -depth 24 \
  -localhost no

/usr/share/novnc/utils/novnc_proxy \
  --vnc localhost:5901 \
  --listen 0.0.0.0:6080
