# 配置固定接线

- purpose: 管理员可以在服务配置的 fixed_routes 中把一个或多个 IM 账号/群固定接到准确已有 AI 对话，不要求目标 AI 主动调用订阅。它使用现有 Agent、订阅、黑名单、消息上下文和原生投递，不是另一套 relay。
- setup: 先配置 connections 中各账号及独立 credential_ref、agent_endpoints 中现有实例，以及 principals 中独立 recipient 的准确 target_constraint；配置片段见 config/fixed-routes.example.json。它是合入现有 service.json 的片段，不是完整服务配置。不同机器人账号使用不同 connection_id，不能凭昵称选目标。
- target: 每项有稳定 id、owner_principal_id（operator）、recipient_principal_id（agent）、target.instance_id/native_session_id、sources。工具及命名空间从 endpoint 得到，不按同名对话猜测。多个接线可共用同一准确目标及 recipient；同一 recipient 不允许多个目标。已有 Agent 归属或目标冲突会 blocked，不抢占；要改目标请明确配置新的 recipient。
- source: sources 至少一项，connection_id 表示整条账号连接；指定 native_chat_id 可限定会话，native_thread_id 可限定原生话题，仅指定 chat 时 include_threads 默认 true；精确 thread 默认 false 且不允许 true。复杂条件用现行 predicate 的 all/any/not。event_kinds/context_policy/delivery_policy/instruction_policy 复用订阅定义；省略 predicate 使用默认 @、私聊、引用、话题和已发消息表情条件。默认不等 AI 上个任务结束，是否真正可忙时输入仍取决于原生端口。
- lifecycle: 启动自动登记期望接线，再由有界后台岗位核实和装配；首次目标离线会退避恢复，不拉起替代 Agent。首次 active 以后才开始接收新事件，不隐式重放此前历史。已有活动接线重启保持原订阅与水位，后续离线投递使用原有持久队列。
- update: 修改 fixed_routes 后用现有 SIGHUP/Core.reloadConfig 原子重载；不支持借重载改 IM 账号、endpoint 或数据库。修改先暂停旧接线，成功后恢复新规则；enabled=false 或删除只暂停该配置拥有的订阅，不停账号、不删共享 Agent、不影响 AI 自建订阅。
- authority: subscription.get/list 返回 configuration_id 时，该订阅由对应固定配置管理，接收者可读取但不能用 subscription.update/pause/resume/delete 改写。启用接线引用的 Agent 也不能 rebind/unregister，先停用或移除全部相关固定接线。需要改变它时由管理员改配置。普通 AI 自建订阅、规则及明确授权的历史 replay 照常使用原接口。
- inspect: service.status.fixed_routes 返回 id/state/last_error/next_attempt_at/agent_id/subscription_id 和准确 target；operator 可见全部，recipient 只见自己的，其他主体看不到。active 只说明接线建立，不能宣称模型已完成任务或回复已发送。pending/retrying 等待恢复，blocked 按真实原因修复配置/权限，不更换账号、会话或幂等键乱投。
- replies: AI 仍自行决定是否及何时回复；回复使用原通知的 reply_context_id，由 DJ 固定身份和目的地。固定接线不把所有模型输出自动回传 IM，也不替目标对话改持久业务规则。
