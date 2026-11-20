# 组订阅

- purpose: 由调用方明确指定多个准确对话及机械算法；同一组只有唯一一个订阅槽位（`group:<group_id>`），每个事件在组内机械选一个成员，不改变普通多对多订阅。DJ不判断任务负责人、不安排协作、不根据正文智能选人。
- group: `subscription.group.create` 的 `name` 仅供展示，`members` 最多 32 项，每项 `agent_id` 必填，`enabled` 默认 `true`，`priority` 默认 `0`、数字越小越优先。`get`/`list` 查回，`update` 整体更新成员并带 `expected_revision`，`delete` 只允许没有在用订阅的组。
- subscribe: `subscription.preview` 的 `spec` 在 `agent_id`/`group_id` 中恰选一个；使用 `group_id` 时 `rules`、`context_policy`、`instruction_policy`、`delivery_policy` 沿用普通订阅流程，再用 `preview_id` 与 `expected_revision`（首次为 `0`）提交 `subscription.set`。组内成员继续有各自 `session.rules`；不要向组写 `subscriber_model` 来替所有成员声明模型。
- distribution: `spec.distribution.algorithm` 可选 `random`、`round_robin`、`priority`。服务 `group_distribution` 提供省略字段的默认，内建 `round_robin`。提交时固化有效策略，修改服务默认不会偷偷改变现有订阅；改变订阅须 `preview` + `set`。
- quota: `distribution.eligibility.quota` 可选 `exclude_exhausted`（默认，跳过已知耗尽、未知仍可参与）、`require_available`（仅已知可用者参与）、`ignore`。所有算法共用此筛选。`agent.availability` 按准确 `agent_id` 只读查询，返回 `state/source/observed_at/valid_until/reset_at`；`unknown` 不是没额度，`available` 不保证够完成任务。
- evidence: Antigravity原生GetUserStatus可提供模型余量，但零基线不一定没有超额额度，未能证实总体不可用时返回unknown。OpenCode可记录原生结构化insufficient_quota等拒绝；普通429只表示限流、不等于耗尽。其他端口未提供额度接口时明确unknown；不会新启CLI、换模型、购买额度或把/usage发给模型试探。
- recovery: 无成员可用时 `waiting_member` 持久保留至 TTL，恢复后继续选择。随机选择、轮询位置和选中成员落盘。明确未发送才允许换成员；已经 `accepted` 或 `submitting`/`unknown` 不自动改投，即使模型之后报错也不据此复制任务。
- inspect: `subscription.group.dispatches` 以 `group_id` 查询实际选择、状态、排除原因和有界选择历史。组分发不改变原消息/账号/回复身份、出站退订、处理中表情和消息可见性。
- pull: 组订阅使用 `delivery_mode="pull"` 时，`subscription.pull` 必须同时给 `group_id` 和自己的准确 `agent_id`。只领取分给该成员的 entry；不要用共享 principal 自动代领别人的消息。`claim_ref` 仍按原 `subscription.ack` 流程确认。
- overlap_with_direct: 路由固定先评估全部单对话订阅（`session:*`），再评估组订阅（`group:*`），并以 `(event_key, session_key)` 为唯一通知槽位。若某组成员在同一事件已命中其自身单对话订阅（`push` 或 `pull`），组选人时若有其他合格成员则跳过该已通知成员（记录排除原因 `already_notified`）；若全部合格成员均已在本事件命中各自单对话订阅，则组分发直接记录 `state="coalesced"` 与 `coalesced_into`，不产生重复的第二条通知。

## 调用示例

调用 `subscription.group.create`；变更必须使用独立幂等键，未知结果先查 `operation.get`：

```json
{"name":"消息接收组","members":[{"agent_id":"agent_alpha","priority":0},{"agent_id":"agent_beta","priority":1}],"idempotency_key":"create-receiver-group"}
```

下面是 `subscription.preview` 中的 `spec` 示例；预览后用返回的 `preview_id` 与 `expected_revision` 调用 `subscription.set`：

```json
{
  "group_id":"group_example",
  "distribution":{"algorithm":"round_robin","eligibility":{"quota":"exclude_exhausted"}},
  "rules":[
    {
      "id":"support-mentions",
      "enabled":true,
      "sources":[{"connection_id":"connection_example"}],
      "predicate":{"field":"addressed_self","op":"eq","value":true}
    }
  ]
}
```
