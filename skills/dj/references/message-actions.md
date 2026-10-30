# 已发消息操作

- entry: 先读具体操作的CLI --help、MCP tools/list或GEPO操作说明。CLI、MCP、GEPO共用同一套DJ操作；DJ已有撤回、编辑与表情能力，优先使用。其他功能确实不足时可用[同身份Lark CLI补充](lark.md#功能不足时使用-lark-cli)，未知结果不换工具重发。
- target: outbound_id/event_id/message_ref/context_ref/conversation_ref 五选一。context_ref/conversation_ref 另带准确 native_message_id；event_id/message_ref 不覆盖 ID。outbound_id 仅适用于 accepted 且只有一个 native_message_id 的出站记录。
- recall: message.recall 撤回已经发出的原生消息；取消尚未发送的记录仍用 outbound.cancel。撤回不会删除本地审计历史，也不会取消已触发的任务。
- edit: message.edit 的 content 使用 type=text 和完整新 text，只编辑文本。不能靠改写本地 outbound 或原事件来冒充原生编辑。
- reactions: message.reaction.list 返回 reaction_id、emoji_type、添加者和分页信息；message.reaction.add 指定原生 emoji_type；message.reaction.remove 指定准确 reaction_id，不猜显示名称。自动 Working/Get 仍由 working 完成/无需回复流程管理。
- durable: 写操作都带固定 idempotency_key。外层 ok 是回执成功，必须检查 data.state。accepted=官方接纳，rejected=明确拒绝，unknown=结果不确定；confirmed 只表示后续消息读回核实了撤回或编辑。表情可用 list 再核对。
- uncertainty: 用 message.action.get(action_id) 或 operation.get 查原结果。unknown 不换键重发；先核对准确原生消息或表情现态。平台拒绝时按实际 native_code 判断作者、期限、次数或权限问题，不笼统声称 DJ 不支持。
- identity: 动作沿目标原连接身份，不把本人操作换成机器人。原生权限和期限由平台执行，不修改订阅、规则或 grants 来绕过。
