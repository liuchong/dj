# GEPO 接入

GEPO 0.2 与现有 JSON API 共用同一私有 HTTP-over-UDS 服务、Bearer 身份和操作目录。它不启动第二个 Core 或 Agent，也不新增公网监听。客户端需支持 Unix socket HTTP 传输，凭据从自己的受保护 profile 读取，不放进 URL、命令参数或模型提示词。

| 请求 | 行为 |
|---|---|
| GET /?.gepo、/.gepo、/.well-known/gepo | 当前主体可见的根目录 |
| GET /subscription?.gepo | 当前目录与直接子路径 |
| GET /subscription/preview | 当前操作用法、输入/结果 schema、副作用与重试要求 |
| POST /subscription/preview | 执行 subscription.preview；JSON body 就是该操作的 arguments |

所有操作把点分名称映射为斜杠路径，例如 message.get 对应 /message/get。GET/HEAD 只提供说明或目录，不创建订阅、不读取 IM 正文、不触发投递；业务查询也使用 POST。无权限路径不在目录中出现，认证信息仍逐请求复核。

POST 参数、结果、权限、revision 和幂等键与 CLI/MCP 完全相同，不增加 GEPO 专用业务 envelope。业务失败可能返回 HTTP 200 且 ok=false，必须读取完整 DJ Result、effect_state 和 next_actions；超时用原 operation/idempotency_key 查回，不能自动重发 POST。已有 /v1/operations envelope 保持兼容。

响应携带 x-dj-api-version 与 x-dj-operation-catalog-digest。可携同名目录摘要请求头拒绝不兼容目录。Origin 请求、未认证调用和超预算请求仍拒绝；认证的空能力集合不会扩权。

AI 通过 GEPO、MCP 或普通 API 调用 DJ，不需要 Cursor Inspector。只有 DJ 主动操作 Cursor 原会话的适配器才使用 Inspector。
