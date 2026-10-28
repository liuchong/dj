# 逐操作字段与受理资料

> 历史资料：保留当时的设计、状态与验收记录，不作为当前使用或施工指令。当前说明见[文档索引](../index.md)和[项目状态](../status.md)。
当前运行目录共 63 个操作，来自 src/application/operations.eli 的 operationCatalog；结构、语义与结果校验分别见 operations/schema/results 模块。CLI、MCP、本地 API 和 GEPO 共用该目录、权限和受理台账。本文保留原施工基线 4e06ea8 的字段资料，并同步新增主动消费接口；工具能力与正式运行限制以 [当前发布范围](../release-scope.md#能力与验证范围)及服务实际返回为准，描述符存在不代表适配器支持。handler 归属见 [contracts](construction-contracts.md)。

## 1. 共用字段与检查顺序

每个 arguments 根对象和业务嵌套对象均拒绝未知字段。本文 `?` 表可省略，`XOR` 是恰好一个分支，斜线只分隔枚举/名称，不把它当自由 action。未列的可选项不能自动接受。所有操作可带 request_id:string 追踪；认证主体始终由通道提供。

| 记号 | 精确字段/类型 | 规则 |
| --- | --- | --- |
| K | idempotency_key:string | 非空，同主体/operation 唯一逻辑请求；变更/refresh/reconcile 必填；原输入原键重放 |
| R | expected_revision:positive safe integer | 修改已有对象/retry/cancel/resolve 必填；重放已受理原记录优先于重验新 revision |
| P | limit?:positive safe integer、cursor?:string | 列表缺省 50、上限 200；cursor 绑定主体/条件/授权/快照，不与 continuation 混用 |
| Id / Ref | 非空 string | 不透明；不强转数字、不从前缀猜类型；Ref 还检查实际记录的 kind/主体/期限 |
| TimeRange | {from:string,to:string} | UTC RFC3339，from 包含/to 不包含且 from<to；无范围查当前允许保留语料 |
| TextContent | {type:"text",text:string} | 非空，UTF-8 ≤16384 字节；原生更小限制另检，不能用 JSON Schema maxLength 冒充字节数 |
| DeliveryPolicy | {busy?,offline?,ttl_seconds?} | busy=queue/steer，offline=hold，TTL 整数 60–604800/默认86400；首期 steer 为合法已知但 unsupported 分支，直发无 context_policy |

流程为：认证 → 按原 operation/key 找已受理结果并核对请求摘要/当前可见性 → 新请求结构校验/明确缺省 → 精确资源与当前授权 → 引用/能力/preview/revision/gate 前置条件 → 事务内重检可变条件并原子受理。读取/preview/probe 不伪造 Operation/Delivery；观察可更新原生事实但不触发模型。校验失败 effect_state=none；变更响应丢失不能仅凭请求超时声称 none。

K/R 表空白表示不要求；operation.get 的 idempotency_key 是 lookup 字段，不是创建新操作的 K。subscription.preview 更新模式的 R 是特定条件字段，见表。所有 input 的默认由共享 normalize 补，不由 Ajv useDefaults、CLI 或 SDK 各自补。

## 2. IM、身份、订阅和投递

data 名称为已定义业务对象的安全 Projection，Page 使用固定 items/next_cursor/complete。变更的 operation_id 在 envelope，受理资源 ID 同时进入 typed resource_refs；不能把返回 Operation.done 理解为外部任务完成。

| operation | 必填业务字段 | 可选业务字段 | K/R | data / 当前能力与检查 |
| --- | --- | --- | --- | --- |
| service.status | 无 | 无 | — | api_version、build_id、operation_catalog_digest、visible_operations、限制/各源各目标/队列安全摘要 |
| operation.get | operation_id XOR (operation,idempotency_key) | 无 | lookup | 本人 Operation/current safe_result/resource_refs；not_found 不证明原请求不会提交 |
| connection.list | 无 | filters、P | — | `Page<ConnectionProjection>`；filters.platform/state |
| connection.get | connection_id:Id | 无 | — | ConnectionProjection（含授权过滤的 brand/identity/source_delivery/source_health，见 IM 接入）；不输出 credential 值 |
| connection.probe | connection_id:Id | 无 | — | 只读健康/能力/凭据状态摘要，不改配置或收件所有权 |
| conversation.list | connection_id:Id | parent_ref:Ref、P | — | `Page<ConversationHandle>`；仅已授权来源/话题范围，不声称整个平台全量 |
| conversation.resolve | connection_id:Id、chat_id:string、thread_id:string/null | 无 | — | 精确 ConversationHandle；thread_id 必须明确，null 不代表未知 |
| agent.whoami | 无 | 无 | — | principal_id、bound_agent_id?、binding_state；来自认证绑定，不猜宿主 |
| agent.discover | tool:string | surface、instance_ref:Id、scope、P | — | `Page<Candidate>`；surface=desktop/cli/sdk；scope=history/live/desktop-open/managed |
| agent.register | candidate_ref:Ref、display_name:string、binding_mode | recipient_principal_id:Id | K | AgentTarget/BindingProjection；existing/managed；recipient 仅 operator 代登记时必填，普通 Agent 禁传 |
| agent.list | 无 | filters、P | — | `Page<AgentTargetProjection>`；tool/surface/state/display_name_exact 精确过滤 |
| agent.get | agent_id:Id | 无 | — | AgentTargetProjection；不是工具父节点 |
| agent.probe | agent_id:Id | 无 | — | 当前原生身份/状态/能力，不创建、唤醒或发送测试消息 |
| agent.rebind | agent_id:Id、candidate_ref:Ref | 无 | K/R | 同 tool/namespace/native_session 的新 Binding；不能改到另一目标 |
| agent.unregister | agent_id:Id | 无 | K/R | closed/订阅暂停撤销摘要；不杀工具、不清 route/unknown、不取消 direct |
| subscription.pull | subscription_id:Id | lease_seconds:整数1–300/默认60 | K | InboxPull；必须是目标 Agent 的 recipient 并具备 subscription.consume；一次至多一项，最多扫描50，空结果也持久去重；不创建原生 Delivery |
| subscription.ack | claim_ref:Ref、disposition=consumed/retry | 无 | K | Inbox；确认当前领取或释放供重领，不声明任务完成；校验主体/版本/TTL/领取代次 |
| subscription.preview | spec:SubscriptionSpec | sample_event_ids:`Array<Id>`、subscription_id:Id、expected_revision | — | 固定 normalized_spec/resolved_sources/target、warnings/issues；无阻断才发 preview_id；更新模式 ID/R 成对 |
| subscription.create | preview_id:Ref | 无 | K | Subscription/start_seq/revision；不接受第二份 spec |
| subscription.list | 无 | filters、P | — | `Page<SubscriptionProjection>`；filters.agent_id/state |
| subscription.get | subscription_id:Id | 无 | — | 当前 Subscription/解析范围及 revision |
| subscription.update | subscription_id:Id、preview_id:Ref | 无 | K/R | 同对象/revision 的票据与新版本/cutover_seq；agent_id 不可变 |
| subscription.pause | subscription_id:Id | 无 | K/R | paused/revision/cutover_seq/已提交数量；不撤回已提交事实 |
| subscription.resume | subscription_id:Id | 无 | K/R | active/新 start_seq；不复活旧贡献或补暂停期；stopping 拒绝 |
| subscription.delete | subscription_id:Id | 无 | K/R | deleted/revision/cutover_seq；独立 direct 保留 |
| message.list | conversation_ref:Ref | time_range:TimeRange、corpus、P | — | `Page<Event/MessageSnapshot>`；首期 local，native 明确 unsupported |
| message.search | conversation_ref:Ref、query:string | time_range:TimeRange、corpus、P | — | 字面非空子串命中与可读引用，不解析为任务意图 |
| message.get | event_id:Id XOR message_ref:Ref | offset_bytes、max_bytes | — | 元数据/UTF-8 正文分页/附件引用，删除/过期不泄露 |
| message.send | destination_ref:Ref、content:TextContent | 无 | K | Outbound/state/revision；固定精确 IM 地址；首期必须单条可表示 |
| message.reply | reply_context_id:Ref、content:TextContent | 无 | K | Outbound/state/revision；固定原账号/消息/话题，不能另带 destination |
| outbound.get | outbound_id:Id | 无 | — | Outbound/parts/安全原生回执，不等于 Agent 完成 |
| outbound.reconcile | outbound_id:Id | 无 | K | 只核对原生事实，unknown 可能仍 unknown，不重发 |
| outbound.retry | outbound_id:Id | 无 | K/R | 仅可证未送达且 retryable 的单位；不重发已接受内容 |
| outbound.cancel | outbound_id:Id | 无 | K/R | 只取消提交点前；unknown/submitting 不擦除，已接受给限制 |
| outbound.resolve | outbound_id:Id、resolution、reason:string | 无 | K/R | operator-only；assume_received_no_retry/abandon_no_retry；manual 非原生接受证据 |
| delivery.list | 无 | filters、P | — | `Page<DeliveryProjection>`；agent_id/event_id/state/origin/route_id/session_key/operation_id；按当前主体过滤 |
| delivery.get | delivery_id:Id | 无 | — | Delivery/贡献/安全回执/reply_context_id?；direct 可空 agent/event |
| delivery.reconcile | delivery_id:Id | 无 | K | 核对原目标/原 attempt，不以其他会话文本猜未送达 |
| delivery.retry | delivery_id:Id | 无 | K/R | 仅 definite_not_sent 的安全重试，重检目标/当前发送授权 |
| delivery.cancel | delivery_id:Id | 无 | K/R | 取消自有未提交输入；不越 origin/主体取消别人贡献 |
| delivery.resolve | delivery_id:Id、resolution、reason:string | 无 | K/R | operator-only 不重发结案；仍须 idle 才可推进后续队列 |

filters 内每项值为对应枚举或精确字符串，字段间 AND；不能接受任意表达式/SQL。instance_ref 在 agent.discover 中就是已配置 ToolInstance 的稳定 ID 参数，不是 endpoint URL；未装配的工具/形态只给能力限制，不启动对应程序。display_name 是非空展示文本，不参与身份或路由。

## 3. 工具目录、查询及生命周期

| operation | 必填业务字段 | 可选业务字段 | K/R | data / 当前能力与检查 |
| --- | --- | --- | --- | --- |
| tool.list | 无 | filters、P | — | `Page<ToolDescriptor>`；filters.tools/adapter_state |
| tool.get | tool_id:Id | 无 | — | 安全工具描述/能力，不扫描任意进程 |
| profile.list | 无 | tools:`Array<Id>`、P | — | `Page<LaunchProfileProjection>`；profile_id/revision/workspace_refs/动作，不含 argv/秘密 |
| instance.list | 无 | tools:`Array<Id>`、ownership、P | — | `Page<ToolInstanceProjection>`；ownership=existing/managed，实例状态与会话覆盖 |
| instance.get | instance_id:Id | 无 | — | 当前 instance_epoch/revision/归属/状态，与历史 lifecycle 分开 |
| catalog.refresh | 无 | scope:SessionScope、include_content:boolean、continuation:Ref、budget:RefreshBudget | K | CatalogRun/catalog_run_id；include_content 缺省 false；外部只读，不启动工具 |
| catalog.get | catalog_run_id:Id | 无 | — | run state/预算/覆盖/continuation，不隐式续扫 |
| session.list | 无 | scope:SessionScope、sort、P | — | SessionPage；sort 默认 session_key_asc，可选 updated_at_desc 索引顺序 |
| session.get | session_ref:Ref XOR session_key:Id | 无 | — | SessionProjection/当前获准短期 session_ref，未登记也可用 |
| session.resolve | instance_id:Id、native_session_id:string | 无 | — | 精确 SessionProjection/session_ref；原生 ID 原样，不按标题选择 |
| session.probe | session_ref:Ref | 无 | — | 只读 receiver/epoch/checked_at/有效期/能力；不登记/输入/新建 |
| session.search | query:SessionQuery | scope:SessionScope、sort、P | — | SessionPage/matched_fields；sort 仅 session_key_asc，组内扫描完才输出 |
| session.message.list | session_ref:Ref | time_range:TimeRange、corpus、P | — | MessagePage/session_message_ref；首期 indexed，不自动读完整原生历史 |
| session.message.get | session_message_ref:Ref | offset_bytes、max_bytes | — | 绑定正文版本的安全元数据/UTF-8 正文分页 |
| session.message.search | query:SessionQuery | scope:SessionScope、time_range:TimeRange、P | — | MessagePage/会话和消息引用；fields 仅 message.text、固定消息顺序 |
| session.send | session_ref:Ref XOR agent_id:Id；content:TextContent | delivery_policy:DeliveryPolicy | K | Delivery/delivery_id/route_id；无 Event/Subscription/登记前置，stopping 拒绝 |
| instance.start | profile_id:Id、expected_profile_revision | 无 | K | LifecycleAction/lifecycle_id/instance_id；获准 profile，单 slot、不自由传 argv/cwd |
| session.create | instance_id:Id、expected_instance_epoch、workspace_ref:Ref | title:string | K | LifecycleAction；核验后 session_key/session_ref；title 非空≤256 UTF-8 字节；Pi 同 RPC unsupported |
| instance.stop | instance_id:Id | 无 | K/R | LifecycleAction；仅 DJ-owned managed，先关 gate 再 drain，期限到不强杀 |
| lifecycle.get | lifecycle_id:Id | 无 | — | 历史动作/稳定资源引用+当前实例状态；可重发当前获准短期 ref |
| lifecycle.reconcile | lifecycle_id:Id | 无 | K | 按 launch token/原生关联键加证据，不按标题猜或重建 |
| lifecycle.resolve | lifecycle_id:Id、resolution、reason:string | 无 | K/R | operator-only，resolution 仅 abandon_no_retry；不释放未证退出的 slot |

expected_profile_revision 和 R 同为 positive safe integer；expected_instance_epoch 是原样不透明字符串，不拿 revision 或 PID 顶替。profile.list/instance.list 的 tools 最多 32、显式空数组拒绝。

## 4. 查询/分页嵌套类型及首期能力

| 类型 | 精确字段和约束 |
| --- | --- |
| SessionScope | tools?:`Array<Id>`（最多32）；instance_ids/workspace_refs/agent_ids/session_keys?:`Array<Id>`（各最多100）；visibility?:`Array<history/live/desktop-open/managed>`；runtime_states?:`Array<unknown/idle/busy/waiting_permission/offline/incompatible>`；registered?:boolean；updated_range?:TimeRange |
| SessionQuery | text:string，非空≤1024 UTF-8 字节；fields 非空去重数组，session.search 允许 title/native_session_id/workspace_label/message.text；mode="literal"；大小写敏感，无分词/同义/正则 |
| RefreshBudget | max_records?/max_messages?/max_bytes?/max_seconds?，正整数、不得超过 10000/1000/16777216/60；续扫 scope/include_content/授权须与原 continuation 一致 |
| BodyPage | offset_bytes?:非负整数/默认0；max_bytes?:正整数/默认16384/上限32768；偏移必须 UTF-8 边界，返回 next_offset_bytes |
| SessionPage / MessagePage | 固定 items/next_cursor/complete，另有 snapshot_id/as_of/coverage_complete/sources/stale；空 items 但有 cursor 仍未查完，不能报不存在 |
| source coverage | 每个可见来源的 covered/partial/offline/unsupported、最后观察、覆盖字段/内容范围/原因；未授权来源连存在性/计数也不泄露 |

SessionScope 不同维度 AND、数组内 OR、空数组拒绝；省略表示全部获准配置来源，不是全机器。IM message.search 的 query 是字面字符串，Agent 查询的 query 是上述对象，不能跨接口混用。正文未覆盖时，定点 catalog.refresh(scope.session_keys,include_content=true) 后再查，不要求注册或让模型设置 timer。

SubscriptionSpec 新增可选 delivery_mode（push/pull，默认 push）与 instruction_policy（prompt/task_template）；主动消费、确定性模板字段与限制见 [操作契约](../interfaces/operations.md#订阅待办拉取)。两者随订阅版本保存，修改仍走 preview/update 与 cutover。

SubscriptionSpec、Predicate、ContextPolicy、selector 的字段保持 domain-model.md 原定义：agent_id/selector.sources/固定事件类型、显式三值 AST、start=now；current/queue/hold 是首期组合。recent/steer/edited/deleted/backfill/native IM corpus/媒体/多片的已知未启用能力返回 unsupported，不静默改成已支持形状；完全未知字段/类型则 invalid_argument。preview sample_event_ids 上限20；create/update 只收固定票据，不收另一份 spec。

## 5. 输出与错误不变量

所有业务结果固定 ok/request_id/warnings/evidence_level/effect_state。ok=true 必有 data 且无 error；ok=false 必有 error 且无成功 data。受理变更返回 operation_id；error 固定 code/message/retryable/details/field_errors/next_actions。field_errors 最多10项、使用原业务字段 JSON Pointer，不回显秘密；next_actions 是确定建议而非自动执行授权。

evidence_level 为 none/service_record/native_protocol/agent_report/manual；effect_state 为 none/recorded/external_accepted/unknown。它们不能与对象 state 或业务完成混用。retryable 不授权盲重发，manual 不伪造原生接受；当前 grants 在 get/list/replay/submit/reply 都生效。

service.status 新增的 api_version/build_id/operation_catalog_digest 是公共技术身份：digest 由规范化完整操作描述符（名称/schema/默认/能力声明格式）计算，不含私有实例、授权投影或秘密。MCP 工具投影只在摘要匹配后使用，visible_operations 仍按主体过滤。摘要不匹配返回 incompatible，不启动影子服务或自动升级依赖。

未来 schema 编写至少逐操作生成：最小合法输入、缺必填、未知字段、错误类型、互斥两边同时/都无、K/R 缺失、超预算和当前授权/能力拒绝子例。只对该行适用的类别生成，不给 query 人为要求 K/R；对 mutation 超时查回另做真实事务/协议用例，不能把输入验证用例冒充外部效果证明。
