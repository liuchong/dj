# 单目标唯一订阅与多条件分支

- single_line: 每个对话（由 `agent_id` 解析到唯一 `session:<session_key>`）或显式分发组（`group:<group_id>`）与 DJ 之间只有唯一一个订阅槽位。不再为同一目标创建多条平行 `subscription`；所有 IM 消息、置顶、表情回应、指定群多条件告警、云文档评论提及与多维表格变更，统一写入该目标唯一订阅的 `spec.rules[]`（`1..64` 条分支）。
- lifecycle: 首次建立时调用 `subscription.preview`（`expected_revision` 省略或传 `0`），核对 `normalized_spec`、`rule_sources` 与 `samples[].matched_rule_ids` 后调用 `subscription.set`（传 `preview_id`、`expected_revision: 0`、稳定 `idempotency_key`）。修改规则时先调用 `subscription.get`（传 `agent_id` 或 `group_id`）读取当前 `revision` 与完整 `rules`，增删或启停分支后以当前 `expected_revision` 调用 `subscription.preview` → `subscription.set`。暂停/恢复/删除统一传 `agent_id` 或 `group_id` 与 `expected_revision`。
- source: 每条 `rules[i].sources` 省略或 `[]` 为全部获准群、私聊及 thread；可用 `{connection_id}` 或 `{conversation_ref, include_threads}` 按分支独立收窄（例如分支 A 监听全部 IM，分支 B 绑定某个多维表格 `conversation_ref`）。条件中的 `conversation.native_chat_id` 是平台原始 ID，不是 `conversation_ref`；应从 DJ 的消息/来源接口读取，不凭标题猜测。
- algebra: `all` 表示全部满足，`any` 表示至少一项，`not` 表示取反。所有字段都可放在 `not` 下；排除只是排除本次触发，不是删除消息。省略整个 `spec.rules` 时，默认归一化为单条 `id="default"` 分支（选中原生 `@`、私聊、引用链回复、话题回应、对话 Pin 和已发消息的表情回应）。显式提供 `rules` 时完全按调用方分支执行；无条件接收显式使用 `all=[]`。
- precedence: 服务级 `message.filter` 的 `suppress_trigger` 优先于订阅；预览样例 `result` 表示本订阅条件，`reason_codes` 包含 `trigger_suppressed` 时仍不会触发。
- multi_branch_merge: 同一事件命中本订阅的多条 `enabled=true` 分支时，只投递一次通知：`matched` 为 `{target_key, subscription_revision, rule_ids}`；`context_policy` 在命中分支间取并集（任一为 `recent` 则采用 `recent` 及最大 `max_events`/`max_bytes`）；`instructions` 先排线级公共 `instruction_policy`（一份），再按分支声明顺序附加本次命中分支的专属 `instruction_policy`（带 `scope="rule"` 与 `rule_id`）。
- unknown: 缺失证据或截断内容保留 `indeterminate`，`not` 不会把未知变成命中。已知没有 thread/topic/引用的字段值为空字符串。

## 通知排查与原订阅恢复

1. 用来源连接的 `message.list` / `message.get` 核对事件入库时间及原生提及。再以 `delivery.list` 的 `filters.event_id` 查询该事件的投递。读取消息、订阅匹配和原生接收各有独立记录。
2. 用 `subscription.get` 查准确目标的 `state` 和规则。只有 `active` 订阅能匹配新事件；暂停、删除及全局触发抑制都可能让消息保留在历史中而无投递。有投递再用 `delivery.get` 查待投、失败或受理原因。
3. 活跃订阅遇到客户端重启或断线时，保留原登记和订阅，按 `agent.probe` / `session.probe` 重验接收端。Codex 的默认在线发现支持 follower IPC 和已授权的原生工具宿主；发现返回空页时查 `coverage`、`reason` 与 `next_cursor`。如已有原生会话 ID，可通过 `session.resolve` → `session.probe` 定点核验。
4. `agent.unregister` 是主动注销，会关闭登记、暂停原会话的在用订阅、取消尚未提交的订阅投递。需要恢复时，重新登记同一原生会话与原接收主体，从新 `agent_id` 读取原有暂停槽位并按当前 `expected_revision` 执行 `subscription.resume`。原规则分支与会话持久规则可继续使用。配置管理的固定接线通过原配置流程恢复。
5. 恢复从新入站事件生效。经授权补投暂停期间的某一条时，核对准确的 `event_id`、当前命中规则及是否已通过任何入口送到或处理，再按该 ID 调用 `subscription.replay`。查询随后产生的投递，避免切换入口重复交办。

