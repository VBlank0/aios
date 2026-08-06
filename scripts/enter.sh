#!/usr/bin/env bash
# 快速进入 aios 容器的终端
set -euo pipefail

CONTAINER="${1:-aios-slot-a}"

if docker ps --format '{{.Names}}' | grep -q "^$CONTAINER$"; then
    docker exec -it "$CONTAINER" bash
else
    echo "❌ 容器 $CONTAINER 未运行"
    echo "   请先执行: bash scripts/setup.sh"
    exit 1
fi
