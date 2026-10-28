# 可配置表情触发

- source: 复用获准来源和准确 Agent 目标；事件为 message.reaction.added。Lark 图钉原生标识是区分大小写的 Pin，不是“图钉”、📌或置顶消息。emoji_type 是平台不透明字符串，不按显示图形猜；一个或多个使用 eq/in。
- identity: reaction.operator.id/kind/is_self 表示实际添加者；sender 仍是原消息作者。is_self 相对当前 user/bot 连接身份。可限定本人或显式添加者；不擅自扩大到所有人。
- configure: 先读回当前订阅，保留来源、目标、上下文、instructions、投递策略和其他业务规则；selector.event_kinds 加入 message.reaction.added，原规则限定在原事件分支，另用 any 增加表情分支，再 preview/update。已有订阅不可用新建重复替代。
- message: 接收原正文、来源 thread、原作者和 reaction 元数据。原文提及仅作上下文，不作为新的提及；回复身份和位置由 DJ 固定。按持久规则决定是否做事/回复；无需回复也走既有 complete/acknowledge 闭环。
- filters: 原作者、表情添加者均受统一人员黑名单控制，字符黑名单检查原文；被屏蔽仍可读。自动 Typing/Get 不得造成自触发循环。
- realtime: 需要平台订阅 im.message.reaction.created_v1。只能收到机器人所在会话中的事件；HTTP 读到原文和 Pin 记录不证明长连接已收到事件。缺权限或事件配置时报告具体缺口，不做历史轮询，不把重放说成实时。

## 三种触发组合示例

沿用现有 agent_id 和 sources，预览以下 selector/predicate；示例以本人添加 Pin 为表情触发条件，扩大 emoji_type/添加者需明确设置。

```json
{
  "selector": {"event_kinds": ["message.created", "message.reaction.added"]},
  "predicate": {"any": [
    {"all": [
      {"field": "event_kind", "op": "eq", "value": "message.created"},
      {"any": [
        {"field": "addressed_self", "op": "eq", "value": true},
        {"field": "chat_type", "op": "eq", "value": "p2p"}
      ]}
    ]},
    {"all": [
      {"field": "event_kind", "op": "eq", "value": "message.reaction.added"},
      {"field": "reaction.emoji_type", "op": "in", "value": ["Pin"]},
      {"field": "reaction.operator.is_self", "op": "eq", "value": true}
    ]}
  ]}
}
```

多表情如 ["Pin", "Fire"]；不自动替换已有订阅对私聊、@all、自发消息或自定义任务规则的决定。删除表情不撤回已投递输入，移除后重新添加是新动作，原生事件重送才去重。
