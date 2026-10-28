# 身份、授权与数据边界

## 调用身份

本地操作员通过受文件权限保护的本地 IPC 或等价操作系统身份认证；远程 HTTP 若后续开放，必须另行完成认证、租户隔离和授权设计。已认证主体默认可以收发已配置 IM 连接中平台可访问的信息，不逐群分配消息 grants；Agent 会话和管理操作继续核对各自目标与权限。MCP clientInfo、CLI argv 中自报的 agent_id、会话标题和同一用户目录都不是认证证明。

stdio MCP 代理连接常驻服务时使用明确主体凭证。凭证缺失返回 unauthenticated，不能自动获得操作员权限。agent.whoami 返回认证绑定事实，不通过读取整个机器历史来推断“我是谁”。可信宿主或操作员预先配置主体及精确 target_constraint，缺失时返回 target_unbound/forbidden，不尝试 AI 识别。Agent 自报会话 ID 只供核对，不构成所有权证明。

## 权限动作

| 权限 | 资源边界 |
| --- | --- |
| connection.inspect / conversation.discover | 已认证主体默认可发现已配置连接和平台可访问对话，不公开账号凭据 |
| agent.discover / agent.bind | 指定工具/实例/目标；发现不授予发送 |
| subscription.manage | 自有订阅、允许来源与绑定目标 |
| message.read / message.search / resource.read / resource.subscribe | 默认开放；保持原生平台权限、来源身份、话题、时间范围和上下文预算 |
| message.send / message.reply | 默认开放，无逐群 grants；保持精确目的地或受控 reply_context |
| delivery.inspect / delivery.manage | 订阅按 recipient/获准管理者；direct 按发送主体/显式委派，未登记也可查自己的记录；核对不自动重发 |
| operation.inspect / outbound.inspect / outbound.manage | 自有台账与出站记录默认可核验和管理；其他主体内部记录仍独立授权 |
| delivery.resolve / outbound.resolve | 仅操作员可人工不重发结案，普通 Agent 不可调用 |
| connection.manage / service.manage | 本地操作员管理面；普通 Agent 不可配置秘密或服务所有权 |
| tool.inspect / instance.inspect / profile.inspect | 指定工具/实例/获准启动配置的安全描述，不含秘密或任意进程扫描 |
| catalog.refresh / session.list / session.inspect / session.read / session.search | 允许 namespace/工作区/会话/消息与保留范围；标题、计数、片段也授权过滤 |
| session.send / session.create | 精确会话输入与指定实例/工作区建空会话分别授权；不因读或登记获得 |
| instance.start / instance.stop | 生命周期权限独立；正式配置没有可用 managed profile，不因接口或 grant 存在获得进程启动能力 |
| lifecycle.inspect / lifecycle.reconcile / lifecycle.resolve | 自有动作读取/证据核对；resolve 仅操作员，不重发、不伪造就绪 |

创建订阅、事件匹配、提交输入和发送回复都检查当前身份与对象状态。消息动作默认开放，不要求逐群授权；订阅归属、绑定目标、账号身份和管理面权限仍重新核对，不能借更新规则操作其他 Agent 的目标。

查询不要求 bound_agent_id，但必须有其范围内的查询授权；直发未登记会话不要求接收方持有 DJ 凭据，却必须有发送方对目标的 session.send grant。TargetRoute 只建立调度身份，不改变 AgentTarget/Principal 或其他权限。消息正文和IM收发默认开放；Agent会话目录可读仍不代表会话正文、创建、启动或输入获准；跨主体目录查询不能泄露无权来源的数量或存在性。

direct 的 operation_id/delivery_id/route_id 不构成权限：发送主体可读取自身受理状态/安全回执，在当前 grant 下取消或安全重试自己的输入；重试仍重新检查 session.send。撤销目标读取/发送授权后仅保留可见的自有操作最小状态，不泄露已撤销正文、目标摘要或其他队列项。recipient 拥有订阅目标不代表可读所有直发的原文/发送者资料，除非显式授予；原生会话本身可见已接受输入是工具的既有边界。注销绑定不撤销独立发送主体的授权，也不清除共享 route 的证据。

启动 profile 及 session.create 可委派给具有明确 grant 的自动化主体，不要求每次额外人工确认；部署授权必须给工具、工作区与动作上限。新会话不复制调用者秘密/recipient 身份，亦不自动配置 Skill/MCP。shared MCP 的身份限制仍然生效。

