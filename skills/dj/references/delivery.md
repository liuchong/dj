# DJ 投递诊断

| 结构化观察 | 行动 |
| --- | --- |
| wrong reference / invalid_argument | 依据 field_errors 的字段路径重新使用正确类型引用，不猜 ID |
| 多个候选 / complete=false | 继续只读筛选或取得下一页；意图仍不明才询问，DJ 不会自行选择 |
| preview_stale/expired | 重读对象后重新预览；不把另一份规则塞进 create |
| already_committed / idempotency_conflict | 查原 operation_id；冲突请求停止，不换键消除告警 |
| 只有历史/无 live_receiver | 报告不能接收；不新开会话代替 |
| offline / busy / permission_pending | 由 DJ 按策略等待；不创建拉取任务或绕过原生审批 |
| accepted / started | 分别是接口接受/原生开始，不等于业务完成 |
| 请求超时且不知道对象 ID | 先 operation.get 按原 operation+key 核对，不拿 reply 的 key 查询 delivery |
| delivery_unknown / outbound_unknown | 对对应对象 reconcile；操作成功仍可能 state=unknown，不重发 |
| failed / unknown | 首期 Outbound 只有一个文本 part；仅明确未发送且接口允许时显式 retry，unknown 先核对原尝试，不整条重发 |
| reply_context 缺失/过期 | 不回复或报告限制；主动发送要有独立目标与授权 |
| incompatible / unsupported | 不猜帧、不切目标、不用模型为 DJ 补协议 |
| indeterminate / 正文不完整 | 报告判定缺口，不把未找到关键词解释为确定不存在 |

effect_state=none 才能把格式错误当作未受理修正；recorded/unknown 先核对原操作。next_actions 是固定恢复建议，不是自动执行或新授权。示例 key 不得用于多个逻辑意图；同一意图重试须保存原 key，跨入口也相同。

操作员显式 resolve 只能记录不重发的 manual 决定，不证明 native accepted；普通 Agent 不自动调用或批准。暂停/取消不能保证撤回提交点之后的输入。模型额度错误与传输错误分开，DJ 不判断任务结果或生成回复。

## 离线与重启恢复

- receive: Lark 从持久断点补收，新窗口最多一天、保留重叠并逐页去重，追平后恢复正常间隔；service.status 的 source_health.state=catching_up 与 lag_seconds 表示仍有历史缺口，ready 不代表已收齐。
- retry: AI 通知仅在 failed、definite_not_sent=true、retryable=true 时自动退避重试；过期不补发，永久拒绝不重试。客户端恢复后仍需原会话与当前权限检查，不自动启动替代进程。
- uncertain: Codex unknown 自动从准确原生会话的 userMessage 核对原 attempt 的完整输入，只接受正向证明；查不到仍保留 unknown，绝不据此新键重发。其他工具按实际 lookup 能力处理，必要时显式 delivery.reconcile。accepted 仅代表原生接收，不代表 AI 完成任务。
