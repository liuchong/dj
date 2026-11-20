# 配置固定接线

- purpose: 管理员可以在服务配置的 `fixed_routes` 中把一个或多个 IM 账号/群固定接到准确已有 AI 对话或显式组，不要求目标 AI 主动调用订阅。它直接绑定目标唯一的订阅槽位（`session:<session_key>` 或 `group:<group_id>`），使用现有 Agent、订阅、黑名单、消息上下文和原生投递，不是另一套 relay。
- setup: 先配置 `connections` 中各账号及独立 `credential_ref`、`agent_endpoints` 中现有实例，以及 `principals` 中 recipient 的实际授权；配置片段见 `config/fixed-routes.example.json`。它是合入现有 `service.json` 的片段，不是完整服务配置。
- target: 每项有稳定 `id`、`owner_principal_id`（operator）、`recipient_principal_id`（agent）、`target.instance_id/native_session_id`（或 `group_id`）与 `rules[]`（`1..64` 条分支）。同一配置中禁止两条 `fixed_route` 指向同一 `session_key` 或 `group_id`；需要多来源、多条件时统一写在同一条 `fixed_route` 的 `rules[]` 中。若目标已有 AI 自建的独立订阅，固定接线不会覆盖它，而是进入 `blocked`（`forbidden`）。
- rules: 每条 `rules[i]` 包含 `id`、`enabled`、`predicate` 及可选 `sources`（`connection_id`，可选 `native_chat_id`/`native_thread_id`/`include_threads`）、`event_kinds`、`context_policy`、`instruction_policy`；线级可设 `delivery_mode`、`context_policy`、`delivery_policy`、`instruction_policy`、`distribution`。
- lifecycle: 启动自动登记期望接线，再由有界后台岗位核实和装配；首次目标离线会退避恢复，不拉起替代 Agent。首次 `active` 以后才开始接收新事件，不隐式重放此前历史。已有活动接线重启保持原订阅与水位。
- update: 修改 `fixed_routes` 后用现有 `SIGHUP`/`Core.reloadConfig` 原子重载；修改先暂停旧接线，成功后切换并恢复新规则；`enabled=false` 或删除只暂停并释放该配置拥有的订阅管理权，不停账号、不删共享 Agent。
- authority: `subscription.get/list` 返回 `configuration_id` 时，该订阅由对应固定配置管理，接收者可读取但不能用 `subscription.set/pause/resume/delete` 改写。启用接线引用的 Agent 也不能 `rebind/unregister`，先停用或移除相关固定接线。
- inspect: `service.status.fixed_routes` 返回 `id/state/last_error/next_attempt_at/agent_id/target_key` 和准确 `target`；operator 可见全部，recipient 只见自己的，其他主体看不到。
- replies: AI 仍自行决定是否及何时回复；回复使用原通知的 `reply_context_id`，由 DJ 固定身份和目的地。
