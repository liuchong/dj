# 统一业务操作契约

CLI、MCP 与本地 API 共享本文件的业务语义。全部为设计，尚未实现。输入只接受结构化 JSON，未知字段拒绝；不提供自然语言命令、模型判路由、智能参数修复或自由字符串 execute。IM 操作保留 conversation/message 命名；Agent 会话使用 session 命名，避免发送方向混淆。

## 共用输入、结果与校验

request_id 可选，用于追踪；所有受理变更要求 idempotency_key。修改已有配置对象、retry/cancel/resolve 要求 expected_revision；register/create/send/reply 无既有 revision。新增 instance.start 使用 expected_profile_revision，session.create 使用 expected_instance_epoch；instance.stop 使用 expected_revision。reconcile 只追加原生观察，要求幂等键但不要求 revision。认证主体来自通道，不接受请求赋权。

返回固定字段 ok、request_id、warnings、evidence_level、effect_state；ok=true 包含 data，受理变更还包含 operation_id；ok=false 包含 error={code,message,retryable,details,field_errors,next_actions}。错误的可修正字段、建议与副作用状态见 [模型接口](../model-facing.md)。evidence_level 为 none/service_record/native_protocol/agent_report/manual，属于来源类别而非可任意升级的等级。

```json
{"ok":true,"request_id":"req_example","operation_id":"op_example","data":{"outbound_id":"out_example","state":"ready","revision":1},"warnings":[],"evidence_level":"service_record","effect_state":"recorded"}
```

先认证并查询同主体/操作/幂等键；相同请求的已受理结果在重新过滤当前可见性后返回，不重验已消费或过期的旧票据，不再次执行。新请求在格式/范围/句柄类型/授权/生效前置检查全部通过后才原子受理：Operation、幂等记录与业务对象在同一事务落盘。校验失败 effect_state=none，不创建 Outbound/Delivery/Subscription。网络超时后可能已经受理，返回或查询 unknown，不能换键重发。

列表统一输入 limit（缺省 50，上限 200）、cursor；返回 items/next_cursor/complete。游标绑定主体、查询条件、授权与读取快照。next_cursor 非空时 complete=false；当前快照列完才为 true，不表示整个机器/平台全量可见。引用始终带类型、有效期与核对摘要。

## 操作目录

每行斜线表示独立操作；各操作的字段都是直接 JSON 字段，分页不嵌套 page 对象。通用字段按上述条件附加，表中不重复列出。

| 操作 | 业务输入 | data 结果 | 权限/效果 |
| --- | --- | --- | --- |
| service.status | 无 | api_version、build_id、operation_catalog_digest、visible_operations、能力/上限、服务与队列摘要 | 可见诊断，无模型判定；技术目录摘要不含秘密/私有实例 |
| message.filter.get | 无 | 服务级过滤策略、revision、rules | message.filter.inspect；消息可见性不变 |
| message.filter.update | expected_revision、rules、idempotency_key | 更新后的完整策略 | message.filter.manage；suppress_trigger；原子替换、持久化 |
| operation.get | operation_id，或 operation + idempotency_key（二选一） | Operation 状态、resource_refs、当前允许的 safe_result | 仅本主体；重新检查读取权限 |
| connection.list/get | filters? / connection_id | 安全 Connection | inspect |
| connection.probe | connection_id | 健康/能力/凭据状态摘要 | inspect；不修改配置 |
| conversation.list | connection_id、parent_ref?、limit?、cursor? | 带 conversation_ref、address/摘要的列表 | discover |
| conversation.resolve | connection_id、chat_id、thread_id（允许 null） | 校验后的 conversation_ref 与摘要 | discover；精确地址，不按标题搜索 |
| agent.whoami | 无 | principal_id、bound_agent_id?、binding_state | 当前认证事实 |
| agent.discover | tool、surface?、instance_ref?、scope?、limit?、cursor? | Candidate 列表 | discover；不创建进程 |
| agent.register | candidate_ref、display_name、binding_mode、recipient_principal_id? | AgentTarget 与 Binding 安全投影 | bind；普通主体只能登记自己 |
| agent.list/get | filters? / agent_id | 目标、安全状态与 revision | 自有/授权目标 |
| agent.probe | agent_id | 核对事实、状态、能力 | bind 范围内只读探测 |
| agent.rebind | agent_id、candidate_ref | 同一原生目标的新 Binding、revision | bind；原生会话不变 |
| agent.unregister | agent_id | closed 状态、撤销摘要、revision | bind；不结束原生会话 |
| subscription.preview | spec、sample_event_ids?、subscription_id?、expected_revision? | normalized_spec/摘要/问题/样本决定，合格时有 preview_id | manage + 必要 read；不投递 |
| subscription.create | preview_id | Subscription、start_seq、revision | manage；提交固定预览 |
| subscription.list/get | filters? / subscription_id | Subscription 与解析后来源/目标摘要 | owner 范围 |
| subscription.update | subscription_id、preview_id | 新 revision、cutover_seq | manage；同目标、固定预览 |
| subscription.pause/resume/delete | subscription_id | 状态、revision、cutover_seq、已提交数量 | manage；不撤回已送输入 |
| message.list | conversation_ref、time_range?、corpus?、limit?、cursor? | 事件摘要及读取引用 | read |
| message.search | conversation_ref、query、time_range?、corpus?、limit?、cursor? | 匹配摘要、语料来源与完整性 | search；字面检索 |
| message.get | event_id 或 message_ref（二选一）、offset_bytes?、max_bytes? | 元数据、正文分页、附件引用 | read |
| message.send | destination_ref、content | Outbound、state、revision | send；创建出站意图 |
| message.reply | reply_context_id、content | Outbound、state、revision | reply；固定目的地 |
| outbound.get | outbound_id | Outbound、parts、安全回执 | 自有/授权记录 |
| outbound.reconcile/retry/cancel | outbound_id | 当前 Outbound 与处理结果 | manage；核对/安全重试/取消分开 |
| outbound.resolve | outbound_id、resolution、reason | resolved、manual 决定 | 仅操作员；永不重发 |
| delivery.list/get | filters? / delivery_id | 投递、贡献、安全回执、reply_context_id? | inspect；正文另读 |
| delivery.reconcile/retry/cancel | delivery_id | 当前 Delivery 与处理结果 | manage；核对/安全重试/取消分开 |
| delivery.resolve | delivery_id、resolution、reason | resolved、manual 决定 | 仅操作员；永不重发 |

