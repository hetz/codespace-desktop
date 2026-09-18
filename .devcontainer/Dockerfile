# openKylin 3.0 Codespace 桌面 VNC
# 参照 AndnixSH/codespace-desktop，基座替换为 openkylin/openkylin:3.0
FROM openkylin/openkylin:3.0

USER root

# 禁止交互式提示
ENV DEBIAN_FRONTEND=noninteractive

# 预配置键盘布局（美式英语）
RUN echo 'keyboard-configuration keyboard-configuration/layoutcode string us' | debconf-set-selections && \
    echo 'keyboard-configuration keyboard-configuration/layout select English (US)' | debconf-set-selections

# 安装桌面与 VNC 组件
#  - 先装 dpkg-dev：ukui-control-center 的 preinst 脚本依赖 /usr/bin/dpkg-architecture，
#    而 openkylin 最小镜像未预装，必须先于 UKUI 安装
#  - ukui-desktop-environment-core : openKylin 原生 UKUI 桌面（核心组件）
#  - xfce4 / xfce4-terminal        : 轻量桌面兜底 + 可用终端（参考项目经验：部分桌面终端在 VNC 下打不开）
#  - tigervnc-standalone-server    : VNC 服务端
#  - novnc + python3-websockify    : 浏览器访问 VNC（WebSocket 代理）
#  - dbus-x11 / policykit-1        : 桌面会话依赖
#  - 中文字体                        : openKylin 中文显示
#  - firefox                        : 浏览器
#  - locales                        : 生成 zh_CN.UTF-8 语言环境
RUN apt-get update && \
    apt-get install -y dpkg-dev && \
    apt-get install -y --no-install-recommends \
        ukui-desktop-environment-core && \
    apt-get install -y \
        xfce4 \
        xfce4-terminal \
        xfce4-goodies \
        tigervnc-standalone-server \
        novnc \
        python3-websockify \
        dbus-x11 \
        policykit-1 \
        x11-utils \
        x11-xserver-utils \
        fonts-wqy-zenhei \
        fonts-noto-cjk \
        firefox \
        kylin-software-center \
        htop git curl wget ca-certificates sudo locales && \
    rm -rf /var/lib/apt/lists/*

# 生成中文语言环境
RUN sed -i 's/^# *zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen && \
    echo 'LANG=zh_CN.UTF-8' > /etc/default/locale

# 创建 Codespaces 习惯的非 root 用户（uid 1000，免密 sudo）
RUN useradd -m -u 1000 -s /bin/bash vscode && \
    echo 'vscode ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/vscode && \
    chmod 0440 /etc/sudoers.d/vscode

# 允许 vscode 用户访问图形/X 相关资源
RUN usermod -aG video,audio vscode || true

RUN set -eux; \
    url="$(curl -fsSL 'https://www.workbuddy.cn/v2/update?platform=workbuddy-linux-x64-deb' | \
        python3 -c 'import json,sys; print(json.load(sys.stdin)["url"])'); \
    curl -fL "$url" -o /tmp/workbuddy.deb; \
    dpkg-deb -I /tmp/workbuddy.deb | sed -n '1,35p'; \
    apt-get install -y /tmp/workbuddy.deb; \
    rm -f /tmp/workbuddy.deb
    
USER vscode
WORKDIR /home/vscode