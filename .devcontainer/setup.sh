#!/usr/bin/env bash
# 容器创建后执行一次：设置 VNC 密码、生成会话脚本
set -euo pipefail

# 1. VNC 密码（默认 password，可用环境变量 VNC_PASSWORD 覆盖）
VNC_PASSWORD="${VNC_PASSWORD:-password}"
mkdir -p ~/.vnc
printf '%s\n%s\n' "${VNC_PASSWORD}" "${VNC_PASSWORD}" | vncpasswd -f > ~/.vnc/passwd
chmod 600 ~/.vnc/passwd

# 2. 会话脚本：优先 UKUI，8 秒内崩溃则自动回退 Xfce
install -m 0755 .devcontainer/session.sh ~/.vnc/session.sh

# 3. xstartup（兼容 vncserver 直接调用的场景）
cat > ~/.vnc/xstartup <<'XSTARTUP'
#!/bin/sh
exec "$HOME/.vnc/session.sh"
XSTARTUP
chmod +x ~/.vnc/xstartup

echo "VNC 密码已设置（默认 password，可用环境变量 VNC_PASSWORD 覆盖）；会话脚本就绪。"
