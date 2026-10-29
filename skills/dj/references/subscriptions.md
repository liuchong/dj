# 可组合消息订阅

- ownership: 由订阅者决定自己的规则。修改先subscription.get，再以原subscription_id/expected_revision调用subscription.preview，核对normalized_spec、样例和阻断项后subscription.update；保留原来源、目标、提示词及投递策略。不新建重复订阅替代修改。
- source: selector.sources省略或[]为全部获准群、私聊及thread。可用conversation_ref/include_threads收窄。条件中的conversation.native_chat_id是平台原始ID，不是conversation_ref；应从DJ的消息/来源接口读取，不凭标题猜测。
- algebra: all表示全部满足，any表示至少一项，not表示取反。所有字段都可放在not下；排除也只是排除本次触发，不是删除消息。默认predicate仍为addressed_self=true；无条件接收显式使用all=[]。
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
| 是否包含机器人 | sender.kind | in / ["human", "bot"] |
| 指定会话 | conversation.native_chat_id | eq / "native-chat-id" |
| 指定消息 | native_message_id | eq / "native-message-id" |
| 原生消息列/thread | thread.id | eq / "native-thread-id" |
| 已规范化话题 | topic.key | eq / "topic-key-from-dj" |
| 引用某条消息 | reply_to.id | eq / "native-parent-id" |
| 关键词 | text | contains / "故障" |
| 文本前缀 | text | prefix / "处理：" |
| 接入账号 | connection_id | eq / "configured-connection" |

- identity: sender.id通常属于应用或平台作用域；在多个应用中代表同一人时，使用全局people登记已核实别名，再按sender.person_id匹配。机器人也按准确身份登记。没有映射时说明缺口，不从昵称自动合并。
- reactions: 表情事件sender仍是原消息作者，reaction.operator.id/kind/is_self表示添加表情的人；按实际触发者选择条件，详见[表情触发](reactions.md)。

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
