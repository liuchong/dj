# 可配置表情触发

- source: 复用获准来源和准确 Agent 目标；事件为 message.reaction.added。Lark 图钉原生标识是区分大小写的 Pin，不是“图钉”、📌或置顶消息。emoji_type 是平台不透明字符串，不按显示图形猜；一个或多个使用 eq/in。
- identity: reaction.operator.id/kind/is_self 表示实际添加者；sender 仍是原消息作者。is_self 相对当前 user/bot 连接身份。可限定本人或显式添加者；不擅自扩大到所有人。
- configure: 先读回当前订阅，保留来源、目标、上下文、instructions、投递策略和其他业务规则；selector.event_kinds 加入 message.reaction.added，原规则限定在原事件分支，另用 any 增加表情分支，再 preview/update。已有订阅不可用新建重复替代。
- message: 接收原正文、来源 thread、原作者和 reaction 元数据。原文提及仅作上下文，不作为新的提及；回复身份和位置由 DJ 固定；可按interaction订阅对本人或机器人已发消息的回应，见[订阅分发](subscriptions.md)。按持久规则决定是否做事/回复；无需回复也走既有 complete/acknowledge 闭环。
- filters: 原作者、表情添加者均受统一人员黑名单控制，字符黑名单检查原文；被屏蔽仍可读。自动 Typing/Get 不得造成自触发循环。
- realtime: WebSocket需平台订阅im.message.reaction.created_v1，其会话覆盖按平台实际授权核对；未覆盖会话由DJ用同一连接的官方HTTPS表情列表补收。只检查已保留本地消息；新入库消息优先检查，最近10分钟最新64条高频轮巡，已观察到表情的旧消息加入有界优先检查，其余历史按整轮目标兜底。重复检查共享观察缓存；空闲探测不反复写数据库。200毫秒是检查新消息的空闲等待，2秒是近期轮巡扫完的等待，均非逐条送达保证。receive_transport=poll不算WebSocket实时证据；缺权限或异常需报告，不让AI另建定时器。
- limits: 普通消息与表情分开调度，表情GET在传输层按应用共享DJ默认10次/秒、并发2的预算，本人/机器人不各算一份。它是DJ选择，不是平台限额；以实际限流与等待时间为准。操作员可配置connection.reaction_poll，详见项目规格0013；订阅者不另建扫描器。
- activation: 新表情补收观察器启动前已存在的图钉不自动建任务；正常重启保留观察边界，移除后重新添加是新动作。HTTP保留native_reaction_id，不编造原生推送事件ID；与WebSocket对同一动作共用去重键。

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

- distinction: 普通回应针对本人/机器人自己发出的消息；本人给别人消息点普通表情不触发回应分支。本人添加Pin等指定表情是主动标记，点在任何作者/位置的消息上均生成message.reaction.added并按独立emoji_type/动作人分支投递；不是“不发事件”。本人在任意位置原生@自己或@自己的机器人同样生成带正文的主动触发。它们与别人点表情/引用/话题回复、别人@、别人私聊三类被动规则独立，不用普通回声过滤一概排除。


## 对话 Pin/置顶

- distinction: 消息菜单“Pin/置顶到对话”是 message.pinned；📌 小表情仍是 message.reaction.added + reaction.emoji_type=Pin。置顶整个聊天窗口和群顶部公告不属于本操作。
- subscribe: 读取原订阅，保留目标、sources、predicate、instructions 与投递策略，selector.event_kinds 加入 message.pinned，再在原 predicate 的 any 中追加 {"field":"event_kind","op":"eq","value":"message.pinned"}。可进一步用 pin.operator.is_self/id/kind 收窄。preview/update 后读回，不重复创建订阅。
- receive: 官方 Pin 列表按已知、授权群和私聊独立增量补收，默认15秒/群等待，共享读取预算且不承诺逐条时限；pin_poll_seconds 是操作员配置，不让 AI 另建巡检。连接 poll_fallback.pin_poll 表示覆盖及时间。首次启用前已有 Pin 不自动补发；正常重启接续原断点。
- metadata: pin.operator 是标记者，sender 是原作者；原文的 mentions 仅作上下文。trigger_reasons 的 chat_pin 表示对话 Pin，reaction_pin 表示 📌 表情，reaction 表示其他表情；mention、direct_message、thread_reply、quoted_reply 等使用各自原因。一条消息可有多个原因，matched 才表示实际命中哪些订阅。原因不能替代权限或要求 AI 必须新建任务。
- reply: Pin 通知沿固定 reply_context_id 原路回复，不因旧原文 @ 或标记者身份更换出口；普通输出不自动发回 IM。
