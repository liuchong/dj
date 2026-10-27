# 面向模型的调用契约

DJ 对模型友好，指的是接口自描述、引用可直接复用、参数和结果结构稳定、错误可定位。DJ 不理解自然语言意图，调用方模型负责选择目标并生成结构化规则；服务负责拒绝无效、失效或越权请求。

## 减少猜测与 ID 拼装

所有发现结果都同时返回机器可用引用与给人核对的摘要。引用是 DJ 生成的不透明、有类型、受主体与有效期约束的句柄，不是凭据。正常写操作不让模型重新拼接原生平台 ID：

| 返回字段 | 来源 | 使用位置 |
| --- | --- | --- |
| conversation_ref | conversation.list/resolve | selector.sources、message.send.destination_ref |
| session_ref | session.list/search/get/resolve、已核验 create/start 结果 | Agent session.send/get/message.list；不是 IM conversation_ref |
| session_key / initial_session_key | 目录或 lifecycle.get 的持久结果 | session.get 重取引用、scope.session_keys 定点刷新/搜索；不是授权 token |
| session_message_ref | session.message.list/search | session.message.get；不是 IM message_ref/event_id |
| instance_id / profile_id / lifecycle_id | instance/profile 列表、start/create 受理结果 | 指定运行实例、获准启动配置、动作核对；不与 agent_id 混用 |
| candidate_ref | agent.discover | agent.register/rebind |
| message_ref | native message.list/search | message.get，与实时 event_id 不互换 |
| agent_id | agent.register/get、agent.whoami | 订阅目标、状态检查 |
| preview_id | subscription.preview | subscription.create/update |
| reply_context_id | delivery.get 和输入信封 | message.reply |
| inbox_id / claim_ref | subscription.pull 返回的当前领取 | 按 inbox_id 识别重复业务，claim_ref 仅用于 subscription.ack；不当 delivery_id 或回复引用 |
| operation_id / outbound_id / delivery_id | 受理结果和查询 | 超时核对、状态读取；三种 ID 不互换 |

IM 原生 ID 只在安全详情中显示或由 conversation.resolve 接收精确三元组。DJ 不按标题模糊查找后自行选一个，不进行 AI 排序、自动改写目标或跨实例兜底。发现结果不完整时标 complete=false；多个候选允许调用方继续筛选，用户意图确实不清时由调用方询问。

Agent 原生 ID 可由 session.resolve 接收 instance_id+native_session_id，不能假借 IM resolve。session.list/search 的 complete 仅表分页，coverage_complete/as_of 才表覆盖和观测时间。调用者读取命中字段/片段来判断任务在哪里；DJ 不给语义归属分。查询、直发、启动/创建是分别授权的步骤，见 [Agent 控制面](agent-control-plane.md)。

搜索预算耗尽可返回空 items 和非空 next_cursor，仍未完成；search 只按稳定键顺序，不能要求服务猜尚未扫描结果的时间排名。session.probe 只读确认单个 receiver，不发测试消息。历史 lifecycle ready 与当前 instance/session 状态分别核对；新会话用于订阅要先有可信 recipient/工具接线，创建者 whoami 不因此改绑。

## 订阅预览与提交

subscription.preview 接收 spec（更新时还带 subscription_id/expected_revision），执行确定性规范化、来源/目标校验、预算/能力检查；返回 resolved_sources、resolved_target、normalized_spec、spec_hash、warnings、blocking_issues 和 sample_decisions。不存在待执行副作用，也不会联系模型解释规则。

没有 blocking_issues 才签发 preview_id，默认有效 10 分钟，绑定 principal、规范化 spec 摘要、目标 revision、来源引用、策略/能力快照，以及更新对象 revision。create 只接收 preview_id 与 idempotency_key；update 另带相同 subscription_id/expected_revision，禁止再次提交一份可能被模型修改的 spec。

commit 时重新检查权限、目标、引用和 revision。语义相关状态漂移返回 preview_stale，不能悄悄重新解释；健康探测时间更新但语义未变不使预览失效。有效期过后返回 preview_expired。允许调用方在原授权内连续 preview → create，不要求额外的人类确认弹窗。

预览中的 start=now 是将来提交时的起点，不能绑定预览时的 ingress_seq。预览不是权限批准，也不保证未来原生投递成功。同一 preview_id 不同幂等键的重复 create 返回 already_committed 及原 operation_id，不创建第二条订阅。

