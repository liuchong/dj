# OpenClaw 与 Hermes 本机接线

在 DJ 私有服务配置的 `agent_endpoints` 中添加端点。下例把两个原生服务作为独立实例使用，`directory` 改为本机获准的绝对目录。

```json
[
  {
    "tool": "openclaw",
    "instance_id": "openclaw-local",
    "native_namespace": "openclaw-local",
    "ownership": "existing",
    "endpoint_ref": "openclaw-local",
    "base_url": "http://127.0.0.1:18789",
    "directory": "/home/operator/.openclaw/workspace",
    "workspace_ref": "openclaw-workspace",
    "workspace_scope": "instance",
    "credential_ref": "secrets/openclaw-gateway.token"
  },
  {
    "tool": "hermes",
    "instance_id": "hermes-local",
    "native_namespace": "hermes-local",
    "ownership": "existing",
    "endpoint_ref": "hermes-local",
    "base_url": "http://127.0.0.1:9119",
    "directory": "/home/operator/projects",
    "workspace_ref": "hermes-workspace",
    "workspace_scope": "instance",
    "credential_ref": "secrets/hermes-gateway.token"
  }
]
```

- OpenClaw 使用正在运行的 Gateway。凭据文件可以保存 Gateway token，或者引用具有同等私有权限且包含 `gateway.auth.token` 的 OpenClaw 原始配置。Gateway 连接须授予 `operator.read` 和 `operator.write`。会话创建的工作区仍由 Gateway 核验。[OpenClaw Gateway 协议](https://docs.openclaw.ai/gateway/protocol/transport)
- Hermes 使用 `hermes serve --host 127.0.0.1 --port 9119 --skip-build` 或已连接到同一原生协议的后台服务。以 `HERMES_DASHBOARD_SESSION_TOKEN=file:/path/to/private-token` 将同一私有 token 文件交给 Hermes。DJ 通过 WebSocket 输入，通过同一服务的 HTTP 接口读回。[Hermes Desktop](https://hermes-agent.nousresearch.com/docs/user-guide/desktop)
- `workspace_scope: "directory"` 仅发现原生接口确认属于配置目录的对话。显式设为 `"instance"` 可发现整个实例，路径已知的对话携带 `directory` 与对应工作区引用。路径未知的对话保留空路径。创建指定工作区时，DJ 与原生服务分别校验。
- 使用 `agent.discover`、`session.resolve` 或 `session.probe` 确定目标，再调用 `session.send`。从 `delivery.get` 查看接受回执，用 `catalog.refresh` 和 `session.message.list` 核对历史及真实回复。对话调用 DJ 的 MCP、CLI 或 API 可向另一工具发送消息。
- 端点断开后，DJ 在后续操作中重新鉴权并重验原实例及原生会话。对已发出而结果未确定的请求保持 `unknown`，先读取原会话再决定后续操作。
