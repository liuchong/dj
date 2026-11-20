# 领域模型与订阅规则

DJ 的类型和规则都是确定性数据，不要求 DJ 理解自然语言。所有 DJ ID 为不透明字符串；原生 ID 原样保存，不强转数字。时间为 UTC RFC3339，顺序使用 ingress_seq/delivery_seq，64 位序号在 wire 上为十进制字符串；revision 是有界安全正整数并发修订，不是协议版本。

宿主仅为 event、delivery、attempt、receipt、binding、reply_context_record、route、agent 八类新实体主键生成 UUIDv7：48 位宿主 Unix 毫秒与 74 位 CSPRNG 随机字段，不使用共享计数器。前缀和标准连字符 UUID 长度不变，旧 UUIDv4 原样共存。非法或越界的宿主时间明确失败，不取整、夹紧或回退；同毫秒与时钟回拨均不承诺生成顺序。主键仍不承担授权、TTL 或业务序列含义，碰撞由原数据库唯一约束拒绝并按原事务回滚。

其余宿主前缀继续生成 UUIDv4；owner、epoch、launch、dispatch 等控制/幂等标识与独立受限句柄工厂均不改。reply_context_record 是内部主键，信封中的 reply_context_id 是另行签发、绑定主体及期限的 UUIDv4 句柄，知道内部主键不授予回复权限。静态混合主键集合仍按现有全序分页；当前页游标之前并发新增的键须重新查询，不由 UUID 时间推断快照成员或业务顺序。

## 对象与所有权

每个原生会话或分发组对应一个订阅槽位。订阅的 `rules[]` 决定触发，由命中分支生成上下文和指令。授权、接收目标以及回复引用由 DJ 按结构化字段核验。

| 类型 | 字段与约束 | 生命周期 |
| --- | --- | --- |
| Principal | principal_id、kind(operator/agent/service)、grant_refs、bound_agent_ids、target_constraint? | 由可信接入配置赋予，不信任请求自报 |
| Connection | connection_id、platform、tenant_ref、account_ref、display_name、credential_ref、brand、identity、source_delivery、source_health、capabilities、state、revision | 配置持久；source_health 安全字段见 IM 接入；秘密另存 |
| ConversationAddress | connection_id、native_chat_id、native_thread_id?、thread_kind | 原生精确地址；未知 thread 不转换为空线程 |
| ConversationHandle | conversation_ref、principal_id、address、source_revision、expires_at | 查询/resolve 签发的类型化地址引用；非凭据 |
| AgentTarget | agent_id、route_id、owner_principal_id、recipient_principal_id、tool、surface、display_name、native_namespace、native_session_id、canonical_target_key、binding_mode、state、revision | 长期登记目标；原生会话不可变 |
| TargetRoute | route_id、canonical_target_key、session_key、binding_id? | 精确原生会话的统一队列；不授予身份/权限 |
| AgentBinding | binding_id、route_id、agent_id?、adapter_id/version、instance_id、instance_epoch、endpoint_ref、verified_at、expires_at、capabilities、runtime_state | 临时；未登记直发也可有已核验 Binding |
| Event | event_id、source_key、connection_id、conversation、native_message_id、event_kind、source_revision、sender、addressed_bot?、reply_to?、content、attachments、source_time?、received_at、ingress_seq | 不可变；编辑形成独立事件 |
| MessageSnapshot | message_ref、principal_id、conversation、native_message_id、source_revision、expires_at | native 查询的只读快照，不是实时 Event |
| Subscription | target_key、owner_principal_id、agent_id 或 group_id、rules、delivery_mode、context_policy、delivery_policy、state、revision | 会话槽位按 session_key 稳定定位，分发组按 group_id 定位 |
| Preview | preview_id、principal_id、normalized_spec、spec_hash、target_revision、expected_revision、expires_at | 规范化订阅的短期提交票据 |
| MatchDecision | event_id、target_key、revision、result、matched_rule_ids | 确定性的命中决定 |
| Delivery | delivery_id、route_id、origin、event_id、target_key?、subscription_revision?、matched_rule_ids?、delivery_seq、state、revision、expires_at | 订阅通知与定向输入共用原生会话队列 |
| Attempt / Receipt | attempt_id、delivery_id、binding_epoch、dispatch_key、started_at；receipt_id、kind、evidence_level、native_ref? | 尝试与观察追加；不覆盖历史 |
| ReplyContext | reply_context_id、delivery_id、recipient_principal_id、destination、native_reply_to、allowed_actions、expires_at | 固定回复目的地，使用时重检权限 |
| Outbound | outbound_id、principal_id、reply_context_id?、destination、content、idempotency_key、state、revision、parts、native_message_ids | 发送 outbox；子消息单独结算 |
| Operation | operation_id、principal_id、operation、idempotency_key_hash、request_hash、resource_refs、state、safe_result | 操作受理台账；支持超时查询 |

