#!/usr/bin/env bash
# 容器每次启动时执行：拉起 Xvnc(5900/5901) 与 noVNC Web 代理(6080)
set -euo pipefail

# 0. 确保系统 dbus 在运行（openKylin 镜像无 docker-init，需自启）
if [ ! -S /run/dbus/system_bus_socket ]; then
  sudo mkdir -p /run/dbus && sudo dbus-daemon --system --fork
  sleep 1
fi

# 清理可能残留的旧实例
pkill -x Xvnc 2>/dev/null || true
pkill -x websockify 2>/dev/null || true
pkill -x novnc_proxy 2>/dev/null || true
sleep 1

# 1. 启动 TigerVNC（显示 :1 → 端口 5901，仅监听 localhost，经 noVNC 代理对外）
mkdir -p ~/.vnc
Xvnc :1 \
  -geometry 1920x1080 \
  -depth 24 \
  -localhost \
  -noreset \
  -SecurityTypes VncAuth \
  -PasswordFile "$HOME/.vnc/passwd" \
  >/tmp/xvnc.log 2>&1 &

XVNC_PID=$!

# 2. 等待 X 就绪（最多 30 秒）
# 等待 Xvnc 就绪
VNC_READY=0

for _ in $(seq 1 30); do
  if ! kill -0 "$XVNC_PID" 2>/dev/null; then
    echo "Xvnc 启动失败："
    cat /tmp/xvnc.log
    exit 1
  fi

  if ss -lnt | grep -q ':5901 '; then
    VNC_READY=1
    break
  fi

  sleep 1
done


# 3. 启动桌面会话（VNC_DESKTOP=ukui 时优先 UKUI，8 秒看门狗；默认 Xfce）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -x "$HOME/.vnc/session.sh" ]; then
  DISPLAY=:1 nohup "$HOME/.vnc/session.sh" >/tmp/session.log 2>&1 &
elif [ -x "${SCRIPT_DIR}/session.sh" ]; then
  DISPLAY=:1 nohup "${SCRIPT_DIR}/session.sh" >/tmp/session.log 2>&1 &
fi

echo "VNC 已就绪: 127.0.0.1:5901 (显示 :1)"

# 4. 启动 noVNC 代理：浏览器访问 localhost:6080 -> 5901
NOVNC_DIR="${NOVNC_DIR:-/usr/share/novnc}"
if [ -x "${NOVNC_DIR}/utils/novnc_proxy" ]; then
  nohup "${NOVNC_DIR}/utils/novnc_proxy" --vnc 127.0.0.1:5901 --listen localhost:6080 >/tmp/novnc.log 2>&1 &
else
  nohup websockify --web "${NOVNC_DIR}" 6080 127.0.0.1:5901 >/tmp/novnc.log 2>&1 &
fi

# 5. 确认 6080 已监听
for _ in $(seq 1 15); do
  if (exec 3<>/dev/tcp/127.0.0.1/6080) 2>/dev/null; then exec 3>&-; break; fi
  sleep 1
done
echo "noVNC 已就绪: http://localhost:6080/vnc.html"
