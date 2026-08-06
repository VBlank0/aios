#!/usr/bin/env bash
set -euo pipefail

AIOS_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$AIOS_ROOT"

IMAGE="aios:latest"
CONTAINER="aios-slot-a"

echo "============================================"
echo "  aios — 初始化 A/B 双系统 Docker 环境"
echo "============================================"
echo ""

# 1. 创建目录
echo "[1/4] 创建数据目录..."
mkdir -p volumes/slot-a volumes/slot-b volumes/shared images config
echo "  ✅ 目录就绪"

# 2. 构建镜像
echo "[2/4] 构建基础系统镜像 (Ubuntu 24.04 + systemd)..."
docker build -t "$IMAGE" .
echo "  ✅ 镜像构建完成: $IMAGE"

# 3. 停止旧容器
docker rm -f "$CONTAINER" 2>/dev/null || true

# 4. 启动 slot-a
echo "[3/4] 启动 slot-a 容器..."
docker run -d \
    --name "$CONTAINER" \
    --hostname aios \
    --restart unless-stopped \
    --privileged \
    --tmpfs /run \
    --tmpfs /run/lock \
    --tmpfs /tmp \
    -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
    -v "$AIOS_ROOT/volumes/slot-a:/var/lib/aios" \
    -v "$AIOS_ROOT/volumes/shared:/shared" \
    -p 2222:22 \
    "$IMAGE"

echo "  等待 systemd 初始化..."
sleep 5
echo "  ✅ slot-a 已启动"

# 5. 验证
echo "[4/4] 验证容器状态..."
if docker ps --format '{{.Names}}' | grep -q "^$CONTAINER$"; then
    echo "  ✅ 容器 $CONTAINER 运行正常"
else
    echo "  ❌ 容器启动失败！"
    docker logs "$CONTAINER"
    exit 1
fi

# 6. 导出基础镜像
echo ""
echo "导出基础镜像存档..."
docker save -o images/base.tar "$IMAGE"
echo "  ✅ 基础镜像已保存到 images/base.tar"

# 7. 初始化状态文件
cat > config/status.json << 'STATUSEOF'
{
  "active_slot": "A",
  "last_snapshot": null,
  "last_restore": null,
  "health_status": "healthy",
  "restore_count": 0
}
STATUSEOF
echo "  ✅ 状态文件已创建"

echo ""
echo "============================================"
echo "  🎉 aios 初始化完成！"
echo "============================================"
echo ""
echo "  进入容器:"
echo "    docker exec -it $CONTAINER bash"
echo "  SSH 连接:"
echo "    ssh root@localhost -p 2222  (密码: aios)"
echo ""
echo "  容器内就是你的\"宿主机\"，随便折腾！"
echo "  搞崩了后面用 snapshot/restore 恢复。"
