# AGENT-PLAN.md — aios Agent 集成实施计划

> 目标：在 aios-workspace 内预装一个**开源、MIT、纯 Python、龙芯可编译**的 TUI agent（gptme），
> 并做成像 VS Code Ctrl+Alt+I 的分屏体验（上：ranger/终端 log；下：AI 对话）；
> 每次 AI 操作自动快照（`aios commit`），出事自动回滚（`aios rollback`）。

---

## 0. 背景与动机

- aios 目前是一套"git 风格多代快照系统"：系统文件在各代镜像（不可变、可回滚），
  用户数据在共享卷 `/home/user`（各代共用、换代不丢）。
- 接下来要接入一个 **TUI 驱动的 AI agent**（类似 Claude Code），让它成为 aios-workspace 内的主力工具。
- 硬性要求：**开源、可从源码编译、必须有龙芯（loongarch64）版本**。

---

## 1. 已确认的决策（来自讨论）

| 决策点 | 结论 |
|---|---|
| Agent 底座 | **gptme**（MIT 许可，Python 84.7%，TUI 由 Textual 驱动） |
| 安装位置 | **aios-workspace 容器内**，`aios init` 时自动预装 |
| 合法性 | MIT 完全合法，无需 Claude 泄露代码等灰色来源 |
| 龙芯可行性 | 纯 Python + 官方 `minimal` extra 明确支持非 x86（ARM/musl/Termux/Lambda） |
| 文件管理 | 与 **ranger**（Python）结合，同一套 Python 生态 |
| 分屏布局 | 上半 ranger/终端 log，下半 AI 对话，快捷键切换（仿 VS Code Ctrl+Alt+I） |
| 快照保险 | 每次 AI 工具调用前 `aios commit`，调用后健康检查，坏了 `aios rollback` |
| 实施节奏 | 先文档评审（本文件），再动手实施 |

---

## 2. 为什么选 gptme（实证依据）

- **MIT 许可**：完全开源合法，可自由修改、编译、商用
- **纯 Python**（84.7%）：解释型、架构无关，龙芯可直接运行
- **官方龙芯友好**：`pyproject.toml` 里 `minimal` extra 注释明确写着
  `no native extensions beyond pydantic-core; works on ARM/musl/Termux/Lambda`
  → 唯一原生依赖是 `pydantic-core`，其余全纯 Python
- **内置 hooks/插件系统**（`auto_snapshots`、`hooks`）：正好对接 aios 的 commit/rollback
- **支持 DeepSeek**（`DEEPSEEK_API_KEY`）：与当前模型一致
- **TUI**：`gptme-tui`（Textual 驱动），满足"TUI agent"要求
- **其它备选**（记录备查）：
  - aider：Python 80%、Apache-2.0、强 git 集成，原生依赖更少（龙芯降级备选）
  - goose：Rust 70.4%、Apache-2.0、Linux Foundation，龙芯需 Rust 编译
  - opencode：TypeScript 75.7%、MIT、最火（195k stars），但 Node 龙芯支持较弱

---

## 3. 目标架构

```
aios-workspace 容器（alpine:3.21）
├── ranger          ← 文件管理器（上分屏）
├── gptme-tui       ← AI 对话（下分屏，快捷键呼出）
├── aios 快照插件    ← hook 自动 commit/rollback（快照保险）
└── /home/user      ← 共享用户卷（AI 产出存这里，换代不丢）

分屏体验（tmux 实现）：
┌──────────────────────────────┐
│ 上半：ranger 或 终端 log      │  ← root@aios-workspace#
├──────────────────────────────┤
│ 下半：gptme-tui AI 对话       │  ← 快捷键（如 Ctrl+Space）切换
└──────────────────────────────┘
```

数据流：
```
用户/AI 操作 → gptme 工具调用 → [hook: aios commit 快照] → 执行
                                                ↓ 失败/健康检查不过
                                        [hook: aios rollback] → 恢复
```

---

## 4. 实施阶段（每阶段独立可验证）

### 阶段 A：x86 当前环境跑通（预计 0.5-1 天）

**A1. 预装方案设计**
- 修改 `images/workspace/Dockerfile`：
  - `apk add python3 py3-pip git tmux ranger`
  - 写 `setup-agent.sh`（首次启动时运行）：`pip install 'gptme[minimal,tui]'`
  - alpine 是 musl，pip 原生依赖需编译，用 `minimal` extra（只带 pydantic-core）
- 修改 `entrypoint.sh`：启动后自动跑 setup + 提示快捷键

**A2. 写 gptme 快照插件**
- 新建 `images/workspace/agent/aios_hooks.py`（gptme hook 插件）：
  - 工具调用前 → `aios commit "pre-tool: <tool>"`（或记录未提交状态）
  - 工具调用后 → 跑 `health.sh`；失败 → `aios rollback`
  - 通过 gptme 的 `hooks` 机制注册（参考官方 `auto_snapshots` 插件写法）
- 配置 `~/.config/gptme/config.toml` 里启用该插件 + DeepSeek provider

