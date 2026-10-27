# 0006 — 处理中的表情与可靠撤销

DJ将Lark `Typing`（敲键盘）作为已交给接收会话处理的标记，不代表任务已完成或必须回复。只有IM来源投递获得原生accepted、有固定回复上下文、出口支持reaction时登记标记；direct输入不加，接收方仍自行决定是否处理及何时回复。

## 状态与接口

- 每条delivery持久保存独立处理租约，同一出口身份、版本和原消息共享一个原生reaction，多个接收方均结束才撤销。
- `delivery.working(delivery_id)`查询处理状态及cleanup_state；`delivery.complete(delivery_id,reason,idempotency_key)`显式报告completed/no_reply/failed/cancelled，仅原接收主体或获准operator可操作。无需IM回复时也必须调用complete，不能用普通文本或最终回答代替。
- 原消息回复通过DJ获得原生accepted时自动结束对应处理租约。已绑定的原生ended/settled/turn_finished等结束观察亦可结束；不会将这些观察作为自动IM回复指令。
- 30分钟处理租约到期触发回收，避免客户端退出、异常、模型未调用complete等情况永久遗留。服务停止持久登记撤销意图，重启继续清理，不依赖对话上下文。长时间业务可继续推进，但过期后不再显示working。

## 外部副作用与清理保证

首次创建前持久登记意图并查询当前身份的原生Typing；已存在的人工表情不归DJ接管或删除。POST之前持久登记attempted_create；POST结果丢失后按相同身份和原消息查询找回，不盲目重复添加。分页有界，游标持久保存并续扫。

需要撤销时先持久保存removing，再按精确reaction_id执行官方DELETE；下次查询确认该ID不存在才记done。DELETE失败、网络中断、进程崩溃均保留清理记录并重试，记录不因租约、回复引用或AI上下文过期而消失。身份版本变化时不借新身份删除其他人的表情，保留具体待处理故障。外部API、凭据持续不可用时不能承诺即时删除，必须如实显示cleanup pending，恢复后继续直到确认撤销。

只调用官方HTTPS的message-reaction create/list/delete；不使用SDK、外部IM CLI或桌面。Typed路径与原消息引用不能被AI覆写，权限和原生身份沿0005固定路径核对。没有必要IM内容回复时仅撤销，不强行发“已处理”。

## 有界历史恢复

`subscription.replay(subscription_id,event_ids,expected_revision,idempotency_key)`仅显式恢复最多16条已入库且匹配已完成的原事件。使用当前active版本的准确来源、谓词、内容权限、目标授权、黑名单、回声栅栏、TTL及容量，并复用原event和原生message ID；不改历史消息、start水位、已完成路由checkpoint或原始决策。唯一约束阻止同event/route重复输入。默认订阅更新仍只从now生效，不静默回补历史。它用于修复明确遗漏，不替代长连接实时收件。
