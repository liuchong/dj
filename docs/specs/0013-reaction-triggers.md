# 0013 — 可配置的消息表情触发

与原生提及、私聊并列支持“添加指定表情”触发。采用现有订阅 selector/predicate，不增加另一套路由、队列或身份体系。按平台原生 emoji_type 精确匹配，大小写敏感，可用 in 配置一个或多个。Lark 图钉表情为 Pin，不是中文名称、Unicode 图钉或群消息置顶接口。

## 当前规范与实现

- 官方 im.message.reaction.created_v1 → message.reaction.added。保留原 native_message_id、chat/thread、消息作者和正文；reaction 独立记录原生事件 ID、添加时间、emoji_type、operator.id/kind/is_self。source_key 使用原生事件 ID，重连重送不重复投递。删除表情不触发，也不撤销已受理输入；移除后重新添加是新动作。
- 原消息的 mentions 仅是上下文，不伪造新提及，addressed_self/addressed_bot=false。回复走当前来源连接身份及原消息位置，不套用原消息其他人的提及回复路由。
- 先读当前身份的本地消息缓存；缺失时只按事件给出的准确消息 ID 直接读取官方 HTTPS API，不搜索、不轮询、不改写原文。缺权限、消息已删或不可读时不凭空补正文，保留原生未确认重试和源错误。持久入 inbox 后才 ACK。
- selector.event_kinds 显式加入 message.reaction.added；predicate 支持 reaction.emoji_type、reaction.operator.id/kind/is_self。没有 reaction 的普通消息对应空字符串/false。默认订阅仍只有原生 @，不会自动扩大全部用户的触发范围。
- 原消息作者与表情添加者均经过同一服务级人员黑名单；字符黑名单使用原正文。消息仍记录、可读，只限制触发。提交时继续重检授权、身份、订阅和过滤规则。
- 人工对 DJ 已发消息加表情可触发，不误判为原消息回声。DJ 自动 Typing/Get 按 work_marks 的身份、请求时间及原生 action_time 判别回声；结果未明确先 hold，防止自触发循环，不按表情名称一律屏蔽人工动作。
- 保留现有多订阅 contribution 合并与独立授权重检。AI 接收原正文、原作者、表情及添加者，仍由 AI 决定是否执行、回复或无需回复。

## 平台边界

应用需订阅 im.message.reaction.created_v1（后台名称“消息被reaction”），具备 im:message.reactions:read 或 im:message:readonly 之一。读取原正文还受消息读取权限约束。机器人只能收到其所在会话中的表情事件。用户 HTTP 可读/可加表情不证明应用 WebSocket 已收件；connection.probe.last_reaction_at 仅记录真实接收，不由配置推定。

依据：[官方新增表情事件](https://open.larksuite.com/document/server-docs/im-v1/message-reaction/event/created)、[官方表情标识](https://open.feishu.cn/document/uAjLw4CM/ukTMukTMukTM/reference/im-v1/message-reaction/emojis-introduce)。

## 本批施工与验收

基线 88bf7d2。lark-events 帧分派调用 lark-reactions.resolveLarkReaction/normalizeLarkReaction，复用缓存和 history；ingestion 保存 reaction；operations/rules/results 同步事件和字段；filtering、echo、working、reply route 保持统一语义；envelope/message/context 保留元数据。SQLite schema 不变，扩展现行 payload，不加兼容入口。

- [x] 一次完成业务、公开 schema、Skill 和说明。
- [x] 集成：原生帧→持久 inbox→规则→准确 Agent 输入；单/多表情、作者与添加者黑名单、thread、去重及自动表情回声。
- [x] 关键保护性测试：原生标识、身份/事件校验、非表情规则及回复路由边界。
- [x] 本机常驻服务已更新为 ready，经公开 preview/update 接口配置 Pin，并读回确认原提及/私聊规则、提示词、目标及投递策略保留；没有加群或改变用户凭据。
- [ ] 用户指定但接收应用未在其中的群，平台新增事件与原对话实时读回尚未验证；遵守不加群要求，不用旧记录、重放或轮询冒充通过。

当前定向检查：6 项通过、138 条断言；WebSocket 帧接收器和 HTTP 响应为明确测试替身，验证持久 inbox 和真实 Core 投递，不冒充平台实时验收。真实平台覆盖需另有新增事件及准确接收对话读回证据。

同一应用可以使用用户与应用 token 调用各自支持的 HTTP API。官方允许同一应用多个 WebSocket，但消息是集群随机分发，不能把两个客户端命名 user/bot 就当成独立用户收件流。多个逻辑身份应共用该应用的事件接入后分发；换 OAuth 身份不扩大 IM 事件的会话覆盖。同应用身份切换还需对应应用签发的用户授权，不能复用另一个应用的 token 或 OpenID。
