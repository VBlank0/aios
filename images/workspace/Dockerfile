# ==============================================================================
# aios generation 基础镜像
# 该镜像作为"代 0"的起点，之后每次 aios commit 都会从当前工作区生成新一代镜像。
# 系统文件在镜像层（只读、各代独立），用户数据在共享卷 /home/user（各代共用）。
# ==============================================================================
FROM alpine:3.21

# 基础工具：fish 便于交互
RUN apk add --no-cache bash fish \
    && echo "gen-0" > /etc/aios-gen

# ---- 用户文件区（各代共用）----
# /home/user 由共享卷挂载，换代不丢失
RUN mkdir -p /home/user

# 健康探针
COPY health.sh /usr/local/bin/health.sh
# 入口脚本（保持常驻）
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/health.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
