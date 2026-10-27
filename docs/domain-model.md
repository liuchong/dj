# 领域模型与订阅规则

DJ 的类型和规则都是确定性数据，不要求 DJ 理解自然语言。所有 DJ ID 为不透明字符串；原生 ID 原样保存，不强转数字。时间为 UTC RFC3339，顺序使用 ingress_seq/delivery_seq，64 位序号在 wire 上为十进制字符串；revision 是有界安全正整数并发修订，不是协议版本。

宿主仅为 event、delivery、attempt、receipt、binding、reply_context_record、route、agent、subscription 九类新实体主键生成 UUIDv7：48 位宿主 Unix 毫秒与 74 位 CSPRNG 随机字段，不使用共享计数器。前缀和标准连字符 UUID 长度不变，旧 UUIDv4 原样共存。非法或越界的宿主时间明确失败，不取整、夹紧或回退；同毫秒与时钟回拨均不承诺生成顺序。主键仍不承担授权、TTL 或业务序列含义，碰撞由原数据库唯一约束拒绝并按原事务回滚。

其余宿主前缀继续生成 UUIDv4；owner、epoch、launch、dispatch 等控制/幂等标识与独立受限句柄工厂均不改。reply_context_record 是内部主键，信封中的 reply_context_id 是另行签发、绑定主体及期限的 UUIDv4 句柄，知道内部主键不授予回复权限。静态混合主键集合仍按现有全序分页；当前页游标之前并发新增的键须重新查询，不由 UUID 时间推断快照成员或业务顺序。

## 对象与所有权

订阅可附 instruction_policy（prompt/task_template）。它与结构化筛选条件一同版本化：筛选决定是否产生贡献，模板只为目标 AI 装配任务说明。多个有效订阅合并到同一 delivery 时各自保留指令及订阅版本，不互相覆盖。原消息 content 保持独立的外部数据；权限、目标、reply_context 与实际任务完成状态不由提示词改变。字段和字节边界见统一操作契约。

| 类型 | 字段与约束 | 生命周期 |
| --- | --- | --- |
| Principal | principal_id、kind(operator/agent/service)、grant_refs、bound_agent_id?、target_constraint? | 由可信接入配置赋予，不信任请求自报 |
| Connection | connection_id、platform、tenant_ref、account_ref、display_name、credential_ref、brand、identity、source_delivery、source_health、capabilities、state、revision | 配置持久；source_health 安全字段见 IM 接入；秘密另存 |
| ConversationAddress | connection_id、native_chat_id、native_thread_id?、thread_kind | 原生精确地址；未知 thread 不转换为空线程 |
| ConversationHandle | conversation_ref、principal_id、address、source_revision、expires_at | 查询/resolve 签发的类型化地址引用；非凭据 |
| AgentTarget | agent_id、route_id、owner_principal_id、recipient_principal_id、tool、surface、display_name、native_namespace、native_session_id、canonical_target_key、binding_mode、state、revision | 长期登记目标；原生会话不可变 |
| TargetRoute | route_id、canonical_target_key、session_key、binding_id? | 精确原生会话的统一队列；不授予身份/权限 |
| AgentBinding | binding_id、route_id、agent_id?、adapter_id/version、instance_id、instance_epoch、endpoint_ref、verified_at、expires_at、capabilities、runtime_state | 临时；未登记直发也可有已核验 Binding |
| Event | event_id、source_key、connection_id、conversation、native_message_id、event_kind、source_revision、sender、addressed_bot?、reply_to?、content、attachments、source_time?、received_at、ingress_seq | 不可变；编辑形成独立事件 |
| MessageSnapshot | message_ref、principal_id、conversation、native_message_id、source_revision、expires_at | native 查询的只读快照，不是实时 Event |
| Subscription | subscription_id、owner_principal_id、agent_id、selector、resolved_sources、predicate、context_policy、delivery_policy、start_seq、cutover_seq、state、revision | 一个目标、多来源；agent_id 不可更新 |
| Preview | preview_id、principal_id、normalized_spec、spec_hash、target_revision、source_refs、policy_snapshot、subscription_id?、expected_revision?、expires_at、committed_operation_id? | 有界短期票据；默认 10 分钟 |
| MatchDecision | decision_id、event_id、subscription_id/revision、result、reason_codes、policy_revision | match/no_match/indeterminate；不含模型评价 |
| Contribution | delivery_id、subscription_id/revision、effective_grant_refs、context_policy、delivery_policy、expires_at | 每条命中订阅的独立有效贡献 |
| Delivery | delivery_id、route_id、origin、agent_id?、event_id?、envelope_ref、delivery_seq、state、revision、expires_at、native_ref? | subscription_event 或 direct；原生目标共用队列 |
| Attempt / Receipt | attempt_id、delivery_id、binding_epoch、dispatch_key、started_at；receipt_id、kind、evidence_level、native_ref? | 尝试与观察追加；不覆盖历史 |
| ReplyContext | reply_context_id、delivery_id、recipient_principal_id、destination、native_reply_to、allowed_actions、expires_at | 固定回复目的地，使用时重检权限 |
| Outbound | outbound_id、principal_id、reply_context_id?、destination、content、idempotency_key、state、revision、parts、native_message_ids | 发送 outbox；子消息单独结算 |
| Operation | operation_id、principal_id、operation、idempotency_key_hash、request_hash、resource_refs、state、safe_result | 操作受理台账；支持超时查询 |

