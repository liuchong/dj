# 0016 — 已发消息与表情操作

DJ 统一提供已发消息撤回、文本编辑和表情增删查。DJ内部接口直接走当前Lark连接的官方HTTPS API，user/bot共用实现，不换身份、不调用外部CLI，也不把订阅过滤当作消息操作权限。AI调用方在DJ功能不足时可使用Lark CLI补充，但必须保持原计划使用的同一账号、租户和user/bot身份；这不改变DJ内部实现。现有操作优先走DJ，未知写入结果不能换工具重发；能力清单与使用方法同步维护于DJ Skill。

## 操作与目标

| 操作 | 用途 |
| --- | --- |
| message.recall | 撤回已发消息，不是取消尚未发送的 outbound |
| message.edit | 将一条原生文本消息替换为新的文本 |
| message.reaction.add | 给准确消息添加原生 emoji_type |
| message.reaction.list | 分页读取表情及添加者 |
| message.reaction.remove | 按准确 reaction_id 撤销当前身份可撤销的表情 |
| message.action.get | 读取已提交动作的持久结果 |

目标在 outbound_id、event_id、message_ref、context_ref、conversation_ref 中严格五选一。outbound_id 必须是已确认 accepted 且仅对应一条原生消息的出站记录；拆分消息须用 conversation_ref/context_ref 和单个 native_message_id 明确选择，不能一次隐式撤回多条。event_id/message_ref 使用其固有消息 ID，不能覆盖。context_ref/conversation_ref 必须另带 native_message_id，并从原生消息读回验证 chat/thread 完全一致。

编辑只支持文本消息，content 为 `{ "type": "text", "text": "完整新正文" }`。不把文本编辑泛化成卡片、文件或任意富文本写入。表情使用原生标识，不把显示名称或 Unicode 图案猜成原生 emoji_type。

## 持久性与不确定结果

四个写操作必须带 idempotency_key。先提交 operation 和 message_action 引用，再执行原生变更；同键重放只读原结果，不重复请求。服务重启、超时、身份变化或结果落盘失败不会自动再次执行原生变更。发送记录、事件和历史回执保持审计快照，撤回不销毁历史记录；已变更消息的原生上下文缓存失效，下次显式原生读取取得现态。

返回的外层 ok 表示动作回执可读，须再检查 data.state：accepted 表示官方写接口确认接纳，rejected 表示收到明确原生拒绝，unknown 表示结果不确定。confirmed 仅表示后续准确消息读回确认撤回或编辑结果；表情写入的 accepted 回执可通过 reaction.list 主动读回核对。unknown 不换键重试，先查 message.action.get 或 operation.get，再核实原生现态。

接收对话默认可操作当前已配置且原生可访问的消息。平台仍限制作者身份、可撤回/可编辑时间、编辑次数及原生权限。DJ 不绕过这些限制，也不把任何失败都归因为缺权限；返回安全错误码和原生数字错误码，不回传原始异常或凭据。参考权限为 im:message:recall、im:message:update、im:message.reactions:read、im:message.reactions:write_only，以官方实际拒绝为准。

自动 Working/Get 由原持久清理流程管理，手动表情接口不替代任务完成接口，不改变订阅规则或回复身份。撤回不撤销已经触发或处理的 AI 任务。

## 平台协议

- 撤回：DELETE /open-apis/im/v1/messages/{message_id}。
- 编辑：PUT 同一路径，msg_type=text，content 为官方要求的 JSON 文本字段；不是卡片的 PATCH 接口。
- 表情：POST/GET /open-apis/im/v1/messages/{message_id}/reactions；DELETE 其下的 {reaction_id}。
- GET 每页至多 50，按 page_token 续页，复用现有应用级表情读取预算。

官方接口说明：[撤回](https://open.larksuite.com/document/server-docs/im-v1/message/delete)、[编辑](https://open.larksuite.com/document/server-docs/im-v1/message/update)、[表情](https://open.larksuite.com/document/server-docs/im-v1/message-reaction/create)。