工具/实例/会话目录、SessionHandle、CatalogRun 与 LifecycleAction 的字段、有效期、范围和状态唯一维护于 [Agent 控制面](agent-control-plane.md)，不与 IM ConversationHandle/MessageSnapshot 混用。SessionRecord 可在没有 AgentTarget 或订阅时存在，register 采用已有 TargetRoute 而不另建一条原生队列。

ConversationHandle 默认有效 24 小时，来源关闭/移除/语义变更时失效；纯健康时间更新不改变其地址身份。candidate_ref 默认 5 分钟，绑定精确实例 epoch。preview_id/候选/对话/回复引用不可互换，也不能绕过当前主体授权。

提交订阅时在内部 resolved_sources 保存稳定 ConversationAddress、来源身份修订与授权范围；规则中的 conversation_ref 保留请求来源。短期句柄过期不使已提交订阅失效，不要求模型续引用或轮询。运行时按稳定地址、当前来源身份和授权重新检查；来源移除/语义改变则 blocked，不能自动迁到同名地址。新建/更新 spec 或主动发送仍须使用当前有效句柄，不能复用内部解析字段绕过校验。

message_ref 默认 10 分钟有效；重新读取若源修订变化则 stale_reference，不把可变正文拼成一个快照。local 查询返回 Event，native 查询返回 MessageSnapshot，二者不共享入库去重主键或路由序号。

source_key 在连接内唯一：只有适配器确认原生事件 ID 具有稳定业务去重语义时才优先使用；否则声明消息 ID+事件类型+源修订的稳定组合。Lark 实时消息使用连接身份与原生 message_id、事件类型等稳定字段去重；传输 event_id 不替代业务消息身份。当前接线见[IM 适配](adapters/im.md)。不得按正文相似度去重。缺少可靠源修订时公开编辑事件保证限制。

## Agent 身份与绑定

surface 为 desktop/cli/sdk；tool 为 codex/claude/cursor/opencode/pi/agy/antigravity，未知插件须先由操作员注册描述符。正式接线使用 existing；数据模型中保留的 managed 描述不代表配置允许托管启动。历史只作为发现候选，不能当活 Binding。

主体系绑定由可信宿主/启动配置创建，可选target_constraint收窄工具、namespace与原生会话；普通本机AI身份可省略，由动作授权和准确原生候选核验。Agent 自报信息必须与候选及约束一致；不是靠猜测当前宿主或标题验证所有权。普通 Agent 只为自己登记；操作员代登记时必须指定配置中已存在的 recipient_principal_id，不把操作员全权限凭据发给目标。

runtime_state 为 unknown/idle/busy/waiting_permission/offline/incompatible。原生状态缺失就保留 unknown。注册通过后原子登记准确原生目标；同recipient可以有多个bound_agent_ids，可选target_constraint由部署配置收窄，不由登记改写。owner与recipient授权保持独立。同主体重复登记相同 canonical_target_key 返回已存在目标，不再建一条；其他主体无授权不可据此探知对象存在。

原生目标身份不因 display_name 改变。重绑只能更新同一目标的临时 Binding；不同窗口/CLI 视图若指同后端，适配器给出同一 canonical_target_key。existing 离线不自动新建或恢复；正式配置拒绝 managed_profiles，不通过创建进程替代原目标。

## 订阅 spec

下面的例子限定在一个已获准来源中触发包含关键词的人类消息。来源引用和 Agent ID 从实际发现结果取得。

