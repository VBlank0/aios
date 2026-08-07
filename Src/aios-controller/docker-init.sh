#!/usr/bin/env bash
# ==============================================================================
# docker-init.sh — Docker-in-Docker 启动入口
# 用途：在容器内拉起 dockerd，等它就绪后继续执行容器主进程。
# 优先使用 /etc/docker/daemon.json 里的 fuse-overlayfs（用户态 copy-on-write）；
# 若 fuse 不可用（如 /dev/fuse 缺失），自动回退 --storage-driver=vfs。
# ==============================================================================
set -e

DOCKER_LOG=/var/log/dockerd.log

start_dockerd() {
    echo "[docker-init] starting dockerd ..."
    nohup dockerd >"$DOCKER_LOG" 2>&1 &
}

wait_for_docker() {
    local i=0
    until docker info >/dev/null 2>&1; do
        i=$((i + 1))
        if [ "$i" -gt 60 ]; then
            echo "[docker-init] ERROR: dockerd failed to become ready; see $DOCKER_LOG" >&2
            return 1
        fi
        sleep 1
    done
    echo "[docker-init] dockerd is ready"
}

if docker info >/dev/null 2>&1; then
    echo "[docker-init] dockerd already running"
else
    start_dockerd
    if ! wait_for_docker; then
        echo "[docker-init] fuse-overlayfs failed, retrying with vfs storage driver ..."
        pkill dockerd 2>/dev/null || true
        sleep 2
        nohup dockerd --storage-driver=vfs >"$DOCKER_LOG" 2>&1 &
        wait_for_docker || exit 1
    fi
fi

exec "$@"
