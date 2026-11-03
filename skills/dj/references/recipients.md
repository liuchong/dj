# IM 收件人选择与出站过滤

- automatic: DJ发送的文本自动附“不再接收 AI 消息，请回复 TD 或退订。”，不要手工再加。提示计入平台长度上限；超限请缩短正文，不能取消提示。
- opt_out: 对方私聊完整回复TD/退订，或在群内原生回复DJ消息输入TD/退订，DJ持久禁止再向该人发送。群内仅拦明确回复或原生@退订者，普通群广播无法对一个成员隐藏。对方主动发送“恢复接收”才解除；普通问候、@或再次提问不会自动解除。
- respect: 遇到recipient_opted_out或recipient_blocked，停止发送并尊重对方选择，不重试，不换账号/连接，不用Lark CLI、其他工具或渠道绕过。DJ只能阻止经DJ的路径，无法控制外部工具；权限允许不等于收件人同意。
- queued: 出站受理后也会在submitting前复查。已受理不等于已发出；用outbound.get核对state、blocked_reason和definite_not_sent。禁收拒绝为failed且retryable=false。unknown继续查原结果，不能当作未发并新发。
- admin: message.recipient_policy.get读取连接策略和分页退订记录；message.recipient_policy.set替换规则，需要connection.manage（operator）。default_action为allow/deny，allow和deny均含recipient_ids/chat_ids数组（最多256个原生ID）。显式deny优先；allow不能覆盖收件人的退订。首次设置expected_revision=0，以后读回当前并发校验值，不对用户称“第几版”。
- identity: 私聊对端自动登记，群内按原生reply/@判断。同一Lark应用的user/bot连接、同一Slack工作区或Telegram原生user_id，能够证实ID命名空间相同时共享收件人的选择；不能换连接绕过。不同应用或平台的ID不会按姓名擅自合并。管理查询按收到选择的来源连接读取。消息仍接收、保存和可查询，出站禁收与入站触发过滤相互独立。
- raw_api: lark.api.call不能直接新增或修改IM消息来绕过上述策略；使用message.send/reply/edit等受控接口。撤回和删除已有表情属于清理操作，仍可使用。