共享客户端身份时，操作审计只能确认实际认证主体。排查注销来源时，仅凭共享主体不能归因到某个对话。

### 编辑后补加 @

新建默认订阅包含 `message.edited`，识别编辑新增的当前身份 @。显式规则若也要接收此类通知，在相应分支的 `event_kinds` 加入 `message.edited`，并更新谓词内限定 `event_kind=message.created` 的 @ 条件。私聊、引用和普通话题条件仍可只匹配初次发送。编辑信封的 `mentions` 是新增的原生提及，`event_id` 指向编辑记录，`native_message_id` 和回复位置仍为原消息。先读 `connection.probe.event_source.poll_fallback.edit_poll` 核对近期回读范围与授权，再查事件、触发黑名单及投递，区分历史空窗与规则不匹配。

## 字段与原生含义

| 条件 | field | op / value示例 |
| --- | --- | --- |
| 任意原生@ | mentions.any | eq / true |
| @当前接入身份 | addressed_self | eq / true |
| @当前应用机器人 | addressed_bot | eq / true |
| @指定人员 | mentions.id | in / ["native-person-id"] |
| 全部私聊 | chat_type | eq / "p2p" |
| 某人全部消息 | sender.id | eq / "native-sender-id" |
| 跨身份已核实人员 | sender.person_id | eq / "registered-person-id" |
| 消息原作者身份 | sender.kind | in / ["human", "bot"] |
| 实际动作发起者身份 | trigger.kind | in / ["human", "bot"] |
| 回应当前本人/机器人消息 | interaction.addressed_self | eq / true |
| 回应指定原作者 | interaction.target_id | in / ["native-person-id", "native-bot-id"] |
| 回应方式 | interaction.kind | in / ["reaction", "reply", "thread"] |
| 指定会话 | conversation.native_chat_id | eq / "native-chat-id" |
| 指定消息 | native_message_id | eq / "native-message-id" |
| 原生消息列/thread | thread.id | eq / "native-thread-id" |
| 已规范化话题 | topic.key | eq / "topic-key-from-dj" |
| 引用某条消息 | reply_to.id | eq / "native-parent-id" |
| 全文关键词 | text | contains / "故障" |
| 全文前/后缀 | text | prefix / "处理："；suffix / "请跟进" |
| 第一行文本（如首行告警） | text.first_line | contains / "炸了！"；prefix / "[P0]" |
| 任一行文本 | text.lines | contains / "ERROR"；eq / "紧急" |
| 接入账号 | connection_id | eq / "configured-connection" |

## 字段作用域与多段正文

- text_lines: `text`、`text.first_line`、`text.lines` 均支持区分大小写的字面 `eq`、`in`、`contains`、`prefix`、`suffix`（`contains`/`prefix`/`suffix` 模式值须非空）。`text.first_line` 仅匹配首个 `\r\n`/`\n`/`\r` 之前的第一行（若首字符即为换行则第一行为 `""`，第二行不会误判为第一行；后续行即使发生超长截断也不影响已换行的首行确定性判断）。Lark 多段富文本 `post` 在 WebSocket 与 HTTP 两侧统一按真实标题行与段落换行提取正文，不会变成单行 JSON。
- identity: `sender.id` 通常属于应用或平台作用域；在多个应用中代表同一人时，使用全局 `people` 登记已核实别名，再按 `sender.person_id` 匹配。机器人也按准确身份登记。没有映射时说明缺口，不从昵称自动合并。
- reactions: 表情事件 `sender` 仍是原消息作者，`reaction.operator.id/kind/is_self` 表示添加表情的人；按实际触发者选择条件，详见[表情触发](reactions.md)。

## 单条订阅承载多分支与任意多条件示例

每条分支的 `predicate` 最大深度 8、单分支叶数最多 64，整条订阅全部规则叶数合计最多 256。下面示例在同一个 `agent_id` 的唯一订阅内同时承载：(1) 默认 IM 消息/回应、(2) 指定群首行带“炸了！”等五重条件告警、(3) 多维表格变更分支：

