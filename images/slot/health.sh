#!/bin/sh
# ==============================================================================
# aios 分区健康探针
# 返回 0 = 健康；非 0 = 不健康（controller 会据此切换分区）
# ==============================================================================
set -e

SLOT_ID_FILE=/etc/aios-slot-id

if [ ! -f "$SLOT_ID_FILE" ]; then
    echo "FAIL: slot id file missing ($SLOT_ID_FILE)"
    exit 1
fi

SLOT_ID=$(cat "$SLOT_ID_FILE")
echo "ok slot=$SLOT_ID"
exit 0
