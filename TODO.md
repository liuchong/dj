# DJ 待办

当前使用与能力见[安装指南](docs/delivery.md)和[项目状态](docs/status.md)。已结束阶段的完整勾选记录保留在[历史检查清单](docs/archive/implementation-checklist.md)，不自动成为下一轮运行任务。

## 已交付

- [x] CLI / 本地 API / MCP / GEPO 共用业务操作、权限与幂等。
- [x] Lark 官方 WebSocket / HTTPS 直连、user/bot 连接管理和订阅路由。
- [x] 人员与字符触发过滤、对话规则保存、固定回复身份、历史与引用上下文、处理中表情清理。
- [x] Codex、Cursor、OpenCode、Pi 的已有会话核心接线；Antigravity 原生接收；Claude Code 适配。
- [x] 目录包、Skill 安装与接线说明；Logo 与 Eliscript Pages。
- [x] 当前文档入口、安装/排查/开发指南及 1PL 许可证。

以上为实现或文档交付，真实验证范围以状态页为准。

## 后续专项

- [ ] 在真实 Claude Code 实例上确认原会话收件；不新启替代 Agent 来冒充已有实例。
- [ ] 补齐获准 Lark 本人消息和资源事件的真实新事件覆盖；读取、重放、轮询与实时证据分别记录。
- [ ] 按实际需要确认各客户端的 MCP/Hook 配置采用，以及 Pi 重启后的接收扩展配置。
- [ ] 其他 IM 的专项接线与验收。
- [ ] `T27.route-load.performance` 完整吞吐门槛。
- [ ] 有明确使用需求时验证可选会话创建和实例生命周期能力。

按完整功能阶段推进：先业务实现，再集中集成功能验收，最后补关键保护性测试。已通过且未受影响的证据复用，不因整理文档或更换会话重跑全套。

- [ ] 0009 任务巡查：实现统一来源树、管理员/本人连接权限、IM 确定性查询及子关联未知标记；施工见 docs/construction/task-inspection.md。业务实现与安装验收分别收口，不重跑全套性能或逐工具矩阵。
