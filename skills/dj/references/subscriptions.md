# 可组合消息订阅

- ownership: 由订阅者决定自己的规则。修改先subscription.get，再以原subscription_id/expected_revision调用subscription.preview，核对normalized_spec、样例和阻断项后subscription.update；保留原来源、目标、提示词及投递策略。不新建重复订阅替代修改。
- source: selector.sources省略或[]为全部获准群、私聊及thread。可用conversation_ref/include_threads收窄。条件中的conversation.native_chat_id是平台原始ID，不是conversation_ref；应从DJ的消息/来源接口读取，不凭标题猜测。
- algebra: all表示全部满足，any表示至少一项，not表示取反。所有字段都可放在not下；排除也只是排除本次触发，不是删除消息。省略predicate时，默认以any选中原生@、私聊、引用链回复、话题回应和已发消息的表情回应；规范化后的每个分支可独立保留或删除。显式predicate完全按调用方选择，不追加默认分支；无条件接收显式使用all=[]。
- precedence: 服务级message.filter的suppress_trigger优先于订阅；预览样例result表示本订阅条件，reason_codes包含trigger_suppressed时仍不会触发。先处理全局策略限制，不通过新订阅绕过。
- overlap: 不同订阅独立匹配同一事件。不同目标分别交付；同目标可能合并投递，matched/instructions保留所有有效贡献。事件重送去重不等于只允许一条订阅匹配。
- unknown: 缺失证据或截断内容保留indeterminate，not不会把未知变成命中。已知没有thread/topic/引用的字段值为空字符串。

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
- identity: sender.id通常属于应用或平台作用域；在多个应用中代表同一人时，使用全局people登记已核实别名，再按sender.person_id匹配。机器人也按准确身份登记。没有映射时说明缺口，不从昵称自动合并。
- reactions: 表情事件sender仍是原消息作者，reaction.operator.id/kind/is_self表示添加表情的人；按实际触发者选择条件，详见[表情触发](reactions.md)。

## 任意多条件组合订阅（不限于两条）

`all` 数组支持 0..64 个子条件同时交集（整棵 `all`/`any`/`not` 树最大深度 8、总叶数 64），既可写 2 条条件，也可按业务需要组合 3 条、5 条或更多条件，或挂入顶层 `any` 与原有 `@`/私聊/话题回应并存。

### 示例1：指定群且第一行带“炸了！”（两条核心条件 + 事件类型）

```json
{"all":[
  {"field":"event_kind","op":"eq","value":"message.created"},
  {"field":"conversation.native_chat_id","op":"eq","value":"oc_fire_group_example"},
  {"field":"text.first_line","op":"contains","value":"炸了！"}
]}
```

### 示例2：五条及以上条件同时判断（群 + 首行词组 + 真人发送 + 非演练 + 非特定话题）

```json
{"all":[
  {"field":"event_kind","op":"eq","value":"message.created"},
  {"field":"conversation.native_chat_id","op":"in","value":["oc_fire_group_example","oc_oncall_group_example"]},
  {"any":[
    {"field":"text.first_line","op":"contains","value":"炸了！"},
    {"field":"text.first_line","op":"prefix","value":"[P0]"}
  ]},
  {"field":"sender.kind","op":"eq","value":"human"},
  {"not":{"field":"text","op":"contains","value":"演练"}},
  {"not":{"field":"thread.id","op":"eq","value":"omt_muted_thread_example"}}
]}
```

- keep_defaults: 若要在已有订阅上新增此类多条件规则而不丢掉原有的 `@`/私聊/引用/话题/Pin 触发，先 `subscription.get` 取出当前 `spec.predicate`（顶层通常为 `{"any":[...]}`），把上述 `{"all":[...]}` 作为一个新元素追加进顶层 `any`，再用原 `subscription_id` 和 `expected_revision` 走 `subscription.preview` → `subscription.update`。
- reply_identity: 无 `@` 的纯规则命中通知中，`trigger_reasons` 为 `subscription_rule`。若该群在当前 DJ 中只有一个可回复连接，通知直接附带 `reply_context_id`；若同一群同时接入了本人与机器人多条同租户连接且原消息未明确指向具体身份，DJ 按 0031 保持输入通知送达但 `reply_route` 为 `ambiguous_target`（不替调用方猜用本人还是机器人回复），调用方按本对话授权使用明确连接 `conversation.resolve` + `message.send` 或仅做内部处理。

## @或私聊，同时排除机器人和关键词

把以下predicate放进完整spec，selector.event_kinds=["message.created"]；来源为空表示全部获准对话。

```json
{"all":[
  {"any":[
    {"field":"mentions.any","op":"eq","value":true},
    {"field":"chat_type","op":"eq","value":"p2p"}
  ]},
  {"not":{"field":"sender.kind","op":"in","value":["bot","agent"]}},
  {"not":{"field":"text","op":"contains","value":"仅供记录"}}
]}
```

