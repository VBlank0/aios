# ==============================================================================
# 阶段 1：使用最新的 Debian Trixie (测试版) 作为开发基底
# ==============================================================================
FROM debian:trixie-backports

# 设置非交互模式，防止 apt-get 弹窗阻塞镜像构建
ENV DEBIAN_FRONTEND=noninteractive

# 切换为国内高带宽镜像源（这里使用阿里云，如果不需要可删掉这行 RUN）
# RUN sed -i 's/deb.debian.org/://aliyun.com' /etc/apt/sources.list.d/debian.sources || true


# ==============================================================================
# 阶段 2：基础工具与 LoongArch64 原生交叉工具链安装
# ==============================================================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    git \
    wget \
    ca-certificates \
    curl \
    pkg-config \
    # Debian Trixie 官方集成的龙芯新世界(New World)交叉工具链
    gcc-loongarch64-linux-gnu \
    g++-loongarch64-linux-gnu \
    # gdb代码调试工具
    gdb-multiarch \
    # ranger 文件管理器，方便我自己操作
    ranger \
    # ===== Docker-in-Docker：在容器内跑嵌套 Docker（A/B 分区用）=====
    # 注意：Debian trixie 中 docker.io 只提供 daemon(dockerd)，CLI 需单独装 docker-cli
    docker.io \
    docker-cli \
    # 控制器脚本使用（纯 stdlib，无需 pip）
    python3 \
    # 清理缓存以精简 Docker 镜像体积
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ==============================================================================
# 阶段 3：多架构(Multi-arch)与目标依赖环境准备
# ==============================================================================
# 如果你后续需要在容器内安装特定针对 loongarch64 的第三方 .deb 依赖库，
# 可以解除下方两行的注释，让 apt 支持直接拉取龙芯原生库（非必须，视项目而定）
# RUN dpkg --add-architecture loong64
# RUN apt-get update

# 设置工作目录
WORKDIR /workspace

# ==============================================================================
# 阶段 4：Docker-in-Docker 启动入口
# 容器一启动就先拉起 dockerd（等它就绪），再执行 VS Code 的主进程
# ==============================================================================
COPY docker-init.sh /usr/local/share/docker-init.sh
RUN chmod +x /usr/local/share/docker-init.sh

ENTRYPOINT ["/usr/local/share/docker-init.sh"]
