#!/bin/sh
# 桌面会话启动脚本
#   VNC_DESKTOP=ukui -> UKUI（openKylin 原生，8 秒看门狗，失败自动回退 Xfce）
#   VNC_DESKTOP=xfce -> Xfce（默认，参考项目验证过的稳定方案）
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-$HOME/.xdg}"
mkdir -p "$XDG_RUNTIME_DIR" && chmod 700 "$XDG_RUNTIME_DIR"
[ -r "$HOME/.Xresources" ] && xrdb "$HOME/.Xresources"

if [ "${VNC_DESKTOP:-xfce}" = "ukui" ] && [ -x /usr/bin/ukui-session ]; then
    # UKUI 原生桌面：后台启动，8 秒看门狗，进程存活即保持，否则回退 Xfce
    dbus-launch --exit-with-session ukui-session >/tmp/ukui-session.log 2>&1 &
    SESS_PID=$!
    sleep 8
    if kill -0 "$SESS_PID" 2>/dev/null; then
        wait "$SESS_PID"
        exit $?
    fi
    echo "[session] ukui-session 提前退出，回退 Xfce（详见 /tmp/ukui-session.log）" >&2
fi

# 默认 / 兜底：Xfce
exec dbus-launch --exit-with-session startxfce4