## 某人的私聊，或某个话题；排除指定对话

```json
{"all":[
  {"any":[
    {"all":[
      {"field":"chat_type","op":"eq","value":"p2p"},
      {"field":"sender.id","op":"eq","value":"native-person-id"}
    ]},
    {"field":"topic.key","op":"eq","value":"topic-key-from-dj"}
  ]},
  {"not":{"field":"conversation.native_chat_id","op":"eq","value":"excluded-chat-id"}}
]}
```

## 只阻止指定机器人回复触发

普通订阅者在自己的predicate外用all附加以下排除项。其他机器人的消息仍按本订阅的其余条件判断；如果要求排除所有机器人则按sender.kind过滤。

```json
{"not":{"all":[
  {"field":"sender.kind","op":"eq","value":"bot"},
  {"field":"sender.id","op":"in","value":["verified-bot-a-id","verified-bot-b-id"]}
]}}
```

- global: 管理员若要所有订阅都禁止这两名机器人触发，用message.filter.update将上面all内部的条件保存成enabled=true、effect=suppress_trigger的规则；先get并保留已有rules/people。跨应用使用sender.person_id及已核实身份表，参见[全局触发过滤](filters.md)。
- visibility: 机器人回执仍进入本地历史和上下文，AI可在另一条消息触发后读取；DJ自己的出站回声继续走防回声与幂等机制，不与普通机器人来源混同。

## 默认全选与独立选择

- defaults: 新订阅省略predicate时默认选择@、私聊、引用链、原生话题、表情回应及对话Pin；event_kinds省略时为message.created/message.pinned/message.reaction.added。原有已保存规则不自动改变。
- choose: 私聊用chat_type=p2p；@用addressed_self=true；引用链、话题、表情分别用interaction.addressed_self=true与interaction.kind=reply/thread/reaction取all，再用any合并所选项。关闭某项就从any删除该分支；其他选项不受影响。需要额外关键词、人员或排除条件时继续用all/any/not组合。
- dispatch: 选项只决定是否通知既有订阅目标，关系元数据仍供查询；不自动建立thread与AI对话绑定。

## 对本人或机器人消息的表情、引用与话题回应

- append: 保留已有predicate并用any追加interaction.addressed_self=true；selector.event_kinds包含message.created和message.reaction.added。跨出口用当前来源作用域核实的interaction.target_id；普通回应是原作者ID，thread_mention则是被提及身份，都不是新回应者。需只收人类回应时与trigger.kind=human取all。
- evidence: interaction.state=resolved才有已确认作者；unavailable表示准确目标不可读/不在本地且补取失败，不猜。thread可由本人/机器人根消息，或同一原生chat/thread内当前身份的既有已发消息确认；后者标记basis=thread_participation，后续回复不必再@。第三方话题的根消息或同一原生chat/thread内更早消息原生@当前身份时，后续回复也持续触发，basis=thread_mention、target_id为被提及身份；不要求先文字回复或任务仍运行。创建话题后的官方native_thread_id可作为已确认出站位置。普通群聊参与、其他话题、正文里的文字@、待发送或未知出站不算依据。
- routing: 无新@时由DJ按回应目标身份沿既有reply_routes固定身份，有新@则原生提及优先。AI不选择出口或收件人。
- robots: 若规则目的是屏蔽机器人动作，使用trigger.kind；sender.kind仍为原消息作者，单独按它排除会连人类对机器人消息的表情一起过滤。人员与字符黑名单仍优先，消息可见性不变。

- chat_pins: 消息菜单 Pin 是独立的 message.pinned，pin.operator 表示实际标记者；与 📌 表情分开选择，见[置顶与原因](reactions.md#对话-pin置顶)。通知 trigger_reasons 展示动作原因，matched 展示命中的订阅；多个原因不要求重复创建任务。

## 保存订阅者自己的模型

所有工具适用。订阅 preview 的 `spec.subscriber_model` 可提供 `provider_id`、完整 `model_id`（允许含斜杠），及可得的 `variant`、`reasoning_effort`。先核对本对话真实原生模型；不知道就省略，DJ 返回 unknown，禁止用工具品牌或全局默认值猜。原生会话观察优先，自报明确标记 subscriber_report，作为参考而非实时证明。

create/update 正式保存后，subscription.get 的 subscriber 是提交时快照；后续通知的 recipient 是该通知的准确接收对话与模型参考。分派或创建对话时可以参考这些字段，不能因此自动更换固定搭档模型。stale、unknown 和 source 必须保留，不把旧报告说成当前已核实的模型。工具 tool 与模型供应商 provider_id 是不同概念。凭据不会包含在此元数据中。

- group_target: spec可以使用group_id替代agent_id，在同一组订阅中机械选一个成员；配置默认、请求选择算法、额度未知策略及pull成员参数见[组订阅](groups.md)。
