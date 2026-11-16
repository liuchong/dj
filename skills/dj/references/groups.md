# 组订阅

- purpose: 由调用方明确指定多个准确对话及机械算法；同一组订阅每个事件选一个成员，不改变普通多对多订阅。DJ不判断任务负责人、不安排协作、不根据正文智能选人。
- group: subscription.group.create的name仅供展示，members最多32项，每项agent_id必填，enabled默认true，priority默认0、数字越小越优先。get/list查回，update整体更新成员并带expected_revision，delete只允许没有在用订阅的组。
- subscribe: subscription.preview的spec在agent_id/group_id中恰选一个；使用group_id时sources、predicate、context_policy、instruction_policy、delivery_policy沿用普通订阅流程，再用preview_id提交subscription.create/update。组内成员继续有各自session.rules；不要向组写subscriber_model来替所有成员声明模型。
- distribution: spec.distribution.algorithm可选random、round_robin、priority。服务group_distribution提供省略字段的默认，内建round_robin。提交时固化有效策略，修改服务默认不会偷偷改变现有订阅；改变订阅须preview/update。
- quota: distribution.eligibility.quota可选exclude_exhausted（默认，跳过已知耗尽、未知仍可参与）、require_available（仅已知可用者参与）、ignore。所有算法共用此筛选。agent.availability按准确agent_id只读查询，返回state/source/observed_at/valid_until/reset_at；unknown不是没额度，available不保证够完成任务。不同账户、模型桶、窗口的百分比不能直接比较。
- evidence: Antigravity原生GetUserStatus可提供模型余量，但零基线不一定没有超额额度，未能证实总体不可用时返回unknown。OpenCode可记录原生结构化insufficient_quota等拒绝；普通429只表示限流、不等于耗尽。其他端口未提供额度接口时明确unknown；不会新启CLI、换模型、购买额度或把/usage发给模型试探。
- recovery: 无成员可用时waiting_member持久保留至TTL，恢复后继续选择。随机选择、轮询位置和选中成员落盘。明确未发送才允许换成员；已经accepted或submitting/unknown不自动改投，即使模型之后报错也不据此复制任务。需要业务转交由AI/用户决定。
- inspect: subscription.group.dispatches以subscription_id查询实际选择、状态、排除原因和有界选择历史。组分发不改变原消息/账号/回复身份、出站退订、处理中表情和消息可见性。
- pull: 组订阅使用delivery_mode=pull时，subscription.pull必须同时给subscription_id和自己的准确agent_id。只领取分给该成员的entry；不要用共享principal自动代领别人的消息。claim_ref仍按原subscription.ack流程确认，不把取到消息当任务完成。
- same_event: 普通订阅和其他组订阅仍独立通知。组单成员语义不表示系统级业务exactly-once；同一对话也可能通过另一条订阅收到同一事件，AI按既有规则决定是否处理。

## 调用示例

调用 subscription.group.create；CLI 可用 `dj subscription group create --json --input <JSON文件>`，JSON文件只放下面的参数。MCP/GEPO选择同名操作并传同一组参数。变更必须使用独立幂等键，未知结果先查operation.get。

```json
{"name":"消息接收组","members":[{"agent_id":"agent_alpha","priority":0},{"agent_id":"agent_beta","priority":1}],"idempotency_key":"create-receiver-group"}
```

下面是subscription.preview中的spec片段；selector等字段按普通订阅补齐，然后提交preview_id。

```json
{"group_id":"group_example","distribution":{"algorithm":"round_robin","eligibility":{"quota":"exclude_exhausted"}},"selector":{"sources":[{"connection_id":"connection_example"}]}}
```
