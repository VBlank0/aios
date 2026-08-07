# ==============================================================================
# aios A/B 分区基础镜像
# 同一个 Dockerfile 通过 --build-arg SLOT_ID=A|B 构建出两个分区镜像。
# 每个分区容器：
#   - 在 /etc/aios-slot-id 写入自己的槽位标识（A 或 B）
#   - 提供 health.sh 健康探针（返回 0 = 健康）
#   - 入口脚本保持容器常驻，可随时 docker exec 进去操作
# ==============================================================================
FROM alpine:3.20

# 槽位标识：构建时传入 --build-arg SLOT_ID=A（或 B）
ARG SLOT_ID=unknown

# 基础工具：bash 便于交互，busybox 自带 sh
RUN apk add --no-cache bash \
    && echo "$SLOT_ID" > /etc/aios-slot-id \
    && mkdir -p /data

# 健康探针
COPY health.sh /usr/local/bin/health.sh
# 入口脚本（保持常驻）
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/health.sh /usr/local/bin/entrypoint.sh

# 可选：暴露健康检查端口（后续 controller 可用 HTTP 探测）
# EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
