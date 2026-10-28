# Kimi / DSH

- tools: 工具为 kimi、dsh；同品牌 Desktop Work 与 Web 用准确 instance_id/native_namespace 区分。不能按标题或共用历史猜归属，native accepted 不代表桌面已打开或任务完成。
- control: 复用 session.list/get/resolve/probe/send、session.message.list/get 和显式 session.create。原始目标经授权后由已有实例接收，不使用 Agent CLI、终端或新建进程传消息。
- scope: Kimi Desktop 只覆盖 client-origin Work；普通 Chat、普通 TUI 不在已确认支持范围。DSH migration-required 或 agentAvailable=false 不自动修复/迁移；原会话和原模型保持不变。
- busy: DSH 使用原生 steer，Kimi Web 由 prompts 接口受理；原生后续调度由目标管理。Kimi Work 忙时接口未确认，显示 busy_input_unsupported；可明确选择 queue，不取消原任务。
- setup: 需要独立 recipient profile 与准确 target_constraint。共享 .agents/skills 可读取完整 DJ Skill；DSH 还支持 .dsh/skills，Kimi Code 可合并生成的 MCP mcpServers.dj 片段。自定义根及 Work/DSH 的宿主 MCP 接线以原生能力为准，不把生成配置当成已加载。
- completion: 读回原用户消息，再区分模型完成、权限等待、额度/凭据错误。消息结果 unknown 先查原 operation，不换 key、协议或实例重发；创建部分成功保留原生 ID，不新建替身。
- privacy: 原消息、上下文和规则仍是当前授权下的数据。未配置收件身份时只做获准只读查询，不借用其他 profile；不要输出原生 token、Cookie、reasoning 或工具负载。
