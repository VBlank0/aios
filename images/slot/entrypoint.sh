#!/bin/sh
# ==============================================================================
# aios 分区入口脚本
# 打印槽位标识后保持容器常驻，方便 docker exec 进入操作。
# 用 tail -f /dev/null 常驻：后续若要跑真实服务，可在此处替换为 exec 服务进程。
# ==============================================================================
set -e

SLOT_ID_FILE=/etc/aios-slot-id
SLOT_ID=$(cat "$SLOT_ID_FILE" 2>/dev/null || echo "unknown")

echo "[aios] slot $SLOT_ID starting (pid $$)"

# 常驻：保持容器运行，便于 exec 与健康探测
exec tail -f /dev/null
