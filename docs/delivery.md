# DJ 核心 Agent 交付与使用

DJ 0.1.0 当前交付本机消息枢纽，已接通 Codex、Cursor、OpenCode、Pi 和 Antigravity 的原会话通知。前四项已有独立身份回复原 Lark 消息及平台读回证据；Antigravity 已确认原生接收及独立 API 调用，模型额度不作为接线门禁。Claude Code 适配与协议验证已完成，实际 Code 会话收件待本机存在该实例时验证。以上均不以新建 Agent CLI 进程模拟接收。当前使用范围和限制见下文，历史结果见 [状态](status.md)。

## 运行包

成品为目录包，可整体搬至持久位置。需要 macOS arm64 和宿主提供的 Bun 1.4.4；不需要 Eliscript 编译器、构建仓库或 node_modules。包内 package-manifest.json 列出版本、build_id 与相对文件 SHA256，bin/dj 为入口。压缩包及其 SHA256 校验文件单独交付，不包含私有账号、客户端配置、数据库或验收日志。

包内 runtime.md 是完整运行手册，config 中是占位示例，skills/dj 是可安装的使用说明。解压和查看帮助不安装系统服务、不启动 AI，也不发送 IM 消息。

当前交付文件为 dj-0.1.0-macos-arm64-8ef5fb08.tar.gz（1,633,440 字节），SHA256 为 `a7eee5e459f92d56a7a8324568b62684374d6d5e96188fcf28529219aa7372ec`。包内 build_id 为 `dj-8ef5fb0884059677064b183cf8628efae862df6bc2a25a46ba9d088b6a524de8`；归档的 46 个载荷文件与 package-manifest.json 摘要逐项一致，共 47 个文件，入口和只读宿主 helper 的执行权限保留。包含已有 Codex/Cursor/OpenCode/Pi 接线，以及 Claude Code/Antigravity 原生适配和私有配置命令；真实客户端范围见下文。

```sh
tar -xzf DJ_ARCHIVE.tar.gz
DJ_BUNDLE/bin/dj --help
```

DJ_ARCHIVE 和 DJ_BUNDLE 替换为交付文件及解压目录。bin/dj 从 PATH 找 Bun；非交互宿主也可用确定的 Bun 路径执行 dist/src/interfaces/cli.mjs。

## 接通服务与原对话

1. 在 ~/.dj 准备受保护配置：目录 0700、配置和凭据 0600。从示例复制后只保留获准的连接和已有实例；managed_profiles 保持空。凭据只存受保护文件，不进提示词、日志、项目或命令参数。
2. Lark 使用专用机器人的 App ID/Secret 和准确的 watch；DJ 直接访问平台接口。Codex 使用已有 Desktop IPC；Cursor 可用已启用的 Desktop Bridge，或配置 DJ 管理 Inspector 的 native_api。先核对实际实例、版本、工作区和会话，不能复制另一台机器的 PID 或 origin。精确字段见 [Desktop 接线](adapters/desktop.md)。
3. 前台运行 `DJ_BUNDLE/bin/dj serve --config PRIVATE_SERVICE`。服务恢复与就绪后，用独立 operator profile 查询 status，执行 catalog.refresh、session.resolve/probe，确认精确原目标。
4. 为每个接收对话准备独立 recipient profile 和 target_constraint；不能把 operator token 给 AI，也不能用一个全局 recipient 冒充多个对话。按 [客户端说明](../skills/dj/references/clients.md)接线，调用 agent.whoami 核对实际绑定，然后登记目标。
5. 用 conversation.resolve/list 取得准确来源引用；subscription.preview 固定来源、过滤器、目标和策略，再通过 preview_id 创建订阅。消息经订阅到达原会话后，接收方使用信封中的 reply_context_id 显式调用 message.reply，并以 outbound.get 核对原生回复。未知结果查原操作，不换键重发。

所有客户端命令都通过 `--client-profile PRIVATE_PROFILE` 选择自己的身份。完整请求、幂等和暂停/撤销流程见 [Skill](../skills/dj/SKILL.md)和 [操作契约](interfaces/operations.md)。

不需要 IM 或订阅时，可由获准调用者使用 session.resolve/probe/send 向准确的已有会话发送输入。当前目录包已分别通过 Codex、Cursor 原会话的公开免订阅直发与原生标记读回，同键重放各只产生一条 direct delivery；不要求先登记 Agent，也不创建 Event、Contribution 或 IM 回复上下文。此路径与订阅通知共用队列、权限和 unknown 屏障。

## OpenCode 与 Pi