```json
{
  "spec": {
    "agent_id": "agt_example",
    "instruction_policy": {
      "prompt": "按本对话持久路由规则分诊并处理外部事件。"
    },
    "rules": [
      {
        "id": "im-default",
        "enabled": true,
        "event_kinds": ["message.created", "message.pinned", "message.reaction.added"],
        "predicate": {
          "any": [
            {"field": "addressed_self", "op": "eq", "value": true},
            {"field": "event_kind", "op": "eq", "value": "message.pinned"},
            {"all": [{"field": "event_kind", "op": "eq", "value": "message.created"}, {"field": "chat_type", "op": "eq", "value": "p2p"}]},
            {"all": [{"field": "interaction.addressed_self", "op": "eq", "value": true}, {"field": "interaction.kind", "op": "in", "value": ["reply", "thread", "reaction"]}]}
          ]
        }
      },
      {
        "id": "fire-alert",
        "enabled": true,
        "event_kinds": ["message.created"],
        "predicate": {
          "all": [
            {"field": "conversation.native_chat_id", "op": "in", "value": ["oc_fire_group_example", "oc_oncall_group_example"]},
            {"any": [
              {"field": "text.first_line", "op": "contains", "value": "炸了！"},
              {"field": "text.first_line", "op": "prefix", "value": "[P0]"}
            ]},
            {"field": "sender.kind", "op": "eq", "value": "human"},
            {"not": {"field": "text", "op": "contains", "value": "演练"}},
            {"not": {"field": "thread.id", "op": "eq", "value": "omt_muted_thread_example"}}
          ]
        },
        "instruction_policy": {
          "prompt": "首行告警分支命中：优先核查线上故障影响面。"
        }
      },
      {
        "id": "bug-bitable",
        "enabled": true,
        "sources": [{"conversation_ref": "cvr_bitable_example", "include_threads": false}],
        "event_kinds": ["resource.changed"],
        "context_policy": {"mode": "current", "max_events": 1, "max_bytes": 16384},
        "predicate": {"field": "people.id", "op": "eq", "value": "ou_assignee_example"}
      }
    ]
  },
  "expected_revision": 1
}
```

- toggle_branch: 临时停用某条分支时，无需删除或拆分订阅，只需将该分支 `enabled` 设为 `false`，用当前 `expected_revision` 执行 `subscription.preview` → `subscription.set`。
- reply_identity: 无 `@` 的纯规则命中通知中，`trigger_reasons` 为 `subscription_rule`。若该群在当前 DJ 中只有一个可回复连接，通知直接附带 `reply_context_id`；若同一群同时接入了本人与机器人多条同租户连接且原消息未明确指向具体身份，DJ 按 0031 保持输入通知送达但 `reply_route` 为 `ambiguous_target`，调用方按本对话授权使用明确连接 `conversation.resolve` + `message.send` 或仅做内部处理。

## 只阻止指定机器人回复触发

普通订阅者在对应分支的 `predicate` 外用 `all` 附加以下排除项；管理员若要所有订阅都禁止指定机器人触发，用 `message.filter.update` 保存 `suppress_trigger` 规则（参见[全局触发过滤](filters.md)）：

```json
{"not":{"all":[
  {"field":"sender.kind","op":"eq","value":"bot"},
  {"field":"sender.id","op":"in","value":["verified-bot-a-id","verified-bot-b-id"]}
]}}
```

## 保存订阅者自己的模型

所有工具适用。订阅 preview 的 `spec.subscriber_model` 可提供 `provider_id`、完整 `model_id`（允许含斜杠），及可得的 `variant`、`reasoning_effort`。先核对本对话真实原生模型；不知道就省略，DJ 返回 unknown，禁止用工具品牌或全局默认值猜。原生会话观察优先，自报明确标记 `subscriber_report`，作为参考而非实时证明。

`subscription.set` 正式保存后，`subscription.get` 的 `subscriber` 是提交时快照；后续通知的 `recipient` 是该通知的准确接收对话与模型参考。工具 `tool` 与模型供应商 `provider_id` 是不同概念；凭据不会包含在此元数据中。

- group_target: `spec` 可以使用 `group_id` 替代 `agent_id`，在同一组唯一订阅中机械选一个成员；配置默认、选择算法、额度筛选、直订与组成员重合去重及 pull 成员参数见[组订阅](groups.md)。
