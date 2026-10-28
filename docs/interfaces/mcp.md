# MCP 接口与宿主适配

## 规范基线

MCP 入口使用锁定的 `@modelcontextprotocol/server` 2.3.1 和 stdio 传输。协议协商、分帧与协议级错误由 SDK 处理，业务 schema、身份与权限由 DJ 校验。[官方现行规范](https://modelcontextprotocol.io/specification/latest)用于查阅协议要求，不代表 DJ 实现了所有可选扩展，也不因旧宿主而增加项目自己的兼容层。

宿主报告的版本、实际 SDK 支持与厂商扩展均需能力探测。服务的 Subscription、AgentTarget 是 DJ 应用状态，不能绑定 MCP 传输连接 ID，也不因客户端断线而删除。

## 工具映射

[统一操作目录](operations.md)每项操作映射一个工具，名称为 dj_ + operation 中点号替换下划线，例如：

| operation | MCP tool |
| --- | --- |
| service.status | dj_service_status |
| agent.whoami / agent.discover / agent.register | dj_agent_whoami / dj_agent_discover / dj_agent_register |
| subscription.preview / subscription.create | dj_subscription_preview / dj_subscription_create |
| conversation.resolve / operation.get / outbound.get | dj_conversation_resolve / dj_operation_get / dj_outbound_get |
| message.get / message.reply | dj_message_get / dj_message_reply |
| delivery.get / delivery.reconcile | dj_delivery_get / dj_delivery_reconcile |
| session.list / session.search / session.send | dj_session_list / dj_session_search / dj_session_send |
| session.message.search / session.create | dj_session_message_search / dj_session_create |
| instance.start / lifecycle.get | dj_instance_start / dj_lifecycle_get |

其余逐一按同一规则生成独立工具，不实现万能 dj_execute，也不把多个操作塞进自由字符串 action。schema 使用 object + additionalProperties=false，字段、必填、默认值和限制取自统一契约。枚举使用精确字符串，不让模型传入任意 shell。

每个工具声明 inputSchema 和 outputSchema。正常及领域失败在 structuredContent 返回统一 envelope，同时提供简短文本摘要；领域失败设置 isError=true。JSON-RPC 协议级错误仅用于无法识别方法/参数等协议问题，不混淆成厂商业务错误。[Tools](https://modelcontextprotocol.io/specification/2026-07-28/server/tools)

只读工具标 readOnlyHint=true；管理和发送标 false。destructiveHint/idempotentHint 依据实际语义：带服务幂等键的创建/发送可声明幂等，但“幂等”不等于没有外部效果。annotations 是提示，不能替代服务端授权。

## 传输与身份

首轮本地 stdio 薄代理连接同一个常驻核心；stdout 只允许协议记录。远程 Streamable HTTP 为扩展候选，启用前实现认证、Origin/目的地校验与租户边界，按该版本传输/授权规范验证。代理不能用宿主自报名称决定 principal。[传输](https://modelcontextprotocol.io/specification/2026-07-28/basic/transports)、[授权](https://modelcontextprotocol.io/specification/2026-07-28/basic/authorization)

查询有预算，长时间等待不占用一次工具调用作为唯一状态容器。subscription.create 返回持久句柄；delivery.get/reconcile 获取受控状态。可选资源 URI 如 dj://deliveries/del_example 只提供授权投影，不提供任意文件访问；首轮工具集足够，无须依赖 Resources/Tasks 扩展才能工作。

## 主动唤醒

MCP 工具调用、通知和扩展流不保证宿主在空闲时发起模型回合。DJ 的默认唤醒路径是 AgentPort，而不是循环调用 message.list 或让 Agent 设置 cron。

Claude Channels 是可选的宿主专用推送方式：会话显式启用、插件/组织策略满足后，适配器把信封送入该通道。需要单独记录 channel_enabled、原生会话绑定与实际触发证据。普通 MCP 已连接但通道未允许时，工具可能仍可用，主动事件不能据此视为可用。[Channels](https://code.claude.com/docs/en/channels)

不同宿主的 Skills over MCP、Tasks 或订阅流可作为显式可选扩展；核心不依赖它们提供跨工具通用唤醒。DJ 不提供或调用 Sampling 推理，也不使用模型来修正工具参数或选择目标。外部 Agent 如何使用自身模型属于其宿主。

## 接口一致性验收

同一个认证主体、输入和幂等键经 CLI/MCP 必须得到相同业务对象、权限决定及副作用。相同请求跨入口重放仍只生成一个 operation_id。MCP 安装成功只证明连接配置；必须另外验证工具发现、正文读取、实际订阅、空闲唤醒与回复。

## 面向模型的工具描述与 schema

工具列表按主体可用权限和产品能力投影，不向普通 Agent 提供 operator-only resolve。每个工具说明做什么、必需 ID 的来源、是否产生外部效果、输出 ID 用于哪项后续操作。服务返回的 conversation_ref/candidate_ref/preview_id/reply_context_id 类型不同，不让模型从字符串前缀猜参数。

inputSchema 在所有嵌套业务对象上明确 additionalProperties=false；叶子值类型、枚举、非空数组与字节上限有定义，禁止把多个不完整对象组合为“猜得出来”的请求。operation.get 的两种查询模式用互斥 schema 表达；宿主不支持所需 schema 形状时报告 incompatible，不偷偷接受更宽输入。

outputSchema 覆盖成功与领域失败两种 envelope，字段为统一目录规定的 data/error、effect_state、evidence_level、warnings。field_errors 使用 JSON Pointer；next_actions 来自固定代码映射，工具文本只是该结构的简短投影，不产生另一个与 JSON 冲突的解释。

subscription.preview 返回可直接提交的 preview_id；create/update 不接受第二份 spec。超时通过 dj_operation_get 找对象，再调用 dj_outbound_get 或 dj_delivery_get。引用失败一律不按标题兜底。MCP 的协议握手由锁定 SDK 处理，不能改变业务授权、参数与幂等语义。

以上是 DJ 自身的设计取舍，不能把服务校验寄托于宿主 strict 模式、Skill 被读取或模型总能正确选择。完整责任边界见 [模型调用契约](../model-facing.md)。

## 实现与客户端接线

Eliscript 调用锁定的 `@modelcontextprotocol/server` 2.3.1，使用 Server 与 `serveStdio(factory)`。主路径为 stdio → UDS → 现有 Core，不启动另一个服务或模型循环。依赖见[技术栈](../technical-stack.md)，各客户端配置与 CLI 备用入口见[客户端接线](../../skills/dj/references/clients.md)。共享配置不能证明当前会话身份，接收方仍需核对自己的 recipient 绑定。

tools/list 从 operationCatalog 投影严格 schema，tools/call 将合法协议壳的业务参数交给 DJ 权威校验，领域错误返回统一 envelope/isError。协议壳错误由 SDK 处理；不依赖高层默认校验生成另一套业务错误。代理核对服务 api_version/build_id/operation_catalog_digest，摘要不符明确拒绝。SDK 协议依据见[低层接口文档](https://ts.sdk.modelcontextprotocol.io/v2/advanced/low-level-server.html)；实际安装与运行证据见[当前状态](../status.md)。

## 控制面的一致投影

[统一操作目录](operations.md)中的 tool/profile/instance/catalog/session/lifecycle 操作按同一映射提供。查询 schema 表达 tools/instances/workspaces 等机械范围；结果同时给分页 complete 与 coverage_complete/as_of，不能简化成一句“搜索无结果”。session.send 不依赖订阅，也不与 IM message.send 合并为模糊 send 工具。

可选会话创建带 idempotency_key 和明确实例 epoch 约束；catalog.refresh/reconcile 也会更新台账，不标成无状态读取。正式配置没有可用的托管 Agent 启动路径，不能把 start 当成 list/search 的隐含补救。IM 收件仍只走事件/订阅规则，不增加聊天管理面。

dj_session_get 的 session_ref/session_key 严格二选一；dj_session_probe 对单个精确会话只读核验，不测试发送。scope.session_keys 允许定点刷新/消息搜索；delivery 过滤允许 operation_id/session_key/origin 等已定义字段，但不跨主体扩权。search 只允许稳定键顺序，空 items + 非空 next_cursor 必须继续视为未完；outputSchema 区分稳定 key、过期短期引用、历史生命周期结果和当前实例状态。所有 origin 分支和 stopping 错误继承统一契约，不由 MCP 描述自行放宽。
