#!/bin/sh
# ==============================================================================
# aios 健康探针
# 返回 0 = 健康；非 0 = 不健康（controller 据此判断是否需要回滚）
# 检查：系统标识文件存在 + 共享用户卷可写
# ==============================================================================
set -e

GEN_FILE=/etc/aios-gen

if [ ! -f "$GEN_FILE" ]; then
    echo "FAIL: gen file missing ($GEN_FILE)"
    exit 1
fi

GEN=$(cat "$GEN_FILE")

# 验证共享用户卷可写（各代共用）
if ! touch /home/user/.aios-probe 2>/dev/null; then
    echo "FAIL: /home/user not writable"
    exit 1
fi
rm -f /home/user/.aios-probe

echo "ok gen=$GEN uservolume=writable"
exit 0
