#!/bin/bash
CONTAINER_NAME="aios-workspace"
#判断用户权限
if [ "$(id -u)" -eq 0 ]; then
            SUDO=""
    else
                SUDO="sudo"
fi
#检查容器运行状态
if [ "$($SUDO docker inspect -f '{{.State.Running}}' "$CONTAINER_NAME" 2>/dev/null)" = "true" ]; then
            echo "容器 $CONTAINER_NAME 正在运行，直接进入..."
    else
                echo "容器 $CONTAINER_NAME 未运行，正在启动..."
                    $SUDO docker start "$CONTAINER_NAME" || { echo "启动容器失败！"; exit 1; }
fi

#进入容器
$SUDO docker exec -it "$CONTAINER_NAME" /bin/bash
