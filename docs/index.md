# 文档

## 安装、接线与日常使用

| 需要做什么 | 阅读入口 |
| --- | --- |
| 安装运行包、准备账号与 AI 会话 | [安装与使用](delivery.md) |
| 让 DJ 随 macOS 登录持续运行 | [macOS 常驻服务](guides/macos-service.md) |
| 设置 Lark / 飞书消息订阅 | [实时订阅指南](guides/lark-realtime.md) |
| 安装 Skill、配置 MCP 或 GEPO | [客户端接线](../skills/dj/references/clients.md) |
| 收到通知后读取、处理与回复 | [DJ Skill](../skills/dj/SKILL.md)、[消息闭环](startup-to-reply.md) |
| 查看来源任务树及排队原因 | [任务巡查](guides/task-inspection.md) |
| 消息没触发、投递未知或回复失败 | [故障排查](guides/troubleshooting.md) |
| 了解实际交付和验证范围 | [能力范围](release-scope.md)、[当前状态](status.md)、[待办](../TODO.md) |

## 接口

- [统一业务操作](interfaces/operations.md)：字段、结果、权限、幂等与错误。
- [CLI](interfaces/cli.md)、[本地 API 与 GEPO](interfaces/gepo.md)、[MCP](interfaces/mcp.md)。
- [Agent 会话控制](agent-control-plane.md)：发现、定位、查询、直发和显式创建。
- [面向 AI 的调用规则](model-facing.md)、[Skill 分发](skill-design.md)。

运行时的 `--help`、MCP 工具描述与 GEPO 发现由 `src/application/operations.eli` 的同一操作目录生成；操作数量不在文档中另存一份。

## 产品规格

- [0013 表情触发](specs/0013-reaction-triggers.md)：指定一个或多个原生 emoji_type，与提及、私聊并列配置。

| 规格 | 内容 |
| --- | --- |
| [0001 实时订阅](specs/0001-lark-realtime-subscriptions.md) | Lark 收件、本人身份、默认 @ 和准确原会话投递 |
| [0002 触发过滤](specs/0002-message-trigger-filters.md) | 人员、字符及组合黑名单；只限制触发动作 |
| [0003 连接与路由](specs/0003-connections-and-routing.md) | 多 IM、多账号、user/bot 共用的连接管理 |
| [0004 对话规则](specs/0004-session-rules.md) | 原文保存、读回与投递恢复 |
| [0005 提及与回复](specs/0005-mention-replies.md) | 固定回复身份和原消息位置 |
| [0006 处理中表情](specs/0006-working-reactions.md) | 登记、完成及最终清理 |
| [0007 消息上下文](specs/0007-message-context.md) | 历史、引用、话题与缓存读取 |
| [0008 资源来源](specs/0008-resource-sources.md) | 文档、表格、Wiki 和原生事件 |
| [0009 任务巡查](specs/0009-task-inspection.md) | 来源树、管理员／本人连接权限及确定性 IM 查询 |
| [0010 消息消费](specs/0010-message-consumption.md) | 默认忙时直达、可配置排队及全局异步消费 |

## 技术与维护

- [架构](architecture.md)、[组件职责](component-contract.md)、[领域模型](domain-model.md)、[需求](requirements.md)。
- [业务流程](workflows.md)、[可靠投递与存储](delivery-storage.md)、[身份与安全](security.md)。
- [Agent 适配](adapters/agent-tools.md)、[Codex / Cursor](adapters/desktop.md)、[Cursor 原生接口](adapters/cursor-native.md)、[Claude / Antigravity](adapters/native-inboxes.md)、[IM 适配](adapters/im.md)。
- [技术栈](technical-stack.md)、[设计决定](decisions.md)、[开发与打包](guides/development.md)、[验收范围](acceptance.md)。
- [官方资料](references/official-sources.md)与[阅读地图](references/reading-map.md)。

## 站点、许可证与历史

- [Pages 源码与预览](pages/README.md)：入口 `docs/index.html`，交互使用浏览器实时编译的 Eliscript。
- [项目许可证](../LICENSE)：[1PL 官方说明](https://license.pub/1pl/)。
- [历史资料](archive/README.md)：旧研究、施工计划、检查清单及验收批次。历史中的状态和建议不作为当前使用或开发指令。

- [0011 可读的 AI 消息通知](specs/0011-readable-notifications.md) · [使用说明](guides/notifications.md)
- [0012 Kimi 与 DSH 已有实例](specs/0012-kimi-dsh-existing-sessions.md) · [接入说明](guides/kimi-dsh.md)
