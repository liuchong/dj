# 任务巡查

接口为 task.list、task.tree 和 task.link；MCP、GEPO、CLI 共用它们。只读查询不启动模型。原消息和原 AI 会话已通过现有投递关联；子对话按准确任务显式登记，没有登记就显示关联未知，不遍历共享助手的所有无关任务。

在私有 service.json 增加 task_inspection：administrators 是获准全局巡查的 principal_id 数组；users 是 {principal_id,identities,connections} 数组。identities 的每项为已核实的 {platform,scope,id}，例如应用级 OpenID 的 scope 使用 app:APP_ID:open_id，不能按昵称绑定。connections 每项为 {connection_id,identity_revision}，必须匹配当前账号身份，账号变化后重新审核绑定。普通用户只查此范围；管理员不隐含授予其他操作。

为各主体授予 task.inspect 对 task-inspection 的访问权。需要登记子任务时再授予 task.link 和相应 session.inspect。IM 命令复用该主体正常 message.send 授权及幂等出站链路；不给巡查用户配置跨范围的其他业务权限。私有配置不进入仓库。白名单与绑定变更可以通过服务的 SIGHUP 配置重载生效；已排队查询结果会在发送前重新核对策略，撤权后不继续发出。

IM 私聊：/dj tasks 显示 5 项；按结果的 /dj tasks AFTER 翻页；/dj tree DELIVERY_ID 展开一条来源树；/dj help 查看帮助。群里不展示跨来源信息。结果固定返回原命令位置，正文不能指定另一个收件人或身份。命令本身不进入订阅任务，出站回声继续去重。

API task.list 使用 after/limit（默认 10，最多 50）。task.tree 使用 delivery_id/max_depth（默认 4，最多 8），最多返回 128 节点，截断与子关系覆盖显式返回。task.link 由准确接收者或巡查管理员登记现存会话，reported_unverified 不等于原生因果已证实。

ready/deferred/blocked 显示队列状态和原因；accepted 仅为原生接收。任务完成依明确完成记录；实时对话状态带 observed_at/runtime_stale，不将 busy、idle 或表情租约到期当作最终业务结果。
