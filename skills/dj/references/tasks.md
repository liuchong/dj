# 任务巡查

- purpose: 查询 IM 原消息到原 AI 会话及登记子对话的关联，不触发 AI 或推断任务成功。
- access: task.list/task.tree 需要 task.inspect；私有 task_inspection 配置中的管理员白名单可查全部，普通用户只查其已绑定且 identity_revision 匹配的连接。operator 不是自动的全局巡查管理员。
- list: task.list 的 after 为上一页 next_after，limit 默认 10、最多 50；next_after=null 表示本次分页结束。
- tree: task.tree 使用准确 delivery_id，可设 max_depth=1..8。source 为原连接、群/私聊/话题和消息；nodes 是带 parent_session_key 的平面树，保留 children_coverage/truncated。
- link: 接收对话需要子任务追踪时，经 task.link 提交本条 delivery_id、准确 parent_session_key 与 child_session_key 及稳定 idempotency_key。需要 task.link 和两端 session.inspect 权限；仅原 recipient 或巡查管理员登记已接收投递。重复登记不增加分支，循环拒绝。显示 reported_unverified，不能说原生已证明归属。
- unknown: 无子关系记录只表示未提供，不是没有子任务；不要根据同名、同目录、创建时间或最近输入猜测归属。共享助手中的其他输入不属于本任务。
- state: accepted 只是接收确认；明确完成、无需回复或失败仍按 delivery.complete 通知 DJ。Typing 租约到期、对话空闲不等于任务完成。
- im: 已配置身份可在任意已接入 IM 私聊发送 /dj tasks、/dj tree DELIVERY_ID、/dj help，查询直接由 DJ 处理。群内只提示使用私聊，不暴露其他来源。未配置身份不得自报昵称或 principal 冒用。