工具/实例/会话目录、SessionHandle、CatalogRun 与 LifecycleAction 的字段、有效期、范围和状态唯一维护于 [Agent 控制面](agent-control-plane.md)，不与 IM ConversationHandle/MessageSnapshot 混用。SessionRecord 可在没有 AgentTarget 或订阅时存在，register 采用已有 TargetRoute 而不另建一条原生队列。

ConversationHandle 默认有效 24 小时，来源关闭/移除/语义变更时失效；纯健康时间更新不改变其地址身份。candidate_ref 默认 5 分钟，绑定精确实例 epoch。preview_id/候选/对话/回复引用不可互换，也不能绕过当前主体授权。

提交订阅时在内部 resolved_sources 保存稳定 ConversationAddress、来源身份修订与授权范围；selector 中原始 conversation_ref 只保留请求来源。短期句柄过期不使已提交订阅失效，不要求模型续引用或轮询。运行时按稳定地址、当前来源身份和授权重新检查；来源移除/语义改变则 blocked，不能自动迁到同名地址。新建/更新 spec 或主动发送仍须使用当前有效句柄，不能复用内部解析字段绕过校验。

message_ref 默认 10 分钟有效；重新读取若源修订变化则 stale_reference，不把可变正文拼成一个快照。local 查询返回 Event，native 查询返回 MessageSnapshot，二者不共享入库去重主键或路由序号。

source_key 在连接内唯一：只有适配器确认原生事件 ID 具有稳定业务去重语义时才优先使用；否则声明消息 ID+事件类型+源修订的稳定组合。Lark user 轮询的 created 按原生 message_id+created 去重；历史 bot receive_v1 的 event_id 只作传输标识，不参与当前接收路径。见首批范围。不得按正文相似度去重。缺少可靠源修订时公开编辑事件保证限制。

## Agent 身份与绑定

surface 为 desktop/cli/sdk；tool 为 codex/claude/cursor/opencode/pi/agy/antigravity，未知插件须先由操作员注册描述符。binding_mode 为 existing/managed。历史只作为发现候选，不能当活 Binding。

主体系绑定由可信宿主/启动配置创建，初始 target_constraint 限制工具、namespace 与原生会话。Agent 自报信息必须与候选及约束一致；不是靠猜测当前宿主或标题验证所有权。普通 Agent 只为自己登记；操作员代登记时必须指定配置中已存在的 recipient_principal_id，不把操作员全权限凭据发给目标。

