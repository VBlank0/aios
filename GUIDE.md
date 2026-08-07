# aios — Git 式多代快照系统

> 把 debian dev container 当作"grub 层 + 大文件夹"：所有用户/AI 操作都在工作区容器内完成，系统以**不可变镜像代（gen-N）**的形式管理，随时可回滚到任意一代，类似 git 的 commit / checkout / rollback。

## 架构

```
debian dev container（= grub 层 + 大文件夹）
│  只装 docker + controller(tools/aios) + 注册表(generations/ git 仓库)
├── gen-0 / gen-1 / ... / gen-N    系统镜像（快照，不可变）
├── aios-workspace                  ← 当前 checkout 的工作区容器
│        └── /home/user             共享用户卷（各代共用，换代不丢）
```

- **系统文件**（`/bin`、`/etc`…）= 在各代镜像里，只读、互相隔离
- **用户文件**（`/home/user`）= 共享卷，所有代读写同一份
- **回滚** = 回到 debian 层执行 `aios checkout <gen>`，停掉旧工作区、用目标代镜像重建

## 快速开始

### 1. 前置条件

- dev container 已按 `.devcontainer/` 配置重建（含 Docker-in-Docker，`--privileged`）
- dockerd 已运行：`docker info` 有输出即正常（入口脚本会自动拉起）
- 终端跑 docker 命令需**非沙箱模式**（VS Code 沙箱会拦截 `/var/run/docker.sock`）

### 2. 初始化（建 gen-0 并启动工作区）

```bash
cd /workspaces/aios
tools/aios init
```

会：
- 从 `images/workspace/Dockerfile` 构建基础镜像 `aios:base`，同时打标签 `aios:gen-0`
- 创建共享用户卷 `aios-userdata`
- 启动工作区容器 `aios-workspace`（挂载 `/home/user`）

### 3. 日常使用

**进入工作区（所有操作都在容器内）**

```bash
docker exec -it aios-workspace /bin/bash
```

**提交一代快照**（工作区有任何改动后）

```bash
tools/aios commit "描述这次改动"
```

**查看当前状态 / 历史**

```bash
tools/aios status     # 当前代、工作区运行状态、健康
tools/aios log        # 从 HEAD 往祖先的代历史
```

**切换 / 回滚**

```bash
tools/aios checkout 2     # 切到 gen-2（停旧工作区→用 gen-2 镜像重建）
tools/aios rollback       # 回到上一代（HEAD 的 parent）
```

## 安全模型（为什么 rm -rf / 都不怕）

1. **系统在镜像层，只读**：`docker exec aios-workspace rm -rf /bin` 只会破坏当前工作区的可写层，**镜像 `aios:gen-N` 不受影响**
2. **回滚 = 换镜像**：`aios checkout` 用目标代镜像重建工作区，系统立刻恢复
3. **用户数据在共享卷**：`aios-userdata` 独立于容器层，删容器、换代都不丢
4. **历史在 git 仓库**：`generations/` 是真实 git 仓库，每代一条 commit，可审计

**必须守住的边界**：
- AI 只能通过 `docker exec` 进工作区容器操作，**不要**把 dev container 的 dockerd root 权限暴露给 AI
- 不要 `docker rmi aios:gen-N`（镜像 = 出厂系统，删了才真没了）

## 实现细节

| 文件 | 作用 |
|---|---|
| `tools/aios` | 控制器（git 风格 CLI）：init/commit/checkout/rollback/log/status |
| `images/workspace/Dockerfile` | gen-0 基础镜像定义（系统 + 用户目录 + 健康探针） |
| `images/workspace/health.sh` | 健康探针（检查系统标识 + 用户卷可写） |
| `images/workspace/entrypoint.sh` | 工作区入口（打印代信息 + 常驻） |
| `generations/` | 注册表 git 仓库（每代一条 commit + JSON 元数据） |
| `generations/HEAD` | 当前代的数字 |
| `generations/json/gen-N.json` | 各代元数据（镜像、parent、message、时间戳） |

## 演示流程（已验证）

```bash
tools/aios init
# 在工作区写用户文件
docker exec aios-workspace sh -c 'echo hi > /home/user/notes.txt'
# 提交
tools/aios commit "add notes.txt"
# 模拟 AI 改坏系统
docker exec aios-workspace rm -rf /bin
# 一键回滚（系统恢复，用户文件保留）
tools/aios rollback
docker exec aios-workspace cat /home/user/notes.txt   # 还在
```

## 常见问题

- **`dockerd` 未运行**：`nohup dockerd --storage-driver=vfs >/var/log/dockerd.log 2>&1 &`
- **`aios:gen-0 not found`**：旧版本 bug，`docker tag aios:base aios:gen-0` 即可修复
- **镜像较大**：vfs 存储驱动每个代是完整副本，属正常现象（也可换 overlayfs 环境省空间）
