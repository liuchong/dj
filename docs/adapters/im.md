# IM 接入

Lark 的正式收件为官方 WebSocket 直连，读取、发送与回复为官方 HTTPS API 直连。实现使用 Bun 原生 WebSocket、fetch 和本项目有界 protobuf 编解码；不依赖 SDK、Lark CLI、桌面客户端或中转进程。产品行为以 [规格 0001](../specs/0001-lark-realtime-subscriptions.md) 为准。

## Lark 实时接入

`source_delivery: "events"` 请求 `/callback/ws/endpoint`，使用受保护 `app_id/app_secret` 获取官方 `wss` 地址；处理心跳、分片、连接关闭与重连。仅接受对应平台的官方域名及 TLS。事件 `im.message.receive_v1` 规范化后先提交 `im_event_inbox`，持久提交成功后回原生 ACK。现有 Core 再接收入库、去重、匹配订阅，并向精确原始 AI 会话投递。队列有界，存储失败不确认消息，状态通过 `connection.probe.event_source` 暴露。

配置示例（替换占位符，凭据文件仅当前用户可读）：

```json
{
  "connection_id": "lark-main", "platform": "lark", "brand": "lark",
  "identity": "bot", "credential_ref": "secrets/lark-app.json",
  "source_delivery": "events", "event_scope": "all_authorized",
  "event_app_id": "cli_example", "event_subject_id": "ou_example",
  "tenant_ref": "tenant-main", "account_ref": "account-main", "watches": []
}
```

`all_authorized` 指该应用在平台权限内实际收到的事件，不能据此宣称覆盖本人全部私聊或所有租户。`configured` 额外限定 watches 中的会话。未 @ 消息也进入 Core，默认订阅通过原生 mentions 元数据判断 `addressed_self`；显式关键词或 all/any/not 规则独立生效。

应用后台需启用长连接和 `im.message.receive_v1` 事件，并授权目标消息范围。平台仅提供部分事件时如实显示覆盖。`event_subject_id` 是默认 @ 指向的已核实身份，不从显示名推断。

## 本人发送、主动读取与机器人回复

`identity: "user"` 使用 `credential_ref` 引用已授权 OAuth 文件及 `user_identity: {"app_id":"cli_example","open_id":"ou_example"}` 锚定身份。凭据包含 `app_id`、`app_secret`、`user_access_token`、`refresh_token`、ISO `expires_at`。DJ 调用 `/open-apis/authen/v1/user_info` 核对本人；临近过期通过 `/open-apis/authen/v2/oauth/token` 刷新并原子保存轮换结果，不登录另一个账号、不回退机器人。

`identity: "bot"` 通过 `/open-apis/auth/v3/tenant_access_token/internal` 获取应用 token。读取为 `GET /open-apis/im/v1/messages`，发送为 `POST /open-apis/im/v1/messages`，回复为 `POST /open-apis/im/v1/messages/{message_id}/reply`。消息外发使用稳定幂等键；不确定结果先查台账和官方读回，不换键重发。WebSocket 是应用事件通道；本人/机器人 HTTP 授权与 WebSocket 应用鉴权分别核对。

`source_delivery: "poll"` 仅保留显式历史查询和有界补偿能力，不作为正常实时收件的替代。常驻服务应显式选择 events。权限错误记录原生错误码和真实 missing_scopes，不猜权限、不返回假空列表。

## 验收与维护

接通必须证明真实新消息 → WebSocket → Core → 订阅匹配 → 原生 IPC → 原会话接收；历史、编译成功或队列记录各自不能替代这一链路。调试仅在明确授权目标进行，不复制实际账号、会话或秘密到文档。原生验收控制器也直接调用 API，保留 unknown-before-send 台账和独立平台读回。

Telegram 保留现有官方 Bot API 接口与独立授权边界；本轮不扩展其真实验收范围。
