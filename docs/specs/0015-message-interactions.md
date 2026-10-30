# 0015 — 对已发消息的回应触发

对本人或机器人已发消息添加表情、引用回复、在其原生话题下回复，都是可以订阅的回应。它们类似公开会话中的定向交流；不需要再次 @，也不要求上一项任务仍在运行。DJ只识别原生关系、按规则投递；是否属于原任务、是否执行或回复仍由接收AI决定。

## 一套接收和订阅路径

- 普通回复仍为 message.created，表情添加仍为 message.reaction.added，不增加虚拟连接、临时任务订阅或第二套分发。
- interaction 提供 kind（reaction/reply/thread）、state（resolved/unavailable）、target_message_id，以及已确认时的 target_id、target_kind、addressed_self。target_id 是被回应消息的原作者，不是新消息发送者。addressed_self 表示准确目标作者是当前来源连接的本人或机器人身份；话题连续回应另以 basis=thread_participation 标明依据。
- 引用按原生 parent_id；直接回应当前身份优先，否则可由原生 thread 的 root_id 确认当前身份的话题，最多按ID读取两个准确目标，缺少自有根/父时再查本地原生话题参与证据，不根据文本相似或在群里说过话推断归属。普通群消息没有这种关系就不命中。若话题根属于第三方，但当前连接身份已在同一原生chat/thread中发过消息，后续话题回复也按公开的定向交流触发，不要求再次@，不取决于任务是否结束。依据只能是当前身份未过期的本地已发消息、同页更早的原生消息，或官方已确认发送的出站记录；未知/失败/待发送不算。只读当前连接和身份栅栏内的记录，排除当前消息、未来记录及其他chat/thread，不以群内参与、相似文本或第三方@推断。保留平台真实root/parent，interaction.target_message_id指向作为依据的本人/机器人消息。
- 表情的 sender 保留原作者，reaction.operator 是动作添加者，interaction 指向原消息作者。原文 mentions 继续仅作上下文，不伪造新提及。
- 先读当前连接身份、同一chat且未过期的本地事件/上下文缓存；缺失时在写事务外按准确消息ID读取官方消息API。不可读、已删、身份不符或chat不符时标记 unavailable，不猜作者、不扩大来源，也不丢弃当前消息。
- user/bot、WebSocket/HTTP 共用同一关系解析。长连接证据与轮询来源仍分别记录，持久化、动作键、去重、黑名单和原会话投递继续复用。

## 触发选项与分发分离

私聊、原生@、引用链回复、原生话题回应、已发消息的表情回应是独立可组合选项。新订阅未提供predicate时默认全部选中，规范化为可读写的any分支；selector.event_kinds默认包含message.created和message.reaction.added。显式predicate或event_kinds完全以调用方选择为准，不强行追加默认分支，已有持久订阅不自动改写。

选择私聊用chat_type=p2p，选择@用addressed_self=true，选择引用链/话题/表情用interaction.addressed_self=true分别与interaction.kind=reply/thread/reaction组合。去掉相应分支即关闭该触发；all/any/not继续承载条件交并与排除。平台关系识别独立于是否订阅：关闭触发也保留消息及上下文。

这些选项只决定是否沿既有订阅通知既有AI会话，不建立话题与AI会话绑定，不创建子对话，也不推断任务归属。未来thread绑定属于独立分发能力，本次不实现。

## 配置与防循环

订阅者保留原 @、私聊、Pin 等分支，在 selector 中包含两种消息事件，用 any 追加 interaction.addressed_self=true；跨出口的准确作者也可用 interaction.target_id in [...]。可再与 kind、发送者、关键词及 not 条件组合。未显式订阅回应时不自动扩大原规则；不由DJ替接收者重写业务职责。

trigger.kind 表示实际发起动作的身份种类：表情取 reaction.operator.kind，其余取 sender.kind。全局“机器人不触发”应使用 trigger.kind，而不是把机器人原消息的作者当成表情添加者。sender.id/person_id 仍可分别约束原作者及表情添加者，人员和字符黑名单继续优先，过滤不影响历史可见性。

DJ自身出站回声、自动 Typing/Get 继续由持久回声证据拦截。人类对机器人消息添加的正常表情可以触发，不因原作者是机器人被误挡；机器人主动添加的表情仍被 trigger.kind 规则屏蔽。撤销表情不触发，重新添加作为新动作沿用现有去重。

## 回复与展示

通知、消息查询及上下文都暴露 interaction 和原生 reaction/reply/thread。AI可以确认“谁对哪条消息作出何种回应”，不把表情原文当成新说话内容，也不必为每个回应新建任务。

当前新消息有原生 @ 时，回复身份优先沿原生提及映射；没有新 @（含表情）时，已确认的回应目标作者用同一 reply_routes 映射选择出口。未命中映射保留来源身份；冲突、过期和权限错误仍拒绝，不自动双发或改投目的地。回复始终固定到当前触发消息及原chat/thread，自动Working、Get和完成清理不改变。

## 验收范围

集成覆盖真实Core、SQLite、官方帧/HTTP协议替身与订阅组合：本人/机器人消息的人类表情、无@引用、原生话题、普通无关消息、读缓存与准确ID补取、去重、机器人发起者与人员黑名单、回复身份。保护性测试覆盖缺失关系、不同chat/身份、不可读目标、原生@优先和不伪造mentions。模拟协议验收不冒充真实平台新事件送达。

本批定向验收：6项集成通过（1901条断言），24项规则/表情保护测试通过（144条断言）；另有1项既有future用例仍为todo。覆盖新增回应、双身份回复及HTTP表情补收回归，未运行全套或性能验收。话题连续回应另覆盖第三方根、本人/机器人既有回复、发送确认、同页补收及身份/来源隔离。