**A3. 分屏布局脚本**
- 新建 `images/workspace/agent/session.sh`：
  - 用 tmux 开一个会话，两个 pane
  - pane 0（上）：ranger（或 shell log）
  - pane 1（下）：gptme-tui
  - 快捷键（如 `Ctrl+Space`）绑定：`select-pane -t 1` + 切换底部输入到 gptme
- 验证：能呼出/隐藏 AI 对话，ranger 与 gptme 同屏共存

**A4. 端到端测试（x86）**
- `aios init` → 容器内有 gptme + ranger + tmux
- 在容器内启动 session → 上半 ranger、下半 gptme
- 让 gptme 干活（改文件）→ 观察自动 commit
- 人为破坏系统 → 观察自动 rollback，用户数据不丢

### 阶段 B：龙芯（AOSC qemu 虚拟机）编译（预计 1-2 天）

**B1. 环境准备**
- 在 AOSC loongarch64 qemu 虚拟机内：
  - 装 Python 3.10+、Rust 工具链（`rustup target add loongarch64-unknown-linux-gnu`）
  - 装 gcc、git、pip

**B2. 编译 pydantic-core（唯一原生依赖）**
- 优先：`pip install 'gptme[minimal]'`，让 pip 尝试找 loong64 wheel
- 若无 wheel：从源码编译 `pydantic-core`（Rust，龙芯官方支持 → 应可编译）
- 若 Rust 编译耗时/失败：降级方案见第 6 节

**B3. 验证**
- `gptme --version` 在龙芯跑通
- `gptme-tui` 能启动（Textual 纯 Python）
- 复跑阶段 A 的端到端测试

### 阶段 C：集成固化（预计 0.5 天）

- 把 gptme + 插件 + session.sh + ranger + tmux 全部打进 `images/workspace/Dockerfile`
- `aios init` 一键获得完整环境
- 更新 `GUIDE.md` + 写 `MIGRATION.md`（龙芯步骤）

---

## 5. 龙芯编译风险与降级方案

| 风险 | 概率 | 降级方案 |
|---|---|---|
| `pydantic-core` 无 loong64 wheel，需 Rust 编译 | 高 | Rust 官方支持 loongarch64，编译应可行；耗时可用缓存 |
| Rust 在 qemu 龙芯上编译极慢 | 中 | 用 `--no-build-isolation` + 系统包；或换 aider（依赖更少原生） |
| Textual TUI 在龙芯异常 | 低 | 降级用非 TUI 的 `gptme`（交互式 CLI 也可用） |
| alpine 无 loong64 包（apk） | 低 | 3.21 起官方支持 loongarch64 ✅ |
| pip 在 musl 下编译失败 | 中 | 用 `--only-binary` 优先 wheel；或换 debian 系 workspace 镜像 |

---

## 6. 相关文件清单

- `images/workspace/Dockerfile` — 预装 python3/pip/git/tmux/ranger + setup-agent.sh
- `images/workspace/entrypoint.sh` — 启动时跑 setup-agent + 提示快捷键
- `images/workspace/agent/aios_hooks.py` — gptme 快照插件（commit/rollback hook）
- `images/workspace/agent/session.sh` — tmux 分屏布局（ranger + gptme-tui）
- `images/workspace/agent/config.toml` — gptme 配置（DeepSeek + 插件）
- `tools/aios` — 保持不动（插件通过 docker exec 调它）
- `GUIDE.md` / `MIGRATION.md` — 文档更新

---

## 7. 验证清单

- [ ] A1: `aios init` 后容器内有 gptme/ranger/tmux（`which gptme ranger tmux`）
- [ ] A2: 改文件时 gptme 触发自动 commit（`aios log` 出现新代）
- [ ] A2: 破坏系统后自动 rollback，`/home/user` 数据不丢
- [ ] A3: tmux 分屏可呼出/隐藏 AI 对话，快捷键生效
- [ ] B: 龙芯虚拟机上 `gptme --version` + `gptme-tui` 启动成功
- [ ] C: 重新 `aios init` 全流程一键可用

---

## 8. 范围边界

**包含**：gptme 集成、快照 hook、分屏布局、龙芯编译指南、文档

**不包含**（后续再议）：
- gptme 大规模定制 / 从零写 agent（先基于成熟底座）
- 自动调度 / 常驻 autonomous loop（可用 gptme-agent-template 后续扩展）
- 多 agent 并行协作
- 用户数据本身的快照/备份（另立话题，见历史讨论）

---

## 9. 附注：已有基础设施（快照机制回顾）

- `tools/aios`：git 风格控制器（init/commit/checkout/rollback/log/status）
- 系统文件在各代镜像（fuse-overlayfs 层共享、只存差异、保留窗口默认 10 代）
- 用户数据在共享卷 `aios-userdata` → `/home/user`
- `boot.sh`：便捷进入工作区容器的脚本（`docker start` + `docker exec -it bash`）
- 健康探针：`/usr/local/bin/health.sh`（返回 0 = 健康）
