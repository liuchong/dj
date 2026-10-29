# 0006 — 处理中的表情与可靠撤销

DJ将Lark `Typing`（敲键盘）作为已交给接收会话处理的标记，不代表任务已完成或必须回复。只有IM来源投递获得原生accepted、有固定回复上下文、出口支持reaction时登记标记；direct输入不加，接收方仍自行决定是否处理及何时回复。

## 状态与接口

- 每条delivery持久保存独立处理租约，同一出口身份、版本和原消息共享一个原生reaction，多个接收方均结束才撤销。
- `delivery.working(delivery_id)`查询处理状态及cleanup_state；`delivery.complete(delivery_id,reason,idempotency_key)`显式报告completed/no_reply/failed/cancelled，仅原接收主体或获准operator可操作。无需IM文字回复时，显式Get确认在同一事务自动收尾；未走自动收尾的通知仍须调用complete，不能用普通文本或最终回答代替。
- 原消息回复通过DJ获得原生accepted时自动结束对应处理租约。已绑定的原生ended/settled/turn_finished等结束观察亦可结束；不会将这些观察作为自动IM回复指令。
- 30分钟处理租约到期触发回收，避免客户端退出、异常、模型未调用complete等情况永久遗留。服务停止持久登记撤销意图，重启继续清理，不依赖对话上下文。长时间业务可继续推进，但过期后不再显示working。

## 外部副作用与清理保证

首次创建前持久登记意图并查询当前身份的原生Typing；已存在的人工表情不归DJ接管或删除。POST之前持久登记attempted_create；POST结果丢失后按相同身份和原消息查询找回，不盲目重复添加。分页有界，游标持久保存并续扫。

需要撤销时先持久保存removing，再按精确reaction_id执行官方DELETE；下次查询确认该ID不存在才记done。DELETE失败、网络中断、进程崩溃均保留清理记录并重试，记录不因租约、回复引用或AI上下文过期而消失。身份版本变化时不借新身份删除其他人的表情，保留具体待处理故障。外部API、凭据持续不可用时不能承诺即时删除，必须如实显示cleanup pending，恢复后继续直到确认撤销。

只调用官方HTTPS的message-reaction create/list/delete；不使用SDK、外部IM CLI或桌面。Typed路径与原消息引用不能被AI覆写，权限和原生身份沿0005固定路径核对。没有必要IM内容回复时仅撤销，不强行发“已处理”。

## 有界历史恢复

`subscription.replay(subscription_id,event_ids,expected_revision,idempotency_key)`仅显式恢复最多16条已入库且匹配已完成的原事件。使用当前active版本的准确来源、谓词、内容权限、目标授权、黑名单、回声栅栏、TTL及容量，并复用原event和原生message ID；不改历史消息、start水位、已完成路由checkpoint或原始决策。唯一约束阻止同event/route重复输入。默认订阅更新仍只从now生效，不静默回补历史。它用于修复明确遗漏，不替代长连接实时收件。

## 显式漏收补处理

普通历史查询不启动Typing或任务。用户明确要求补处理漏收消息时，操作员可用message.recover给出同一连接下1..16个准确原生message_id、原因及固定幂等键，由DJ核验官方消息、当前身份和授权，再按原消息键去重进入原订阅/黑名单/投递路径。这里只登记explicit_native_recovery证据，不冒充WebSocket实时事件，不移动收件游标，不自动扩大订阅或重建已有任务。

恢复消息按当前原订阅通知原对话；原case和owner继续复用。正式投递accepted后复用同一Typing租约，回复、delivery.complete、失败/无需回复或租约到期均走既有撤销机制。此接口仅操作员可调用，不是每次主动查询的隐式动作。

## 收到确认与无需文字回复

Get表示内容已理解或已收录、暂时无需文字回复，不是普通收件回执，也不是Working之后的必经步骤。AI按原接收对话的持久规则明确选择message.acknowledge(reply_context_id,idempotency_key)，不因普通输出自动发送，不对所有关键词或私聊事件一律确认。DJ沿0005固定的原消息与user/bot身份执行，AI不选择chat、message_id或身份。此操作复用message.reply授权与受控回复引用，不适用于资源事件。

| AI对当前消息的决定 | 表情行为 |
| --- | --- |
| 正在处理本条要求或问题 | 只保留Working，不额外点Get |
| 已理解、知道了，暂时无需文字回复 | Get，并结束本条消息的Working |
| 补充已收录进正在处理的任务 | 补充消息Get；原任务的Working继续保留 |
| 完成并回复 | 撤销Working，不必再补Get |

确认意图与当前delivery处理租约在同一事务持久提交，结束原因为no_reply，不依赖AI再调一次delivery.complete。若确认发生于submitting、原生接收回执尚未落盘时，先登记并结束本条处理租约，后到的accepted不能重新点起Working。只结束回复引用所绑定的delivery，不按群、thread、会话或AI猜测的任务批量结束；补充消息不会结束原任务，其他接收方的处理租约仍独立存在。这里的结束仅表示本条输入已处理，不代表整个业务任务完成，也不禁止后续明确回复。

Get是持久内容确认，Typing是临时处理中。原生Get创建与Typing撤销仍异步执行，故可短暂共存；同一原消息存在其他接收方未完成的租约时，Working依原有共享规则保留。两者共用现有持久表情队列，按emoji区分；Get在官方GET核对存在后才native_acknowledged=true，可通过message.acknowledge.get查询。已存在的本人同类Get直接确认，不删除人工表情；网络未知或丢失POST响应时只重查，不盲目重发POST。执行前复核当前主体授权、账号栅栏、源读取有效期；失效则终止待发送确认并保留明确状态，不借新账号发送。Get发送失败不将已确认处理完的当前输入重新标记为处理中，保留真实确认/清理错误并重试。

## 当前策略验收

定向集成6项通过：真实SQLite/Core与明确替换的原生表情端口验证确认意图和Working结束原子提交、失败回滚、补充不结束原任务、多接收方共享标记、submitting期确认不被后到accepted复活、丢失原生响应及重启后清理。36项保护检查、331条断言通过。此证据不冒充真实平台的表情删除时延；原生Get和清理仍分别以官方读回及cleanup_state确认。
