# CLI 契约草案

目标可执行名 dj，尚未实现。CLI 是无 AI 的薄客户端：连接现有 DJ 服务、传递结构化参数、返回结果；不解释自然语言，也不每次启动一个收件服务。[业务契约](operations.md)是唯一语义来源。

## 命令与输入

operation 的每一段点号映射为命令词，例如 subscription.create → dj subscription create、session.message.search → dj session message search；service.status 的唯一特例为 dj status。每个独立操作都有明确 --help；--help 说明必填字段、ID 类型、默认、上限、权限、受理和完成区别，以及典型错误后的查询操作。

| 选项 | 规则 |
| --- | --- |
| --json | 给模型/脚本的固定 envelope；人类默认简明表格 |
| --input FILE | 完整 JSON 参数；FILE=- 从 stdin 读，相对文件路径；与所有逐字段业务 flags 互斥 |
| --idempotency-key / --expected-revision | 逐字段模式下的幂等/并发参数；--input 模式放入 JSON |
| --limit / --cursor | 顶层列表分页，不嵌套 page |
| --connection / --agent / --subscription / --delivery / --outbound | 映射相应对象 ID，非当前操作所需即拒绝 |
| --conversation-ref / --destination-ref / --candidate-ref / --preview-id | 不同类型的引用；不按名称相似度互换 |
| --session-ref / --session-key / --session-message-ref / --instance / --profile / --catalog-run / --lifecycle | Agent 控制面引用/ID；get 的 ref/key 互斥，只在对应操作允许，不能当作 IM 地址 |
| --operation-id | operation.get 的 ID 查询模式；与 operation+幂等键查询互斥 |
| --timeout-seconds | 默认 30，1–300；超时不取消已受理后台工作 |
| --endpoint | 配置中的 DJ 服务引用，不是任意目标工具 URL |

不提供自由文本 dj do/自然语言 execute 或自动参数纠错。人类命令写错也必须给明确错误，不能悄悄映射到另一个对象。模型优先使用完整 JSON 输入，服务返回的句柄直接复用，不用 shell 拼接原始消息正文。

JSON 成功 envelope 写 stdout，失败写 stderr，日志只在 stderr；调用者须同时读取退出码和对应 envelope。代理不得把诊断拼进协议 JSON。退出码：0=查询成功/变更已受理，2=参数/票据失效，3=认证/授权，4=可证未受理/未发送的依赖失败，5=结果未知，6=revision/幂等/重复提交冲突，7=不支持/版本不兼容，8=内部或存储错误。

## 可复用输入示例

```bash
dj status --json
dj agent whoami --json
dj conversation list --connection con_example --json
dj subscription preview --input preview-request.json --json
dj subscription create --input commit-request.json --json
dj operation get --input operation-lookup.json --json
dj outbound get --outbound out_example --json
dj message reply --input reply-request.json --json
```

这些文件名不是仓库已有文件，完整 JSON 形状见 Skill 示例与业务契约。commit-request.json 只包含 preview_id 和调用方保存的幂等键；不能重复写 spec。该预览在原授权内可直接提交，不额外引入人类审批步骤。

操作超时后，operation-lookup.json 使用原 operation+idempotency_key；查到 operation_id 后再从 resource_refs 取得 outbound/delivery/subscription ID。不能凭名字猜哪个 get，也不能新键重发。not_found 不证明原请求不会提交，若重放必须保留原键和原输入。

## 生命周期入口

服务采用 `dj serve --config FILE`，FILE 为本地部署配置，缺省为可信宿主 home 下的 `.dj/service.json`（即 `~/.dj/service.json`）；--config 仅属于该操作员启动入口，不是普通业务 JSON 参数。CLI/MCP 从可信宿主设置的 DJ_CLIENT_PROFILE 指向受保护客户端配置，--endpoint 只选择其中的服务引用；不接受请求自报 principal。启动与权限接线见 [完整流程](../startup-to-reply.md)。

操作员进程入口 dj serve（前台常驻）和 dj mcp serve --transport stdio（薄代理）均待实现。服务由部署配置启动，不由 Agent 隐式安装/后台脱离。MCP/CLI 断线不删除订阅；服务不可用不另建空数据库或影子服务。

本地秘密通过受保护配置引用取得，不放进命令参数、模型正文、输出或 Skill。普通 Agent 无法调用 operator-only resolve。CLI 与 MCP 共用幂等台账、字段目录、错误与权限，不因换入口而重新执行副作用。

## 会话控制面命令

跨工具 scope、query、预算及启动/创建参数使用 --input 完整 JSON，形状见 [控制契约](../agent-control-plane.md)与[Skill 例子](../../skills/dj/references/control.md)。这些都是未来命令，无 IM 管理命令或自由文本 execute。

```bash
dj tool list --json
dj instance list --json
dj profile list --json
dj catalog refresh --input refresh-request.json --json
dj session list --input list-request.json --json
dj session search --input search-request.json --json
dj session message search --input message-search-request.json --json
dj session resolve --input resolve-request.json --json
dj session get --session-key session_example --json
dj session probe --session-ref ssr_example --json
dj session send --input direct-request.json --json
dj instance start --input start-request.json --json
dj session create --input create-request.json --json
dj lifecycle get --lifecycle life_example --json
```

list/search 不自动 refresh/启动实例。direct-request 只含一个 session_ref 或 agent_id，返回 delivery_id；IM send/reply 返回 outbound_id；启动/创建先返回 lifecycle_id，原生核验后才有就绪会话引用。三种结果不能混查，超时仍先 operation.get 按原键找回。

会话/消息检索沿稳定键有界续扫，items 为空而 next_cursor 非空时仍有未扫描数据；不能自动补全局时间排序。lifecycle.get 返回稳定 session_key/initial_session_key 与当前获准引用，过期 ref 用 session.get 重取，不重做 start/create。未登记直发的 delivery 可按 operation_id/session_key 过滤本人记录。instance.stop 的期限不等于强杀授权，stopping 时新提交明确失败；完整字段均继承控制契约。