```json
{
  "agent_id": "agt_example",
  "rules": [
    {
      "id": "review-request",
      "enabled": true,
      "sources": [{"conversation_ref": "cvr_example", "include_threads": false}],
      "event_kinds": ["message.created"],
      "predicate": {"all": [
        {"field": "sender.kind", "op": "eq", "value": "human"},
        {"field": "text", "op": "contains", "value": "请检查"}
      ]}
    }
  ],
  "context_policy": {"mode": "current", "max_events": 1, "max_bytes": 16384},
  "delivery_policy": {"busy": "queue", "offline": "hold", "ttl_seconds": 86400}
}
```

完整分支、默认条件和直订/组订阅合并规则见 [单线订阅](specs/0035-single-line-subscriptions.md)。缺失证据会保留 `indeterminate`，只有明确命中的分支触发。集合表示、比较运算和正文截断边界见 [订阅 Skill](../skills/dj/references/subscriptions.md)。

## 上下文、投递与生效边界

上下文可限制为当前消息或最近的获准历史。正文截断提供读取引用。Lark 附件在就绪时提供本机路径，也可沿附件引用补取。见 [消息上下文](specs/0007-message-context.md) 和 [附件读取](specs/0034-message-attachments.md)。

更新、暂停或删除推进修订，并取消旧修订尚未提交的推送、撤销待领项。恢复订阅从新起点开始。已提交的记录和原生队首状态继续由 [可靠投递](delivery-storage.md) 管理。

`origin=subscription_event` 携带命中订阅的 `target_key`、`subscription_revision` 和规则 ID。定向输入 `origin=direct` 携带认证主体和操作 ID，`event_id` 为 null。两类输入按同一原生会话的 `route_id` 调度。

## 复合类型与状态

- Sender 为 {id:string,kind:human|bot|agent|unknown,display_name?:string}；reply_to 为 {id:string,sender_id?:string}。
- Event.content 为 {kind:text|tombstone|unsupported,text?:string,truncated:boolean,original_bytes?:integer}；删除只保留 tombstone，不能恢复已删除正文。
- AttachmentRef 带 `attachment_ref`、`kind`、`state` 与原生来源锚点。就绪文件附本机 `local_path`、类型和大小。
- Candidate 包含 candidate_ref、tool、surface、native_namespace、native_session_id、scope、live_receiver、runtime_state、capabilities、expires_at 和安全 target_summary；scope 为 history/live/desktop-open/managed。
- 能力项为 {status:supported|unsupported|unknown,evidence_kind,checked_at,limitations:array}，unknown 不能视为支持。
- Connection.state 为 configured/connecting/online/degraded/offline/incompatible；AgentTarget.state 为 registered/closed；Subscription.state 为 active/paused/deleted。
- Delivery.state 为 ready/deferred/blocked/submitting/accepted/unknown/failed/expired/cancelled/resolved；Outbound 使用同一状态集合（deferred/blocked 可表发送限流/配置等待）。Operation.state 为 recorded/done/result_expired；done 只指业务 API 已受理结算，不是模型任务结束。
- Outbound.content 为 {type:text,text:string}；parts 是稳定有序子消息记录，每项有 part_id、dispatch_key、state、native_message_id?，首轮若平台无法提供安全拆分则发送前拒绝。
- ReplyContext 在实际输入提交前签发，默认有效 24 小时，不晚于正文保留期限；绑定 recipient 主体与精确原话题。已认证主体默认可读和回复，无需逐群发送权限；来源失效、身份变化或路由歧义时 reply_context_id=null 且 allowed_actions 不含 reply。
- Delivery 信封含 schema_version=1、kind=external_message、delivery/event ID、source、sender、匹配原因、content、attachments、reply_context_id?、allowed_actions。正文永远是结构化数据字段，不拼入受信任头。传输版本、信封 schema_version 与对象 revision 分开。

信封按 origin 分支：subscription_event 使用 IM source、Sender、event_id 和命中分支；direct 使用 source.kind=api、ApiSender={principal_id,principal_kind:operator/agent/service}、event_id=null、无订阅匹配与 IM 回复引用。不能将 API 主体伪造成人类 IM 作者；未接线 DJ 工具的接收方 allowed_actions 为空，输入仍可留在原生会话。当前均为未发布草案，两个分支的 schema 必须一起验证。

多对多接线现行边界见[0027](specs/0027-many-to-many-subscribers.md)：调用身份与接收目标分离，whoami返回登记数组，普通AI自行登记订阅；同事件协作提示不决定任务归属。