connection 和 managed profile 的配置由操作员维护，普通工具不接受秘密、任意 argv 或目标 URL；文件凭据与 UDS 已选定，见技术选型。获准调用者可显式选择预配 profile 启动实例，不修改其配置。新增 tool/profile/instance/catalog/session/lifecycle 的逐项操作、严格输入与输出目录见 [Agent 会话控制面](../agent-control-plane.md#统一操作目录)，是本目录的正式补充，不能只暴露在某一入口。

施工用的全部61操作必填/可选、互斥、幂等键/修订保护、嵌套类型及结果已展开为 [逐操作字段表](../construction/operation-catalog.md)。service.status 的 operation_catalog_digest 表示公共描述符/schema/默认规则的技术身份，不含主体授权/私有实例；薄客户端不匹配则 incompatible，不能悄悄用另一套字段目录。

agent.register 的 recipient_principal_id 仅操作员代登记时允许且必填，普通 Agent 不能传入；主体/目标约束见安全文档。rebind 不接受 tool/namespace/session 改变。unregister 关闭目标并暂停其订阅，撤销未提交的订阅贡献，保留已提交记录；不能把新 native_session_id 写进原 agent_id。它不停止原生实例、不删除共享 TargetRoute/unknown，也不取消独立直发。后续登记沿用同一 canonical route，不能通过注销/重登记绕过顺序屏障。

agent.discover 继续为登记核对返回 Candidate；agent.list 只列已登记 AgentTarget。跨全部/若干工具会话列表和检索使用 session.list/search，不要求先 register。session.send 受理返回 Delivery，message.send/reply 返回 IM Outbound；启动/创建返回 LifecycleAction。operation.get.resource_refs 指明对象类型，不让调用者猜 get 操作。所有新操作沿用台账原子受理与原键重放。

## 规则与提交

spec 可选 instruction_policy：`prompt` 为固定提示词，`task_template` 为确定性任务模板，至少提供一项，每项 1..8192 UTF-8 字节。模板仅支持 `{{message.text}}`、`{{event.id}}`、`{{sender.id}}`、`{{source.chat_id}}`、`{{source.thread_id}}`、`{{subscription.id}}`，最多 32 个占位符。未知/未闭合占位符在 preview 前拒绝；固定 prompt 不展开。message.text 使用最终信封的有界正文，缺失 thread 等字段为空字符串，插入值中的花括号永不二次展开。

配置随 subscription revision、preview hash 与不可变 version 保存，再复制到 contribution；提交时仍逐条重检 owner/revision/TTL/授权，仅有效贡献生成 instructions。信封 instructions 按 matched 的订阅顺序携带 subscription_id、subscription_revision 及可选 prompt/task_template/task。task 是配置模板的机械渲染，不是 DJ 调用模型或执行任务；正文及其插值仍是外部数据，不提高优先级或权限。单 task 超 32768 UTF-8 字节或最终帧超原上限时阻塞为 limit_exceeded，不发送部分任务。旧订阅未设置该字段时不增加 instructions 字段，原 accepted attempt 快照不变。

spec 定义见 [模型](../domain-model.md)。sources 使用 conversation_ref，selector.event_kinds 形成明确类型范围。preview 更新模式必须同时给 subscription_id/expected_revision；create 模式不能给这两个字段。update 的 preview 必须属于同一对象/revision，且 spec.agent_id 不变。

create/update 不接收 spec，不能将 preview 的解释与另一份输入组合。票据失效/状态漂移返回 preview_expired/preview_stale，不能自动修改再提交。只签发无 blocking_issues 的票据；warnings 不等于人工审批要求。sample_event_ids 最多 20，缺省不遍历历史。start 首轮仅 now，backfill 返回 unsupported。

## 消息与查询

### 订阅待办拉取

spec.delivery_mode 默认为 push；显式 pull 时，规则命中的事件写入独立收件箱，不创建原生投递或调用 AI 接口。修改模式同样走 preview/update 与版本 cutover；旧版本待办不能借新版本授权复活。message.list/search/get 仍只是消息查询，不领取待办。

`subscription.pull(subscription_id, lease_seconds?, idempotency_key)` 每次最多领取一项，lease 默认 60 秒、范围 1..300 秒且不晚于待办 TTL。调用者必须是该 Agent 的 recipient，并具备 subscription.consume（self 按 recipient 归属）及当前消息读取权限；operator 不能冒用 recipient。匹配和每次领取都重检订阅 owner、revision、TTL、连接身份和授权。按 ingress_seq 选择已完成路由的待办，跳过其他未过期租约；每次扫描上限 50。返回 pull_id、empty、more 以及可选 item；more 只表示可能还有候选，空结果不代表所有历史均扫描完。

item 含 inbox_id、状态、claim_ref、lease_until 和 envelope；信封 delivery_id 为 null，inbox_id 标明主动消费来源，原消息、指令和受限 reply_context 均按当前权限生成。它不经过 native queue，不绕过原生队首屏障。使用 claim_ref 调 `subscription.ack(claim_ref, disposition, idempotency_key)`：consumed 确认本次消费；retry 释放待办供新领取。消费确认不是 AI 任务完成声明。两个操作都写原操作台账；同键重放不重新领取，空领取也固定记录。租约过期或重领后旧 claim_ref 无效，旧回复上下文在回复受理和实际出站前均校验代次；应以 inbox_id 对业务处理去重，不能宣称 exactly-once。

操作查回仅在当前权限和原租约仍有效时返回正文。已消费、失效或被新领取替换的原操作只返回当前安全状态，不泄漏新 claim_ref 或重发消息。没有回调时 AI 可主动发起新键轮询，不自动生成后台定时器。

ConversationAddress 的原生地址与 ConversationHandle 的公共 conversation_ref 有明确映射；正常发送只用 destination_ref，不允许同时给原生目的地或标题。只有 resolve 接收精确原生三元组；它仍须核验权限，无法证明时不签发句柄。reply_context 固定目标，不允许附加 destination 覆盖。

content 必须为 {type:"text",text:string}，非空且 UTF-8 最多 16384 字节；不接受任意额外类型。平台更低上限在受理前校验是否可安全拆分。分片策略、幂等与未知结果见投递文档。缺少回复权限时不签发可用 reply_context。

corpus 缺省 local，native 仅对具备能力的源开放。native 记录经过权限和字段规范化后形成只读 MessageSnapshot/message_ref，不创建实时 Event、不消耗 ingress_seq，也不占用源入库去重键；稍后真正到达的 live 事件仍按自己的规则处理。message.get 接收 event_id 或 message_ref 两种互斥参数，不能混用。time_range 为 {from,to}，端点 RFC3339；query 是非空字面子串，不分词、不推理。查询不标记平台消息已读，也不加入群。

message.get 的 offset_bytes 默认 0，必须在 UTF-8 边界；max_bytes 默认 16384，上限 32768。返回 next_offset_bytes，内容删除/过期返回明确状态。附件首轮仅元数据，没有未定义的“自动获取附件”操作。引用包含值不代表永远有权读取。

## 查询、核对与人工解除

operation.get 支持在未收到 operation_id 时按原 operation+幂等键查询；若尚未发现记录返回 not_found，并明确这不能证明原请求永远不会提交。若要再次提交原请求，必须使用原键与原输入，由唯一约束避免重复受理。已发现记录则从 resource_refs 读取对象当前状态，原安全响应已过期时返回 result_expired 而不再执行。

retry 只允许明确未送达且 retryable 的失败项；cancel 只撤销提交点之前的工作。submitting/unknown 的 cancel 返回 delivery_unknown（出站为 outbound_unknown），不能擦除未知。accepted 的 cancel 返回当前状态和 already_submitted warning，不声称工作停止。

resolve 是操作员显式解除 unknown 的唯一人工入口，resolution 为 assume_received_no_retry 或 abandon_no_retry，reason 必填。它记录 resolved/manual，持久禁止相同投递再次发送，不伪造 accepted/started；解除目标顺序屏障后仍需原生 idle 证据才能提交后续 queue。它不授权模型自动采用建议，也不切换原生目标。

## 错误代码与恢复

| code | 确定性行为 |
| --- | --- |
| invalid_argument / limit_exceeded | 给字段路径与预期类型；none 请求可修正 |
| unauthenticated / forbidden | 不泄露不可见对象，不换主体绕过 |
| not_found | 仅当前可见范围；查询台账为空不证明网络未执行 |
| ambiguous_target / target_unbound | 返回允许的候选/绑定操作，不自动选取 |
| stale_reference / revision_conflict | 重读原对象，保留原意图 |
| preview_invalid / preview_stale / preview_expired / already_committed | 修正后再预览，或核对已提交的原操作 |
| target_offline / target_busy / permission_pending | 按明确状态等待，不猜意图或审批 |
| unsupported / incompatible | 不隐式降级、切工具或换模型 |
| idempotency_conflict / idempotency_expired | 不同请求同键拒绝；过期响应查原操作 |
| delivery_unknown / outbound_unknown | 已有对象先 reconcile，禁止盲重试 |
| lifecycle_unknown / instance_not_ready / profile_conflict | 查原 lifecycle/instance；stopping 拒绝新 send/create/订阅启用，不另起进程、不按标题猜创建结果 |
| catalog_incomplete / source_unavailable | 返回允许的覆盖/时间与缺口；不声称全量无匹配，不自动启动来源 |
| cursor_expired / content_expired / reply_context_expired | 重新发现授权引用，不拼回旧地址 |
| rate_limited / unavailable | 只在 effect_state 与确定未送达证据允许时重试 |
| storage_unavailable / capacity_exceeded | 保持积压与损失边界可见，不确认未持久事件 |

retryable 不是重发授权。CLI/MCP 原始超时通常无法知道是否已经记录，必须走操作查询。DJ 不能借助模型判断“这次大概没有发出去”。

## 列表过滤与确定性值

filters 只接受各表明确定义的字段：connection 为 platform/state；agent 为 tool/surface/state/display_name_exact；subscription 为 agent_id/state；delivery 为 agent_id/event_id/state/origin/route_id/session_key/operation_id。origin 为 direct/subscription_event，其余为相应枚举或精确 ID，多个字段按 AND，不支持自由查询语言。route_id/session_key 过滤不授予读取同队列其他主体记录的权利；未登记直发可按 operation_id、session_key 或无过滤查本人记录。所有结果先按可见性过滤，再以稳定 ID/序号排序分页；不给模型未授权候选。

time_range 为 from 包含、to 不包含，from<to；无范围表示当前保留的可见语料。无可靠 native 等价过滤就 unsupported，不执行模型检索。状态查询返回可见原生事实与限制，不需要模型判断或副作用。

## 本地 API 投影

首期 API 与 CLI/MCP 同时作为统一接入面，经私有 UDS 的 POST /v1/operations 接收 api_version/operation/arguments；具体通道与认证见技术选型，不等于远程 Streamable HTTP。arguments 逐字段使用本目录及 Agent 控制契约，不接受 principal、任意 shell、原始 endpoint 或自然语言命令。成功/领域失败均按固定 envelope 返回，错误 HTTP 状态也不得丢掉机器字段。

```json
{"api_version":"1","operation":"session.list","arguments":{"scope":{"tools":["opencode","pi"]},"limit":50}}
```

这一 API 只是同一 execute 的投影，跨入口仍按同一主体/操作/幂等键去重。不以 IM 聊天消息作为管理命令入口，也不维护 UI 状态库；既有 IM 读写 API 继续保留。

施工落实的传输状态映射见 [施工接口](../construction/contracts.md#1-操作目录与入口)：有效业务 Result 用 HTTP 200 承载，业务成败仍检查 ok/code/effect_state；格式/认证/请求预算/服务启动故障使用相应 HTTP 状态并尽可能保留安全 envelope。不能因 HTTP 200 就把 unknown 或领域失败当成功。
