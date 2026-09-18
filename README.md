# openKylin 3.0 桌面 VNC (GitHub Codespaces)

```bash
docker run -it --rm -u codespace \
-p 5901:5901 \
-p 6080:6080 \
-e HOME=/home/codespace \
openkylin-vnc:final \
bash -c '/usr/local/bin/vnc-start.sh'
```

# How to use
1. Create a new space: https://github.com/codespaces/new
2. Select this repo `hetz/codespace-desktop`
2. Select this Branch `openkylin3`
3. Select a machine type. To unlock better machine types, file a ticket to Github: https://support.github.com/contact?tags=rr-codespaces%2Ccat_codespace
4. Click "Create codespace". It will take a while to create
5. Once created, open PORTS tab, open forwarded address, click on `vnc.html` link and enter your VNC password

https://github.com/codespaces/new?skip_quickstart=true&machine=standardLinux32gb&repo=1374824990&ref=openkylin3&devcontainer_path=.devcontainer%2Fdevcontainer.json&geo=SoutheastAsia

The default VNC password is just `password`. You can change it using `vncpasswd` in Terminal. You don't need to worry about weak password because the vnc ports are not public by default, accessing the ports requires your Github account to be logged in. This makes it a lot secure

The default keyboard layout is English (US). You can change it in Cinnamon settings

To run Windows app, install Wine: https://wiki.winehq.org/Ubuntu

# Limitations & bugs
- No audio support. See https://github.com/novnc/noVNC/issues/302
- No hardware acceleration because Codespace does not have a GPU
- Terminal won't open. Use Xfce Terminal or others instead




参照 [AndnixSH/codespace-desktop](https://github.com/AndnixSH/codespace-desktop)，将基座替换为 **openKylin 3.0**（`openkylin/openkylin:3.0`），提供：

- **Xfce 4.18** —— 默认桌面（参考项目验证过的稳定方案）
- **UKUI 4.24** —— openKylin 原生桌面，`VNC_DESKTOP=ukui` 切换（见下文）
- **TigerVNC** —— VNC 服务端（显示 :1，端口 5901，仅监听本机）
- **noVNC** —— 浏览器直接访问（端口 6080）
- **Firefox + 中文字体** —— 开箱即用的中文桌面

## 快速开始

1. **准备仓库**：把本目录内容推送到你的 GitHub 仓库（`.devcontainer/` 必须在仓库根目录）。
2. **创建 Codespace**：进入仓库页面 → **Code → Codespaces → Create codespace on \<分支\>**。
   - 首次创建会自动构建镜像（含桌面安装，约 5–15 分钟），之后秒级启动。
3. **等待就绪**：终端出现 `noVNC 已就绪: http://localhost:6080/vnc.html` 后，打开 **PORTS** 面板。
4. **访问桌面**：点击 `6080` 端口右侧的转发地址（形如 `https://<你的codespace名>-6080.app.github.dev`）→ 打开 `vnc.html` → 点击 **Connect** → 输入 VNC 密码。
   - **默认密码：`password`**，创建后可改：在 Codespace 终端执行 `vncpasswd`，或在 `.devcontainer/devcontainer.json` 的 `remoteEnv` 中预设 `VNC_PASSWORD`。

## 目录结构

```
.devcontainer/
├── devcontainer.json   # Codespace 配置：端口转发 6080、privileged、启动钩子
├── Dockerfile          # openkylin:3.0 + UKUI/Xfce + TigerVNC + noVNC
├── session.sh          # 会话脚本：Xfce 默认，VNC_DESKTOP=ukui 时优先 UKUI（8 秒看门狗）
├── setup.sh            # 容器创建后：设置 VNC 密码、安装会话脚本
└── start-vnc.sh        # 容器每次启动：dbus + Xvnc(5901) + 会话 + noVNC(6080)
```

## 访问链路

```
浏览器 → https://<codespace>-6080.app.github.dev (noVNC)
       → 127.0.0.1:6080 (novnc_proxy / websockify)
       → 127.0.0.1:5901 (Xvnc :1, VncAuth)
       → Xfce / UKUI 桌面
```

## 自定义

| 需求 | 方法 |
| --- | --- |
| 使用 UKUI 原生桌面 | `devcontainer.json` 中 `postStartCommand` 前增加 `remoteEnv`：`"VNC_DESKTOP": "ukui"`（或登录后 `VNC_DESKTOP=ukui ~/.vnc/session.sh`） |
| 修改 VNC 密码 | 创建后运行 `vncpasswd`，或在 `remoteEnv` 预设 `VNC_PASSWORD` |
| 屏幕分辨率 | 修改 `start-vnc.sh` 中 `Xvnc -geometry` 参数 |
| 安装更多软件 | Codespace 终端执行 `sudo apt install <包名>`（openKylin 官方源） |

## 实现要点（与参考项目的差异）

1. **`dpkg-dev` 前置安装**：openKylin 最小镜像未装 `dpkg-architecture`，而 `ukui-control-center` 的 preinst 脚本依赖它；不先装会直接构建失败。
2. **系统 dbus 自启**：openKylin 镜像没有微软 devcontainer base 自带的 docker-init，`start-vnc.sh` 会在启动时拉起 `/run/dbus/system_bus_socket`。
3. **会话外置启动**：openKylin 仓库的 TigerVNC 1.15 的 `Xvnc` 不支持 `-xstartup` 参数，改为 `Xvnc` 直启 + 单独执行 `session.sh` 启动桌面。
4. **图像解码依赖 bwrap（已实测自动降级）**：openKylin 3.0 的 gdk-pixbuf 通过 glycin + bubblewrap 沙箱解码 PNG/JPEG。实测确认：当 bwrap 因权限无法创建命名空间时，glycin 会自动降级为无沙箱解码（日志出现 `WARNING: Glycin running without sandbox.`），桌面照常渲染。真实容器均有 `/proc`，无论是否允许 userns 都能工作。

## 验证记录（2026-09 实测）

- ✅ VNC 链路：Xvnc RFB 握手、VncAuth 密码认证 —— 通过
- ✅ noVNC 链路：vnc.html 服务、WebSocket 升级、RFB 透传 —— 通过
- ✅ Xfce 桌面渲染：完整桌面 UI（壁纸、图标、面板、Dock）经 VNC 截图确认渲染正常
- ✅ UKUI：可启动（Peony 桌面/面板/菜单），部分组件在无头 VNC 下异常时自动回退 Xfce

## 已知限制

- 无音频、无 GPU 硬件加速（与参考项目一致）
- noVNC 端口默认不对外公开，需 GitHub 账号登录后经转发地址访问
- UKUI 在纯容器 VNC 环境下个别组件可能异常，Xfce 为已验证的稳定默认