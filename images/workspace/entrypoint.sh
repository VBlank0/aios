#!/bin/sh
# ==============================================================================
# aios 工作区入口脚本
# 打印当前代信息后保持容器常驻，方便 docker exec 进入操作。
# 系统文件在镜像层（只读），用户文件在共享卷 /home/user。
# ==============================================================================
set -e

GEN=$(cat /etc/aios-gen 2>/dev/null || echo "unknown")

echo "[aios] workspace gen=$GEN starting (pid $$)"
echo "[aios] system: /bin /etc (per-gen immutable image)"
echo "[aios] user:   /home/user (shared volume, survives checkout)"

# 常驻：保持容器运行，便于 exec 与健康探测
exec tail -f /dev/null