runtime_state 为 unknown/idle/busy/waiting_permission/offline/incompatible。原生状态缺失就保留 unknown。注册通过后原子建立 recipient 的 bound_agent_id/target_constraint 绑定；操作员代登记也执行该步骤，owner 与 recipient 的授权保持独立。同主体重复登记相同 canonical_target_key 返回已存在目标，不再建一条；其他主体无授权不可据此探知对象存在。

原生目标身份不因 display_name 改变。重绑只能更新同一目标的临时 Binding；不同窗口/CLI 视图若指同后端，适配器给出同一 canonical_target_key。existing 离线不自动新建或恢复；managed 的进程创建单独受操作员配置控制。

## 订阅 spec

完整领域合同与首期开放能力分别维护；当前对未启用的 steer、编辑/删除来源事件等返回 unsupported，范围见 [首批接入](release-scope.md)。

以下为传给 subscription.preview 的 spec；句柄来自发现结果，示例不可直接复用为真实目标。

```json
{
  "agent_id":"agt_example",
  "selector":{
    "sources":[{"conversation_ref":"cvr_example","include_threads":false}],
    "event_kinds":["message.created"]
  },
  "predicate":{"all":[
    {"field":"sender.kind","op":"eq","value":"human"},
    {"field":"text","op":"contains","value":"请检查"}
  ]},
  "context_policy":{"mode":"current","max_events":1,"max_bytes":16384},
  "delivery_policy":{"busy":"queue","offline":"hold","ttl_seconds":86400},
  "start":"now"
}
```

sources 必填且非空，每项必须是 ConversationHandle，不接受自然语言地址或拼接原生 ID。include_threads 默认 false；聊天主流引用只覆盖主流，true 才包括子话题；精确话题引用与 true 冲突。event_kinds 缺省仅 message.created，规则引擎定义 created/edited/deleted 三种，具体来源首期只开放其已声明能力；显式订阅编辑/删除必须在此列出。正文分类不改变事件类型。

predicate 缺省 {all:[]}。AST 为 all/any/not 或叶子，节点形状互斥；空 all 为 true，空 any 拒绝，not 只接受一个子节点。叶子字段为 event_kind、sender.id、sender.kind、addressed_bot、reply_to.id、text。eq/in 用与字段相同的类型，in 为非空同类型数组；contains/prefix 仅接收 text 字符串，禁止隐式数字、大小写、分词、正则或代码转换。

缺失字段产生 indeterminate，只有明确 true 才触发；not(indeterminate) 仍为 indeterminate。sender.kind 的字面枚举 unknown 可被显式比较，不代表值缺失。DJ 依平台原生身份及配置映射标记来源，不能根据写作风格猜作者。

若正文不完整：contains 找到原文子串时为 true，未找到为 indeterminate；eq 为 indeterminate；prefix 在已有完整前缀足够时正常比较，无法确定时为 indeterminate。indeterminate 记录缺口，不把它当 no_match 或交给模型猜。路由默认不为判定而下载更多正文；调用方可在授权内读取和决定下一项操作。

深度上限 8、叶子上限 64、sources 上限 100、event_kinds 上限 3、in 值最多 64。超限在 preview 拒绝。规范化只补明确缺省、去重完全相同项并稳定排序来源/事件类型，不重排有序内容，不做同义词、语义等价或自然语言转换。

## 上下文、投递与生效边界

recent 为默认，current 可显式选择；recent 仅选当前事件之前、同连接/原生对话/同话题且目标主体有权读的事件，最多 20 条/32 KiB；当前事件最多注入 16 KiB。所有截断显式给出 bytes 与读取引用，附件只提供元数据。列表和上下文不借机遍历整个目标历史。历史、引用链和继续读取统一见 [消息上下文](specs/0007-message-context.md)，默认直接读DJ本地缓存，不执行search或平台轮询。

busy=queue 为默认，steer 必须显式并具备能力；offline 首轮仅 hold。ttl 默认 86400 秒，允许 60–604800。start 首轮仅 now，按 commit 后的 ingress_seq 生效；backfill 尚不支持，不能把旧事件自动补成实时输入。