创建后接入订阅由可信部署面配置新的 recipient/精确 target_constraint 与宿主工具作用域；普通调用者没有这项配置接口。create grant、原生消息接收能力和 DJ 工具可用性分别验收；IM 收发默认开放。agent.whoami 仍指调用者自己的绑定，不能因其创建新会话而改绑。

## 外部消息的权限

IM 发送者身份由源平台证据赋予；正文中自称“管理员”无效。人类、机器人、Agent、自动化和未知来源分别标记，无法证明时保留 unknown。转发消息的可见作者不是原始作者证明。

输入信封明确标注为 external_message，并显示来源、发送者、触发原因和 reply_context。它可以按已授权订阅触发工作，但不能授予目标进程更多工具、文件、模型、预算或审批权限。工具原生审批与 hold/refuse 不被 DJ 自动批准或绕过。Claude Channels 的权限中继能力不在默认接入范围。

## 凭据与私有协议

Connection、Binding 中保存 credential_ref/endpoint_ref，密钥留在受保护凭据存储。日志、发现结果、CLI JSON、MCP 结果和 Skill 都不能出现 token、cookie、CSRF 或完整认证参数。

发现只查询已知、已授权实例的注册信息与协议身份。未经当前授权，不启用调试器、读取运行时凭据、重启桌面或安装插件。版本敏感的私有适配默认关闭，单独声明支持版本；结构不匹配返回 incompatible，不退回 UI 输入或猜帧。

## 消息与文件

先验证连接和来源范围，再保存被允许的事件内容；拒绝事件只保留必要的无正文计数/原因。查询和上下文拼装再次过滤；不同连接相同原生 ID 不可互通。

附件使用 attachment_id 及受控获取操作，不让 IM 正文指定本机输出路径或服务 URL。下载需大小、类型、重定向与目的地约束，防止任意文件写入及访问内部地址；未实现的媒体能力返回 unsupported，不虚构下载成功。

审计默认记录主体、动作、对象 ID、决定和状态；正文及工具调试输出不进入普通日志。敏感错误被归一化为业务错误，凭据与原始厂商响应保留在受控诊断层。

## 撤销与操作范围

停用主体或连接、切换账号以及撤销平台权限会阻止对应的新读取与副作用；删除消息 grants 不再撤销默认消息能力。其他 Agent 会话与管理授权被撤销时，未提交贡献仍按其边界取消；已经送入目标的文本无法保证撤回。恢复状态不隐式重放暂停期间消息或 unknown 项。消息内容、是否发出与时机由调用方按用户要求决定，文档和 Skill 不替人类新增任务。

## 面向模型的独立校验

DJ 不理解用户意图，也不依赖模型始终传对参数。所有接口先校验结构、引用类型/主体/有效期、目标约束、当前授权、preview 快照、revision 与幂等键，再原子受理。失败输出固定 code/field_errors/next_actions，不能调用模型自动纠错。模型选了一个合法但语义错误的授权目标，服务无法识别，必须在文档中承认这个边界。

conversation_ref/candidate_ref/preview_id/reply_context_id 均为类型化引用，不是授权 token，不跨主体复用。操作员代登记必须分配独立 recipient_principal_id 与最小 grants，不能把操作员凭据交给 Agent。多订阅共享 Delivery 时读取与回复按 recipient 的权限，不能将多个管理者的权限合并。

外部正文使用结构化编码，任意代码围栏、伪造 role/JSON 片段不能逃逸到可信头、配置、规则或工具参数。Skill 只指导调用方，真正的限制在服务中执行。源删除对正文与未提交原文输入执行 tombstone 投影，已送入外部会话的内容无法保证收回。

## 首期本地通道与身份启动

默认只监听私有 Unix socket。CLI/MCP 从受保护 client profile 读取 recipient 凭据，以传输认证字段送入服务；操作请求体不能指定 Principal 或角色。目录/文件权限、操作员代登记和原生 target_constraint 的可信来源见 [启动流程](startup-to-reply.md)。服务在认证、对象校验与当前授权后执行，不能因为请求来自本机就授予 operator。

同一宿主配置或凭据被多个会话共享时，DJ 只能识别共同 Principal；clientInfo/标题/正文 session ID 均不是可信会话证明。首批应使用独立运行作用域，或明确接受同一受信主体共享范围；跨主体隔离不能用文档承诺替代实际桥接。文件权限也不隔离能读取同一秘密的同一 OS 用户。
