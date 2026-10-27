# 研究结论与证据边界

## 如何阅读证据

研究整理日期：2026-10-23。前置实测来自 2026-10-15 至 2026-10-21 的研究记录，本轮核对了相关官方资料，没有重新向真实工作会话发送测试。历史实测只作为可行性输入；私有接口、本机版本、账号权限和桌面状态均可能改变。原始会话、凭据、机器路径和测试会话 ID 不进入仓库。

证据层次分为：官方公开协议、版本敏感的私有机制、前置研究已观察到的行为、DJ 设计选择、DJ 当前实现/验收。本仓库当前最后一层均为未实现/未运行。

## Agent 方向的可行性

| 工具形态 | 前置研究结果 | 仍有边界 |
| --- | --- | --- |
| Codex 桌面 | 已有活动对话的内部 IPC 追加输入通过 | 空闲启动分支没有同等实测；不是所有普通云聊天都可用 |
| Codex CLI | 公开 App Server 的会话、回合与事件机制已核对 | 托管服务不等于接管任意普通 TUI |
| Claude Code CLI | 真实 inbox 入队且同会话开始处理 | 余额阻断正常回复；写入无完整 ACK，hold/refuse 可阻断模型接收 |
| Claude Desktop Code | 有应用与历史线索 | 当时未取得可投递活动 inbox；不能沿用 CLI 成功 |
| Cursor 桌面 | 实验 Desktop Bridge 的指定会话投递与回复通过 | 普通重启恢复与升级兼容仍需验证 |
| OpenCode 桌面 | 已有实际窗口会话的消息、回复、客户端缓存与渲染一致；创建并注册标签页通过 | 共享后端历史不自动属于当前窗口，私有窗口管理单独验证 |
| Pi | 公开 RPC 托管控制方式已核对 | 当时没有完成对真实已有普通 Pi TUI 的发送验证 |
| Antigravity 桌面 | 已有后端发现、列出、创建、发送、读取与渲染同步通过 | 前置版本为 2.24.0；私有协议、跨平台和重启后全链路待验 |
| agy CLI | 托管的同一原生进程持续多轮收发与读回；退出后新进程恢复通过 | 前置版本为 1.4.3；任意非托管 TUI 自动接管未实现 |

以上都不是 DJ 的产品支持清单。正式支持须绑定适配器版本、操作系统、目标形态及 [验收](acceptance.md)。

## 官方资料本轮补充的发现

- Codex App Server 把历史、已加载会话、启动回合、活动回合追加区分开；优先作为托管模式协议。桌面内部 IPC 独立于公开协议。[官方 App Server](https://learn.chatgpt.com/docs/app-server)
- Claude Channels 提供向运行会话推入外部事件的专用方式，需要显式启用，且仍有预览、认证与组织策略条件；它是 DJ 可采用的主动输入适配方式，不是所有 MCP 客户端的通用功能。[Channels](https://code.claude.com/docs/en/channels)
- Cursor ACP 适合启动和管理 CLI 进程；官方 SDK Bridge 提供 SDK 集成。SDK Bridge 与前置研究的桌面实验 Bridge 是不同接口，不能互相证明已有桌面对话可控制。[ACP](https://cursor.com/docs/cli/acp)、[SDK Bridge](https://cursor.com/docs/sdk/bridge)
- OpenCode HTTP 具有会话、异步输入和事件接口；新启动 serve 与连接现有服务需区分。[Server](https://opencode.ai/docs/server/)
- Pi RPC 区分命令接受、运行事件和 agent_settled；返回成功不等于模型工作结束。JSON 单次输出与双向 RPC 也是两种运行方式。[RPC](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/rpc.md)
- agy 支持同一进程通过 stream-json 连续接收输入；按 ID 恢复启动的是新进程。桌面与 CLI 默认分开存储，会话导入不能解释成实时共用一个活会话。[Headless](https://www.antigravity.google/docs/cli/headless/)、[Resume](https://www.antigravity.google/docs/cli/commands/resume/)
- MCP 当前 latest 在本轮解析为 2026-07-28，核心已转向无状态、自描述请求，不能直接套用旧版生命周期。宿主实际支持范围仍需探测。[当前规范](https://modelcontextprotocol.io/specification/2026-07-28)、[变更说明](https://blog.modelcontextprotocol.io/posts/2026-07-28/)
- Agent Skills 有共同文件格式，各产品加载路径、刷新和权限行为仍不同。安装链接、发现目录、读取正文、实际按指令执行需分别证明。[格式](https://agentskills.io/specification)

## IM 方向的结论

多个平台已提供事件、长连接或长轮询接收方式；Agent 无需自建定时拉取。不同 IM 在账号权限、提及可见性、话题、机器人消息和历史查询上不能直接等同。Telegram webhook 与 getUpdates 互斥；并行部署必须先确定收件归属。具体策略见 [IM 接入](adapters/im.md)。

## 对 DJ 的设计影响

统一的是业务语义与能力声明，而不是假设每个产品存在相同收件口。发现必须沿工具、运行形态、实例、命名空间、会话 ID 和活接收方定位；窗口当前打开与最初创建来源分别记录。注册表不能从历史数据库推导在线状态。

最重要的待证问题是：精确目标处于空闲时能否真正唤醒、目标忙碌时队列如何交接、结果不明时怎样避免重复工作、同一 IM 身份是否存在竞争收件、DJ 与目标重启后如何恢复。完整问题与解除条件见 [设计决定](decisions.md)。

## 本轮整体审阅的边界修正

用户已明确 DJ 无 AI、不能使用大模型，定位是高效组件式转发服务。原设计“语义分类/摘要为未来候选”已撤销；自然语言理解只属于调用方。已有厂商可编程能力不改变这一边界，DJ 仅用固定协议连接外部 Agent。面向模型的类型化引用、固定预览和结构化错误属于本产品设计，不是声称厂商均提供这些接口。

## 技术方向与首批范围收敛

用户指定前期使用 Eliscript。已只读核对当前源码的 ESM 构建和互操作合同，采用 ESM/Bun、SQLite 和本地薄客户端；首批为 Lark 国际版（user）/Telegram 与 OpenCode/Pi。选择依据、当前版本候选、CLI schema 和真实验收缺口分别维护在 technical-stack.md 与 release-scope.md，不将语言 README 或版本读回当作 DJ 已接通证据。本轮未修改语言源码或恢复其他项目开发。

## 统一会话控制追加

用户追加跨工具机械查询、免订阅向已知会话输入、指定实例创建会话、显式启动工具及 CLI/MCP/API 接入，首期不做 IM 操作界面。新增 ToolInstance/SessionRecord/TargetRoute 与生命周期台账；采用本地索引/明确范围和覆盖，不增加任务归属推理。首期在已有两个 Agent 协议上补控制能力，其余工具仍按适配证据声明。未执行实际启动、创建或发送。
