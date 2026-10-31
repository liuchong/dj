# 安装与使用

DJ 是本机常驻消息枢纽。安装服务、接入 IM、绑定 AI 会话和安装 Skill 是不同步骤；打包或复制文件不会自动完成其他步骤。各工具已有验证范围见[能力范围](release-scope.md)。

## 1. 准备运行包

运行环境为 macOS arm64 和 Bun 1.4.4。目录包不依赖开发仓库、node_modules、Emacs 或 Eliscript 编译器。

解压你实际取得的目录包，核对发布方提供的摘要，以及包内 `package-manifest.json` 的 build_id、文件摘要和运行时要求。本文不固定引用某次本地构建的文件名、字节数或 SHA256。

```sh
tar -xzf DJ_ARCHIVE.tar.gz
DJ_BUNDLE/bin/dj --help
```

`DJ_ARCHIVE` 和 `DJ_BUNDLE` 替换为实际归档与目录。`bin/dj` 从 PATH 找 Bun；launchd 等非交互宿主使用明确的 Bun 路径。运行包包含项目 `LICENSE`、依赖许可证、运行说明、占位配置与完整 Skill；不包含账号、数据库和客户端凭据。

## 2. 配置并启动服务

1. 在持久私有目录准备 `service.json`，默认根为 `~/.dj`。目录权限 0700，配置与凭据 0600。
2. 从包内 `config/service.example.json` 取用字段，只保留自己的获准连接与已有 AI 实例。`managed_profiles` 保持空。
3. Lark / 飞书使用官方 WebSocket 和 HTTPS API；user/bot 授权分别配置。AI endpoint 必须匹配真实进程、工作区和原生会话，不复制其他机器的 PID 或认证参数。
4. 前台运行并核对状态：

```sh
DJ_BUNDLE/bin/dj serve --config PRIVATE_SERVICE
```

在另一终端中使用自己的客户端 profile：

```sh
dj status --client-profile PRIVATE_PROFILE --json
```

持续运行可使用 [macOS 常驻服务](guides/macos-service.md)。具体配置与包结构见[运行手册](../packaging/runtime.md)。

## 3. 接通 AI 原会话

操作员通过 `catalog.refresh`、`session.resolve/probe` 找到准确实例与原对话，为接收对话准备独立 recipient profile 和 `target_constraint`。AI 使用自己的身份调用 `agent.whoami` 核对绑定；不能把 operator token 或其他会话的 profile 交给它。

| 工具 | 接线入口 |
| --- | --- |
| Codex / Cursor | [Desktop 配置](adapters/desktop.md)；Cursor 按需 Inspector 只用于 DJ 主动通知方向 |
| OpenCode | 已运行实例的本机 HTTP 接口与准确工作区，见[Agent 适配](adapters/agent-tools.md) |
| Pi | [原进程接收扩展](../connectors/pi/README.md)，显式加载到已有 TUI |
| Claude Code / Antigravity | [原生接收端](adapters/native-inboxes.md)与 `dj native configure` |

历史文件不等于活接收端。没有 receiver 时如实报告，不启动新 Agent CLI 来代替原会话。可选空会话创建受独立授权与实际原生能力约束，不是核心通知的前置条件。

管理员也可在 service.json 添加 `fixed_routes`，由 DJ 自动登记准确目标并建立订阅，无需 AI 主动操作。先按[固定接线](../skills/dj/references/fixed-routes.md)准备 operator、recipient、已有 endpoint 和来源连接，再合入包内 config/fixed-routes.example.json 的配置片段。首次尚未接通前不会补投历史消息。

## 4. 安装 Skill 和调用接口

```sh
dj skill targets
dj skill install --target codex --scope user --dry-run
dj skill config --target codex --client-profile PRIVATE_PROFILE
```

先检查预览，再按实际目标安装。安装不会覆盖不同内容或链接；`skill check` 核对文件，`skill config` 只生成 MCP 片段供显式合并，不修改客户端信任或启动模型。完整位置与流程见[客户端接线](../skills/dj/references/clients.md)。

CLI、本地 API、MCP 和 GEPO 共用操作目录和权限。MCP 是连接原服务的 stdio 薄代理；GEPO 使用同一私有 UDS，不是 MCP HTTP URL。不要为接线临时开放无认证公网端口。

## 5. 订阅、上下文与回复

由接收对话取得来源引用，调用 `subscription.preview` 核对目标和规则，再用 preview_id 创建。默认来源为当前主体获准的全部对话，可显式收窄到群、私聊或话题；默认 @ 与关键词、组合过滤共用核心。

- [Lark 实时订阅](guides/lark-realtime.md)：来源、过滤和原消息回复。
- [对话规则](../skills/dj/references/session-rules.md)：保存完整规则原文与固定回复映射。
- [消息上下文](specs/0007-message-context.md)：历史、引用和 thread，默认本地缓存。
- [主动消费与回调](../skills/dj/references/callbacks.md)：pull/ack 和可选原生 Hook，不创建后台轮询。

AI 通过信封中的 `reply_context_id` 显式调用 `message.reply`，由 DJ 固定账号与原位置。普通输出或最终回答不会自动发给 IM。收到不需回复的通知也要按处理结果结束 delivery，让处理中表情可靠清理。

无需 IM 或订阅时，获准调用者也可使用 `session.resolve/probe/send` 向精确已有会话输入。它与订阅通知共用队列、权限和 unknown 屏障。

## 排查与维护

消息未触发、结果未知、回复或表情异常时，按[故障排查](guides/troubleshooting.md)检查原台账，不换键重发。停止服务使用 SIGTERM/SIGINT 或 launchd bootout，等待 drain；不要强杀已有 AI 客户端。源码构建与打包见[开发指南](guides/development.md)。
