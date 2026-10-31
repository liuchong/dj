# Slack 原生协议包

Eliscript 直接连接官方 Web API 和 Socket Mode，无第三方 SDK、CLI 或 DJ 依赖。

- `createSlackClient(config, host)`：`request(method, parameters, context)`、`socketUrl(context)`、`identity()`、`pendingWork()`、`close()`。
- config：`identity`、`credential_ref`、`tenant_ref`、`event_app_id`、`event_subject_id`、可选 `history_poll_seconds`。
- host：`credentials.resolve(ref)`、`fetch(url, options)`、`monoNow()`，可选 `budget_owner` 指向共享预算对象。context 接受 `deadline`（单调毫秒）和 `abort_signal`。
- `createSlackSocket(client, host)`：`subscribe(id, durableConsumer)`、`unsubscribe(id)`、`status()`；host 可注入 `webSocket(url)`。consumer 成功返回代表已持久化；所有消费者完成才 ACK，失败断连重试。有界队列、自动刷新/重连、关闭回收。
- `apiUrl(method)` 仅允许官方方法名，禁止外部 URL；请求不跟随重定向，有超时、1MiB 响应限制和共享 Retry-After 暂停。写操作不会自动重试。

包不处理账号安装、订阅、消息规则、AI、任务或原生字段到 DJ 的映射；这些归 DJ [平台接线](../../docs/specs/0019-slack.md)。