## 典型闭环

1. service.status 获取可见协议和业务能力；agent.whoami 获得当前已认证目标。未绑定则使用被允许的候选登记，不从自身猜 ID。
2. conversation.list 获取目标对话的 conversation_ref，核对摘要和完整性；不能列举时可用 resolve 校验明确原生 ID。
3. 模型将需求编为 spec，preview 后检查解析出的来源、目标和触发条件。自然语言还不明确时，模型先澄清规则含义。
4. 使用 preview_id 提交；保存 subscription_id、operation_id 和当前 revision。客户端退出不影响持久订阅。
5. 收到信封后执行目标任务，使用给定 reply_context_id 回原话题；DJ 只转发回复，不评价答案是否正确。
6. 受理请求超时时，operation.get 按 operation_id 或原 operation+幂等键查询；获取 outbound_id/delivery_id 后分别查询和核对，不能用新的幂等键重试原副作用。

## 推送、主动消费与提示词

默认 delivery_mode=push：DJ 按订阅向原会话投递。需要主动消费时在 preview 的 spec 中选择 pull，用 subscription.pull 领取一项，再用 subscription.ack 确认接收或释放重试；租约与空结果均按原键持久去重。确认接收不是任务完成，超时不换键重发。消息、指令及 reply_context 均受当前身份与领取代次约束。

instruction_policy 提供固定提示词和确定性任务模板；模板只展开明确字段，不让 DJ 推理任务、执行脚本或扩大权限。接口字段和上限见 [操作契约](interfaces/operations.md#订阅待办拉取)。CLI/MCP/API/GEPO 使用同一目录；可选本机回调及各客户端安装说明见 [DJ Skill](../skills/dj/SKILL.md)。配置生成与客户端实际加载分别核对，不自建无授权的后台轮询或模型进程。

## 结构化错误与恢复指引

错误除 code/message/retryable 外，返回 effect_state、field_errors 和 next_actions。effect_state 为 none（未受理副作用）、recorded（已持久受理，可能仍在后台执行）、external_accepted、unknown。它不表示业务成功；操作查询还应读取 data 中对象状态。

field_errors 元素为 {pointer,code,expected,received_type}，pointer 为 JSON Pointer，最多 10 项；不回显秘密值。next_actions 来自固定错误代码映射及已授权对象引用，格式为 {operation,arguments,requires_user_decision}，仅提供建议，不执行、不给新授权，也不使用大模型生成。

```json
{
  "ok": false,
  "request_id": "req_example",
  "warnings": [],
  "evidence_level": "service_record",
  "effect_state": "none",
  "error": {
    "code": "invalid_argument",
    "message": "来源必须使用对话引用",
    "retryable": false,
    "details": {},
    "field_errors": [{"pointer":"/spec/selector/sources/0/conversation_ref","code":"required","expected":"ConversationHandle","received_type":"missing"}],
    "next_actions": [{"operation":"conversation.list","arguments":{"connection_id":"con_example"},"requires_user_decision":false}]
  }
}
```

不得由模型对 message 字段做正则判断是否重试；先看 code、effect_state 及对象状态。可修正的 none 请求可以在新请求中更正；recorded/unknown 请求先核对，不能因参数或权限变化自动重新执行。引用失效不能降级为按标题发送。

## 自描述与精简输出

MCP 每个操作使用独立工具与严格 input/output schema；必填、枚举、联合类型的分支、字节/条数上限和副作用描述明确给出。CLI --help 和 JSON 输出使用同一参数目录。查询列表默认只给 ID、摘要、状态、限制和下一页，不批量输出正文/完整历史。详细事件正文通过 message.get 有界读取。

Skill 解释概念与典型流程，不能承担参数校验职责。外部事件正文即使包含 JSON、工具名、代码围栏或“系统指令”，序列化时始终进入 content.text 数据字段，不能拼入受信任协议头、工具调用或规则 AST。

## 边界测试

使用同名会话、张冠李戴的 ID 类型、过期引用、越权引用、preview 后改规则、重复键、跨入口重放、错误工具调用、正文伪造信封和上下文压缩后丢失 operation_id 等场景验证。模型可犯错的前提下，服务仍能确定性拒绝、定位或呈现 unknown；格式有效但选择错误且被授权的目的地，仍需调用方对用户意图负责。
