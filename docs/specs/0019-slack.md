# 0019 Slack 接入

## 范围与架构

复用 0003 的扁平多连接管理、Rack 生命周期、接入去重、消息缓存、组合订阅、黑名单、原会话通知、固定身份回复及出站台账。新增平台适配，不复制 user/bot 业务树，不接入 AI 模型。

```text
packages/slack  官方 HTTPS / Socket Mode / 认证 / 有界响应 / 限流
       ↓
src/adapters/im/slack  账号隔离 / 原生消息与 thread / 持久收件及补收
       ↓
连接管理器 → 接入去重和历史 → 订阅过滤 → 已有 AI 对话
       ↑                              ↓
固定身份的消息发送、回复、编辑、撤回、表情与 working 清理
```

- `packages/slack/src/{client,socket,index}.eli` 独立实现官方协议，不依赖第三方 SDK、CLI 或 DJ；通过 host 注入 HTTPS、凭据、单调时钟和可选 WebSocket 工厂。
- `createSlackPort(config, host)` 是单一 user/bot 适配器。`auth.test` 核对 workspace、user ID 和 bot 身份；凭据每次解析，身份检查最多缓存一分钟，换 token 立即重查。
- 同应用只共享一个 Socket Mode 流，跨 workspace 也共享；Slack 多 socket 分摊事件，不能用独立身份 socket 冒充各自完整流。分发先核对 app/team，再用每条连接自己的 token 验证原生会话可见性；可见性缓存限 256 项、一分钟。身份、HTTP 补收断点和持久消息各自独立。
- envelope 必须在所有适用连接完成持久收件后 ACK。失败不 ACK，断连后重连；积压最多 32 帧 / 4MiB，单帧和响应最多 1MiB，收件缓冲有界。重试与 HTTP 补收复用同一个消息 source_key。

## Slack 原生语义

- workspace 使用 `tenant_ref`，主体为 `event_subject_id`；人员别名是 `platform=slack, scope=workspace:<team_id>, id=<user_id>`，禁止跨工作区猜同名人员。
- `native_message_id = channel_id:ts`，保留字符串原始小数，不能转浮点数生成 ID。`ts` 只在 channel 内唯一。`native_thread_id` 为根消息的原生 `thread_ts`；根、引用目标使用完整消息 ID。
- 支持消息和 `app_mention`、`reaction_added`；同消息双事件去重。编辑/删除可经主动原生读取查询当前内容，不作为新任务触发。
- @、私聊、原生 thread 回应、本人配置的主动表情标记复用现有订阅条件；emoji 为 Slack 原生名称，例如 `pushpin`，不是 Unicode 📌。普通表情与主动标记仍是独立条件。机器人触发是否屏蔽沿统一配置，不在适配器私设名单。
- 发送用 `chat.postMessage`，回复保留原 thread；编辑 `chat.update`、撤回 `chat.delete`，表情为 `reactions.get/add/remove`。平台只允许编辑/撤回当前身份可操作的消息，DJ 不绕过限制。
- working 使用 `keyboard`，知道了使用 `eyes`；共用持久状态机，完成、无需回复、失败和超时清理，保留预先存在的人工表情。原生 reaction ID 为 `emoji:user_id`，只撤自己的表情；用户列表可能不全，官方保证包含当前认证用户，不能把列表当成员全集。
- 出站请求未获确定结果记 unknown，不因断网或 5xx 重发；`client_msg_id` 为关联信息，不宣称平台提供无限期 exactly-once。

## HTTP 补收与限制

Socket Mode 实时为主。HTTP 按发现的可见 channel 或显式 watches 分页补收，原生 thread 用 `conversations.replies`；断点与该页消息同事务提交，整段分页完成后才推进水位，重启继续未完成页。首次连接从最近五分钟开始，不把任意历史当新任务。

`history_poll_seconds` 默认 60、最小 60 秒。history/replies 各方法预算按应用+workspace 共享；429 按 Retry-After 暂停，不自动重试写操作。每次泵最多一页，15 项；DJ 参数是保守预算，实际额度取决于 Slack 应用分发类别。频道数量和 thread 数量会影响追赶时延，`gap_status=possible` 不冒充完整覆盖。

已知限制：未被历史页或实时流观察到的旧 thread，不承诺离线补收；bot 的 channel thread 历史权限由 Slack 决定，失败会显示降级。HTTP 不重建离线期间每一次表情添加/撤销；实时 reaction 事件与历史消息是不同证据。缺权限不得当成没有新消息。

## 配置与权限

见 [Slack 使用说明](../guides/slack.md)。本任务不创建 workspace、不安装远程 Slack 应用、不借用现有 Lark 凭据，也不在没有凭据时宣称真实 Slack 验收成功。

## 施工与验收

- [x] 独立协议包、同应用共享 socket、身份校验与限流。
- [x] 适配器接入连接管理、持久收件、HTTP 分页补收和上下文。
- [x] 发送、固定身份回复、消息操作、working 与回声隔离；文档和 Skill。
- [x] 集成功能验收：协议传输、双身份分发、持久去重、重连/补收/限流、消息及 thread 操作。
- [x] 关键保护性单测：消息 ID、提及、身份和地址边界。
- [ ] 获准真实 Slack workspace 收发验收（需独立 Slack 凭据）。

官方依据：[Socket Mode](https://docs.slack.dev/apis/events-api/using-socket-mode/)、[限流](https://docs.slack.dev/apis/web-api/rate-limits/)、[消息](https://docs.slack.dev/reference/events/message/)、[表情读取](https://docs.slack.dev/reference/methods/reactions.get/)。

## 本地验证记录

本批以官方 HTTP/Socket Mode 协议替身连接真实 SQLite 与完整 Core：4 项 Slack 集成覆盖持久后 ACK、双身份可见性、去重、持久失败后重连、HTTP 断点、共享限流、订阅通知、thread 收发及 working 清理；15 项受影响公共集成回归通过。协议替身不代表真实 Slack 工作区通过。2 项新增保护性单测覆盖精确 ID、提及、workspace 隔离、凭据轮换、身份拒绝、端点和响应上界，并验证受影响公共单元用例。

公共 Lark HTTP 夹具同时对齐当前传输要求：明确 app ID、合法原生 ID、调用截止时间；不放宽 URL 校验或取消截止。Skill 正文通过 MDP/MDS 校验。未启动性能或其他 AI 工具的全套验收。
