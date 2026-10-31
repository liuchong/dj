# Slack

Slack 与 Lark 共用 DJ 的连接、订阅、过滤、上下文和回复接口。所有操作使用明确连接，不通过昵称猜身份，不需要 Slack 桌面端或外部 CLI。

## 连接

在 Slack 应用后台启用 Socket Mode，创建带 `connections:write` 的 app-level token。安装应用并取得 bot 或 user OAuth token；两种身份可同时配置，使用同一应用的 app token，DJ 自动共享应用事件流。

将下列连接加入已有 `service.json` 的 `connections`，不要覆盖原配置：

```json
{
  "connection_id": "slack-bot",
  "platform": "slack",
  "brand": "slack",
  "identity": "bot",
  "source_delivery": "events",
  "tenant_ref": "TEXAMPLE",
  "event_app_id": "AEXAMPLE",
  "event_subject_id": "UBOTEXAMPLE",
  "credential_ref": "secrets/slack-bot.json",
  "revision": 1,
  "identity_revision": 1,
  "event_scope": "all_authorized",
  "watches": [],
  "history_poll_seconds": 60
}
```

私有凭据文件权限 0600：

```json
{
  "app_id": "AEXAMPLE",
  "team_id": "TEXAMPLE",
  "app_token": "replace-with-app-level-token",
  "access_token": "replace-with-bot-or-user-oauth-token"
}
```

本人身份新增一个 connection，`identity=user`、`event_subject_id` 为本人 Slack user ID、凭据引用为本人 OAuth 文件。workspace/app 必须准确，`auth.test` 不一致拒绝接线。OAuth 安装与续期由操作员管理；更换凭据后身份会重新核对，不能把过期 token 当空收件。

`all_authorized` 接收应用事件中当前 token 可见的消息，并发现 HTTP 可访问频道；`configured` 只接收 watches 指定的 `chat_id`。watch 未指定 thread 时包括该频道的所有 thread。订阅再选 @、私聊、thread、关键词、人员和正反组合；全局黑名单只挡触发，保留消息可见度。

## Slack 应用权限

按所需会话类型为 **bot 和 user 分别**授权：

| 能力 | OAuth scopes / 事件 |
| --- | --- |
| 频道与会话发现 | channels:read、groups:read、im:read、mpim:read |
| 消息历史与实时收件 | channels:history、groups:history、im:history、mpim:history；message.channels、message.groups、message.im、message.mpim |
| 提及与表情事件 | app_mentions:read / app_mention；reactions:read / reaction_added |
| 发消息与消息操作 | chat:write；编辑/撤回仍受作者身份限制 |
| 表情与工作状态 | reactions:read、reactions:write |
| reaction 操作者类型 | users:read |

只授权实际需要的 scope，并在应用后台为对应 bot/user event subscriptions 登记事件。配置存在不代表 Slack 已授予权限。bot 在公共/私有频道的可见范围、thread 历史的 token 要求、Slack Connect 和应用分发类别以官方返回为准；不自动加群、不使用另一身份兜底。

## 调用与诊断

CLI、MCP、GEPO 共用 `connection.list/get/probe`、`conversation.list/resolve`、`message.list/get/context/history/recover`、`message.send/reply/recall/edit`、`message.reaction.*`、`subscription.*`、`session.rules.*`。消息 ID 保留 `CEXAMPLE:1793400000.000001` 整串；thread ID 只填根 `ts`。回复优先用通知的 `reply_context_id`，DJ 已固定身份及话题。

`pushpin` 是可配置主动标记的 emoji 名；`keyboard`/`eyes` 是 DJ 工作/已阅反馈，不添加为自己的触发表情。`delivery.complete` 或显式回复结束后由 DJ 负责清理工作表情，不依赖 AI 最终回答自动外发。

HTTP 默认每分钟一页补收，与实时 socket 分开观察；429 及缺权限显示降级。首次只取最近五分钟，已登记断点恢复分页；不能承诺没有观察过的旧 thread 或离线 reaction 重建，见 [0019](../specs/0019-slack.md)。无实际 workspace 凭据时只完成本地协议集成验收。
