# 0037 本机 MCP 共享接收

DJ 主服务可直接承载带鉴权的 MCP Streamable HTTP。服务配置的 `service.mcp_http_port` 只绑定 `127.0.0.1`。客户端统一连接 `http://127.0.0.1:<port>/mcp`，不需要为每个工作区或对话运行一个 DJ 代理。由同一 Core 执行工具目录、授权与操作。

各 MCP 客户端独立初始化，HTTP 会话绑定已认证主体及授权修订。连接关闭、会话过期或服务重启后，客户端可以重新初始化。服务以有界会话和请求数提供保护，在 `service.status.mcp_http` 暴露当前会话和进行中的请求数。明确调用 stdio 的客户端保留正式支持，部署到支持 HTTP 的客户端时用 URL 取代命令入口。

Codex Desktop 需在同一 `codex app-server` 进程树内运行自带签名 `cua_node` 才能保留 App Tools 控制权限，因此通过包内 `connectors/codex/launch-mcp.sh`（`mcp.mjs`）提供专用 stdio-to-HTTP 薄代理：从 `0600` `--token-file` 读取本机 Bearer token 连接 `http://127.0.0.1:<port>/mcp`，支持 SSE 与 JSON 响应解码、HTTP `404` 会话过期透明重建、实时捕获 `_meta["x-codex-turn-metadata"]` 到 `caller-context.json`，并在同进程内托管单锁（`<owner_pid>.lock`）原生控制接收端。

Antigravity 的桌面发现涵盖宿主原生返回的对话及子轨迹。具体会话操作仍沿精确原生 ID 和工作区校验。客户端 PID 和端口变化由原有的运行实例重发现处理。
