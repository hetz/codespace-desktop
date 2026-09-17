# Use the base image
FROM openkylin/openkylin:3.0

# Enable privileged mode
USER root

# Set up environment variables to suppress interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Preconfigure the keyboard layout
RUN echo 'keyboard-configuration keyboard-configuration/layoutcode string us' | debconf-set-selections && \
    echo 'keyboard-configuration keyboard-configuration/layout select English (US)' | debconf-set-selections

# Install necessary packages
RUN apt-get update && \
    apt-get upgrade -y && \
	# Installing ukui and vnc. Installing xfce4 solves grey screen issue
    apt-get install -y tigervnc-standalone-server dbus-x11 xfce4 xfce4-goodies novnc python3-websockify python3-numpy python3-pip pipx cabextract tightvncserver htop software-properties-common && \
    apt-get install -y ukui-desktop-environment xauth xfce4-terminal sudo procps ca-certificates curl wget git x11-xserver-utils useradd && \
    rm -rf /var/lib/apt/lists/* && \
	useradd \
        --create-home \
        --shell /bin/bash \
        --uid 1000 \
        codespace && \
    echo 'codespace ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/codespace && \
    chmod 0440 /etc/sudoers.d/codespace && \
    mkdir -p /home/codespace/.vnc && \
    chown -R codespace:codespace /home/codespace


	# Remove dummy Firefox
    apt-get remove -y firefox && \ 
	# Install Firefox without Snap
	echo 'Package: firefox*\nPin: release o=LP-PPA-mozillateam\nPin-Priority: 1001' | tee /etc/apt/preferences.d/Mozilla && \
	add-apt-repository ppa:mozillateam/ppa && \
	apt-get update && \
    apt-get install -y firefox

COPY vnc-start.sh /usr/local/bin/vnc-start.sh
