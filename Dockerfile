FROM ubuntu:24.04

# 避免交互式提示
ENV DEBIAN_FRONTEND=noninteractive

# 安装 systemd 和基础工具
RUN apt-get update && apt-get install -y \
    systemd \
    systemd-sysv \
    dbus \
    openssh-server \
    sudo \
    curl \
    wget \
    vim \
    htop \
    net-tools \
    iproute2 \
    iputils-ping \
    dnsutils \
    git \
    build-essential \
    ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 配置 SSH
RUN mkdir -p /run/sshd && \
    echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config && \
    echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config && \
    echo 'root:aios' | chpasswd

# systemd 需要这些
RUN systemctl mask \
    systemd-resolved.service \
    systemd-networkd.service \
    dev-hugepages.mount \
    sys-kernel-debug.mount \
    sys-kernel-tracing.mount \
    getty@.service \
    getty.target \
    console-getty.service \
    systemd-logind.service \
    systemd-hostnamed.service \
    systemd-localed.service \
    systemd-timedated.service \
    systemd-user-sessions.service

# 确保 /run 目录存在
RUN mkdir -p /run/systemd && \
    echo 'docker' > /run/systemd/container

# systemd 作为 PID 1
STOPSIGNAL SIGRTMIN+3
CMD ["/lib/systemd/systemd"]
