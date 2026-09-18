# Use the base image
FROM openkylin/openkylin:3.0

# Enable privileged mode
USER root

# Set up environment variables to suppress interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Preconfigure the keyboard layout
RUN echo 'keyboard-configuration keyboard-configuration/layoutcode string us' | debconf-set-selections && \
    echo 'keyboard-configuration keyboard-configuration/layout select English (US)' | debconf-set-selections

# openKylin 官方源在多文件并发下载时会随机返回 502 Bad Gateway，先配置重试避免构建被瞬时故障打断
RUN printf 'Acquire::Retries "10";\nAcquire::http::Timeout "30";\nAcquire::https::Timeout "30";\n' > /etc/apt/apt.conf.d/99-retries

# 容器内 PID 1 不是 systemd，而 UKUI 部分包（kylin-nm 等）的 postinst 一旦检测到 systemctl 就会调用它，
# 因 systemd 未运行返回非 0，导致 kylin-nm 配置失败并连带 ukui-desktop-environment 元包失败。
# 基础镜像本身不带 systemctl，但安装过程中 systemd 包会引入真实版本覆盖普通 stub，
# 所以这里用 dpkg-divert 永久占位，后续安装的 systemd 会被分流到 /usr/bin/systemctl.distrib。
RUN dpkg-divert --local --rename --add /usr/bin/systemctl && \
    printf '#!/bin/sh\nexit 0\n' > /usr/bin/systemctl && \
    chmod +x /usr/bin/systemctl

# UKUI 多个包的 preinst/postrm 依赖 dpkg-architecture，基础镜像未自带 dpkg-dev，
# 不安装会导致 ukui-control-center / libukcc3 / ukui-media / ukui-power-manager 解包失败
RUN apt-get update && \
    apt-get install -y --no-install-recommends dpkg-dev && \
    rm -rf /var/lib/apt/lists/*

# Install necessary packages
# Installing ukui and vnc. Installing xfce4 solves grey screen issue
# 注意：useradd 是命令而非软件包，由 passwd 包提供；firefox 在 openKylin 官方源中可直接安装，
# 混用 Ubuntu 的 ppa:mozillateam/ppa 会给该发行版引入外来源，存在依赖冲突风险
# 必须使用 --no-install-recommends：推荐依赖会把 libimobiledevice6 拉进来，
# 它与 libimobiledevice-1.0-6 争抢同一个文件 /usr/lib/aarch64-linux-gnu/libimobiledevice-1.0.so.6。
# 后者虽然声明了 Breaks/Replaces，但约束写成 "<< 1.3.0-9"，而源里的版本是 1.3.0-ok1，
# 版本判定失配导致替换不生效，解包阶段报 "trying to overwrite ... which is also in package" 而构建失败。
# 同理不要执行 apt-get upgrade，它会引入同样的组合。
RUN apt-get update && \
    apt-get install -y --no-install-recommends tigervnc-standalone-server dbus-x11 xfce4 xfce4-goodies novnc python3-websockify python3-numpy python3-pip pipx cabextract tightvncserver htop software-properties-common && \
    apt-get install -y --no-install-recommends ukui-desktop-environment xauth xfce4-terminal sudo procps ca-certificates curl wget git x11-xserver-utils passwd firefox && \
    rm -rf /var/lib/apt/lists/* && \
	useradd \
        --create-home \
        --shell /bin/bash \
        --uid 1000 \
        codespace && \
    echo 'codespace ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/codespace && \
    chmod 0440 /etc/sudoers.d/codespace && \
    mkdir -p /home/codespace/.config && \
    chown -R codespace:codespace /home/codespace

# 注意：COPY 会沿用宿主机上的文件权限位，若仓库中该文件没有读权限，bash 将无法执行它，
# 因此这里统一显式设为 755
COPY vnc-start.sh /usr/local/bin/vnc-start.sh
RUN chmod 755 /usr/local/bin/vnc-start.sh
