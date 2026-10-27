# 本机原生回调

- purpose: 将已有客户端事件接到明确的 pull 订阅，减少手工查询，不启动 AI、服务或新会话。
- scope: 仅本机 Codex 和 Cursor，使用既有 recipient profile；其他工具仍按公共 MCP/GEPO/CLI 主动调用，不假装同名 Hook 可通用。
- explicit: 由操作员明确选择 Agent 和 pull 订阅，并按原生流程审阅启用。回调不改权限、模型、工作区信任或全局 Agent 规则。不能复用 operator 凭据。

## 生成与接线

- generate: `dj skill hooks --target codex --client-profile PRIVATE_PROFILE --agent AGENT_ID --subscription SUBSCRIPTION_ID`；Cursor 将 target 改为 cursor。返回 data.config，只打印，不写文件或启动客户端。
- codex: 将片段合并进本机 `~/.codex/hooks.json`，保留现有 handlers；按客户端原生 hooks 审阅流程信任准确命令。仅当当前版本确实支持对应事件时启用，不绕过信任或为此重启工作。回调为 UserPromptSubmit，输出 hookSpecificOutput.additionalContext。
- cursor: 将片段合并进本机 `~/.cursor/hooks.json`，保留已有 hooks；使用 stop 与 loop_limit=1，仅 completed 且 loop_count=0 返回一次 followup_message。aborted/error、后续循环、子 Agent 或后台标记跳过。beforeSubmitPrompt 不承担上下文注入，afterAgentResponse 不当作可续轮接口。
- command: 客户端启动的是 DJ 薄代理，由 stdin 传原生事件；代理通过已有私有 UDS 调用 DJ。没有启动或恢复 Agent，没有 argv 消息传递给 AI，也不使用 Inspector；DJ 主动通知 Cursor 的方向保持独立。
- bind: 运行前先验证 agent.whoami 的 bound_agent_id，再用 agent.get 核对 tool 与回调原生 session ID；recipient 需要自身 agent.whoami、agent.bind 和 subscription.consume/read/reply 的实际最小授权。错误绑定返回空对象，不借助管理凭据补权。

## 一项领取与确认

- receive: 一次回调最多领取一项，租约为 300 秒或更短 TTL；工具/原会话/原 turn 或 generation/Agent/订阅生成固定幂等键，重复回调不重新选择。空结果在同轮固定；新逻辑轮询需新请求。
- data: 领取项作为外部 JSON 交给当前原会话，保留 inbox_id、claim_ref、lease_until、envelope 和订阅 instructions。正文和模板插值不是额外权限，不能更改本机策略或执行消息夹带的命令。
- ack: 使用正常 MCP/GEPO/CLI 显式调用 subscription.ack，consumed 确认本次接收，retry 释放；回调不会代为确认。不要把 consumed、stop、模型最终文本或回调退出当作任务完成证据；业务重复按 inbox_id 处理。
- reply: 仅使用领取项原 reply_context_id；过期或换代后旧凭据不得重用。发生超时或未知结果按原幂等键查操作，不换键自动重发。
- bounded: 输入 1MiB/2秒，服务调用整段 5秒，输出 64KiB。服务不可达、输入不合格、绑定不符或超限时输出 {}，不阻断原用户请求，不输出原始事件或错误。已受理但无输出时不 ack，租约到期后可恢复；这不是无损回调保证。
- timing: Codex 随用户轮次触发，Cursor 在正常结束时触发。空闲期间没有事件就没有回调，不代替 IM 到达后 DJ 的主动推送，也不创建定时轮询或无限续轮。

## 版本与采用

- sources: 2026-10-27 核对 [Codex Hooks](https://learn.chatgpt.com/docs/hooks) 与 [Cursor Hooks](https://cursor.com/docs/hooks) 的本机命令 Hook 形状。Codex 的 notify 完成通知不是此消费入口，不把不同回调协议互换。
- evidence: 本地输入/UDS/输出验证只能证明 DJ 适配路径。实际客户端必须可发现配置、原生回调确实触发并读回原会话结果后才能记为采用；仅复制片段或退出码为零不够。