- OpenCode 连接已运行实例的本机 HTTP 接口，配置准确工作区与私有凭据；不新建 CLI，不替换模型。消息读取使用原生 limit/before 与不透明分页游标，限制响应预算。原 Desktop 调试会话已经完成公开直发/原生回复、同键去重、主 Skill/clients.md 实际摘要、独立 recipient API 和 Lark 原消息订阅回复，平台已读回。
- Pi 使用随包 [接收扩展](../connectors/pi/README.md)。使用者显式将 connectors/pi/extension.mjs 加入专用工作区 extensions，按 Pi 原生流程 reload 已有会话，再以私有 manifest 接入 DJ。该扩展在 Pi 自己的进程内调用 sendUserMessage；不启动替代 CLI、不发终端按键、不改模型。只暴露当前原生会话及有界近期消息，历史覆盖始终 partial，缺少接口的创建/启停明确 unsupported。
- Pi 已通过原 TUI 进程的真实验收：临时加载原生扩展后，DJ 经 socket 直发、原生条目读回、同键去重、主 Skill/clients.md 摘要、独立 recipient API 和 Lark 原消息订阅回复均成立。只为接线临时开启的 Inspector 已关闭；扩展留在当前 Pi 生命周期内，持久 settings 未改，重启后仍按扩展说明显式加载。没有新建或替换 Agent 进程。只有没有实例的工具才将真实验收留给用户。
- 两者调用 DJ 的 CLI/MCP/GEPO、订阅过滤器、提示词装配和主动 pull/ack 共用现有核心。每个会话仍需独立 recipient 与 target_constraint；Pi 不假设原生自带 MCP 客户端，可使用 CLI/本地 API。

## Claude Code 与 Antigravity

- 两端已接入正式端口装配和 `dj native configure --input PRIVATE_JSON`，详见[原生接收端说明](adapters/native-inboxes.md)。只连接已有本机进程，保留进程出生、原会话和准确工作区校验；无云端控制或 CLI 启动回退。
- Antigravity 原会话已实际完成公开直发/原生输入与回复读回、同键单 delivery、主 Skill/clients.md 摘要及独立 recipient 的 status/whoami。授权 Lark 消息也已按订阅进入同一原会话并 accepted；模型随后返回 429 额度耗尽，没有生成 IM 回复。按用户最新范围，模型实际工作不作为工具接线门禁；该额度状态与后续 IM 回复继续如实区分。
- Claude Code 的 native idle、delivered、held、refused、迟到确认与无 ACK 路径通过本地协议夹具；本轮只有 Claude Desktop，无运行中的 Code 会话及原生收件登记，真实 Code 收件待有实例时验证。适配与使用说明已交付，不新建替代 CLI 或等待用户开进程。

## AI 调用 DJ

- CLI、本地 JSON API、stdio MCP 和 GEPO 共用当前 63 个操作、权限与操作台账。AI 调用 DJ 不需要 Inspector；Inspector 仅用于 DJ 主动操作 Cursor 原会话。
- `dj skill install/check` 安装或核对使用说明；`dj skill config` 生成 MCP 片段供显式合并，不改现有客户端配置。GEPO 使用同一私有 UDS，不能作为 MCP HTTP 地址，也不为接线开放公网端口。
- 订阅的 instruction_policy 保存固定 prompt/task_template；DJ 按明确字段展开后与原消息投递，不做模型推理。delivery_mode=pull 可改用 subscription.pull/ack 主动领取与确认；消费确认不是任务完成。
- 可选 `dj skill hooks` 生成 Codex/Cursor 原生回调配置，`dj hook pull` 领取一项；不会自动启用、确认、创建模型进程或建立后台轮询。具体边界见 [回调说明](../skills/dj/references/callbacks.md)。

## 已知限制与交付边界

- Cursor native_api 是固定版本适配，当前验证 Cursor 3.27.14。manage_inspector 只临时开启自己管理的端口并在操作后关闭；既有调试端口保留。客户端升级、重启或工作区变化后需重新核对，不静默使用旧绑定或 CLI 回退。
- Codex/Cursor 的原会话通知与独立 API 回复已真实验证；配置生成、文件安装、模型读取与实际 MCP/Hook 触发是不同事实。Cursor 原对话已读取主 Skill 并调用 recipient API；Codex 新专用调试对话已读取主 Skill/clients.md 并调用两项只读 API，正确处理未绑定身份。Cursor 完整参考文件及两客户端实际 MCP/Hook 启用仍未验证；新调试对话不替代原订阅目标。接收方拒绝执行时如实报告，不能以一次回复文本冒充采用。
- Claude Code 的实际原生会话收件、其他 IM 的专项验收、创建空对话的可选增强及性能优化延后。既有 route-load 吞吐未达标与资源记录保留，不宣称达到完整性能目标，也不把它们重新作为本次主要业务交付的循环测试任务。
- 停机后不再运行周期 tick 补排观察任务，由 drain 等待既有任务并核对原绑定；本次修复恢复正常退出，未重新发送模型/IM 消息。
- 本交付不安装或启动常驻系统服务、不修改客户端信任、不发布到外部平台。结束前台服务使用 SIGTERM/SIGINT，保留 draining/unknown 事实；不强杀已有 AI 客户端。
