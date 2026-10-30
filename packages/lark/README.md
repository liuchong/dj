# Lark

独立 Eliscript 包，直接连接 Lark／飞书官方 HTTPS API，不依赖 DJ、第三方 SDK 或 CLI。JSON、查询参数、multipart、原始请求体、文本与二进制响应共用一套传输实现。`wire` 提供官方 WebSocket 帧编解码。

## 模块

| 文件 | 负责 |
| --- | --- |
| `src/http.eli` | 官方域名与路径、查询编码、请求体、取消/截止、限量响应、原生状态与安全响应头 |
| `src/client.eli` | 应用 token、本人 OAuth 刷新与身份核验、缓存、单飞鉴权和生命周期 |
| `src/wire.eli` | WebSocket 帧编码、解码与有界协议校验 |
| `src/index.eli` | 独立公共入口 |

消费者提供 `host.fetch(url, options)`、`host.monoNow()`、`host.credentials.resolve(ref)`；本人 OAuth 续期另需 `credentials.persist(ref, value)`。config 使用 `brand: lark|feishu`、`identity: user|bot`、`credential_ref`；本人身份另有 `user_identity: {app_id, open_id}`。同一应用的本人和机器人可各建独立实例，不共享 token、取消状态或账号选择。

```eliscript
(import "./src/index.eli" createLarkClient)
(defconst client (createLarkClient config host))
(await (js-call client :request
  (js-object :method "GET" :path "/open-apis/im/v1/chats"
    :query (js-object :page_size 20))
  (js-object :deadline (+ (js-call host :monoNow) 15000))))
```

`request(spec, context)` 返回 `{status, headers, wire, retry_after}`，保留平台原生 JSON，不把 HTTP 200 自动解释为业务成功。`spec` 支持 `method/path/query/headers/body/form/raw/response_mode/max_response_bytes/timeout_ms`；body、form、raw互斥，GET/HEAD不带正文。form值为标量或原生Blob/File；raw为文本、Uint8Array或Blob。mode为json/text/bytes，bytes返回Buffer。默认响应上限1MiB、请求15秒；消费者可按业务预算显式设置，上限512MiB。分页按端点原生page_token等字段显式续页，不自动全量遍历。

请求只允许官方 `/open-apis/` 路径，不跟随重定向，不允许覆盖认证头。调用方负责端点的业务授权与字段，包负责注入所选身份的凭据；不在本人失败时切机器人。平台权限、错误码、限流与业务结果原样返回；写请求从不自动重试。`close()`取消本实例在途HTTP，`initialize()`重新启用；不操作其他实例。

WebSocket连接重连、DJ持久收件和WebSocket＋HTTP去重由DJ适配器负责，协议编解码来自本包。订阅、触发过滤、m×n分发、回复位置、Working与业务操作台账不进入通用包。

本包提供通用原生API传输能力，不声称已经逐一封装或真实验收官方全部业务端点。API支持的身份、可见资源、参数和限流以[官方文档](https://open.larksuite.com/document)及[飞书文档](https://open.feishu.cn/document)为准。

## DJ 接入

DJ的连接管理器按connection_id选择本包实例，适配器继续维护IM事件语义。CLI/MCP/GEPO通过`lark.api.read/call/get`访问通用入口；常用消息及资源功能继续使用已有高级接口。详情见[0017](../../docs/specs/0017-lark-package.md)和[AI用法](../../skills/dj/references/lark.md)。

独立构建使用本目录的`eliscript.json`；生成JS不入仓库。许可证见[LICENSE](LICENSE)。
