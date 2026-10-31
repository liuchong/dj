# 对话督工

- purpose: 由原对话主动请求 DJ 在意外结束或临时中断后继续提醒原任务；直到明确取消。
- enroll: 用 agent.whoami 核对自身绑定，再调用 session.supervision.start；agent_id、session_key、session_ref 三选一，prompt 写清原任务、接续入口和限制，带独立 idempotency_key。不替用户擅自给其他对话登记。
- example: CLI 将完整输入保存为 supervision.json 后调用 dj session supervision start --input supervision.json --json；不要假定每个业务字段都有独立 CLI flag。MCP/GEPO 直接传相同结构化参数。
- inspect: dj session supervision get --agent-id <本对话agent_id> --json。active 仅表示登记还在；status、last_error、delivery_id、next_check_at 说明实际进展。发送受理不代表任务或 Goal 恢复。
- cancel: dj session supervision cancel --agent-id <本对话agent_id> --idempotency-key <唯一键> --json。任务完成、用户主动暂停或不再需要提醒时主动取消；普通最终回答不会取消督工。取消不停止当前任务，已经提交的原生输入不能撤回。
- recovery: 忙时不催，等待授权不批准；离线后持久等待、指数退避，实例恢复后仍向原对话续接。默认30秒检查、连续空闲120秒后提醒；不能保证原生一直报告busy的卡死能自动解除，不启动替代CLI或新建会话。
- uncertainty: 同一唤醒复用持久幂等键，unknown 等待原投递核实，不能手动换键重发。不把额外接收对话当作恢复路径。
- goals: 收到督工续接后先核对当前任务和停止原因；沿宿主真实接口恢复意外中断的 Goal，核验原目标与预算，不能用新任务或数据库写入冒充恢复。用户暂停、预算耗尽、权限阻塞先按原限制处理；需要用户决定时明确说明并取消不适合继续的督工。
- permission: 已有可信精确会话绑定的主体可以自督工；管理其他会话需要 session.supervise 权限。没有自身身份绑定时先按已有接线流程登记，不借其他主体凭据。

## 登记输入示例

```json
{
  "agent_id": "本对话的准确agent_id",
  "prompt": "继续原任务；沿项目TODO接续，完成后取消督工。",
  "idle_seconds": 120,
  "check_seconds": 30,
  "idempotency_key": "为本次登记生成的唯一键"
}
```