更新/暂停/删除设置 cutover_seq 与新 revision。事件按 ingress_seq 对应规则版本匹配；提交前撤销所有已过时或被暂停/删除的贡献。resume 产生新 start_seq，旧贡献不复活。已由目标接受的输入不因退订而撤回。最终提交时点定义与租约竞态见投递文档。

同目标/事件合并时，贡献间的策略规则见 [可靠投递](delivery-storage.md)：不能任取一条，也不能合并出更大权限。每个贡献独立到期，剩余有效贡献继续成立。

origin=subscription_event 时 agent_id/event_id 必填并使用 Contribution；origin=direct 时保存认证发送主体、operation_id 与独立 delivery_policy/授权快照，event_id=null，agent_id 可空，不伪造订阅贡献。direct 信封 source.kind=api、reply_context_id=null。两类都以 route_id 调度，不能互相绕过 unknown。

direct 的 delivery_policy 仅 busy/offline/ttl_seconds，不接 context_policy；当前纯文本就是本次输入。agent_id 是受理时别名，历史字段不因后来登记变化。AgentTarget 关闭撤销其未提交订阅贡献，route/Binding/unknown 及独立 direct 继续保留。长期路由身份属于原生会话，recipient 绑定属于订阅接线，不能混为同一生命周期。

## 复合类型与状态

- Sender 为 {id:string,kind:human|bot|agent|unknown,display_name?:string}；reply_to 为 {id:string,sender_id?:string}。
- Event.content 为 {kind:text|tombstone|unsupported,text?:string,truncated:boolean,original_bytes?:integer}；删除只保留 tombstone，不能恢复已删除正文。
- AttachmentRef 为 {attachment_id:string,kind:string,file_name?:string,mime_type?:string,size_bytes?:integer,native_handle_ref?:string}；无凭据 URL/机器路径。
- Candidate 包含 candidate_ref、tool、surface、native_namespace、native_session_id、scope、live_receiver、runtime_state、capabilities、expires_at 和安全 target_summary；scope 为 history/live/desktop-open/managed。
- 能力项为 {status:supported|unsupported|unknown,evidence_kind,checked_at,limitations:array}，unknown 不能视为支持。
- Connection.state 为 configured/connecting/online/degraded/offline/incompatible；AgentTarget.state 为 registered/closed；Subscription.state 为 active/paused/deleted。
- Delivery.state 为 ready/deferred/blocked/submitting/accepted/unknown/failed/expired/cancelled/resolved；Outbound 使用同一状态集合（deferred/blocked 可表发送限流/配置等待）。Operation.state 为 recorded/done/result_expired；done 只指业务 API 已受理结算，不是模型任务结束。
- Outbound.content 为 {type:text,text:string}；parts 是稳定有序子消息记录，每项有 part_id、dispatch_key、state、native_message_id?，首轮若平台无法提供安全拆分则发送前拒绝。
- ReplyContext 在实际输入提交前签发，默认有效 24 小时，不晚于正文保留期限；绑定 recipient 主体与精确原话题。允许读取不代表允许回复，缺少发送权限时 reply_context_id=null 且 allowed_actions 不含 reply。
- Delivery 信封含 schema_version=1、kind=external_message、delivery/event ID、source、sender、匹配原因、content、attachments、reply_context_id?、allowed_actions。正文永远是结构化数据字段，不拼入受信任头。传输版本、信封 schema_version 与对象 revision 分开。

信封按 origin 分支：subscription_event 使用 IM source、Sender、event_id 和匹配贡献；direct 使用 source.kind=api、ApiSender={principal_id,principal_kind:operator/agent/service}、event_id=null、无匹配贡献和无 IM 回复引用。不能将 API 主体伪造成人类 IM 作者；未接线 DJ 工具的接收方 allowed_actions 为空，输入仍可留在原生会话。当前均为未发布草案，两个分支的 schema 必须一起验证。
