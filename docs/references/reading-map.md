# 按设计问题查官方资料

所有 ID 的原始链接、查阅日期和限制见 [官方目录](official-sources.md)。先读需要的协议，不要求每次完整阅读全部资料。

| 问题 | 来源 | 对应 DJ 文档 |
| --- | --- | --- |
| 如何对齐 MCP 当前版本、传输、身份与错误 | MC01–MC09、RPC01 | interfaces/mcp、operations、security |
| 为什么普通 MCP 不保证空闲唤醒 | MC03/MC06、CL02 | architecture、adapters/agent-tools |
| 如何控制 Codex 线程/回合，活动追加有何前置条件 | CX01/CX04 | agent-tools、workflows |
| 如何接收 Claude 外部输入与尊重 inbound 策略 | CL01/CL02/CL06 | agent-tools、security |
| 如何托管 Cursor CLI；SDK 与桌面控制有何不同 | CU01–CU03、AC01–AC03 | agent-tools |
| 如何接入 OpenCode 既有后端、异步输入和事件 | OC01/OC02 | agent-tools、delivery-storage |
| Pi 接受、排队、处理、最终稳定如何区分 | PI01–PI03 | delivery-storage、agent-tools |
| agy 持续流、恢复、桌面导入分别意味着什么 | AG01/AG02/AG07 | research、agent-tools |
| Skill 格式与跨产品发现为何分开 | SK01/SK02、CX02、CL04、CU05、OC04、PI05、AG03/AG04 | skill-design |
| 各宿主如何连接 DJ 的 MCP | CX03、CL05、CU04、OC03、AG05 | interfaces/mcp |
| IM 事件为何需要单一接入所有者与源身份 | IM01–IM06 | adapters/im、delivery-storage |
| Eliscript 如何构建 ESM、与宿主互操作 | EL01–EL04 | technical-stack |
| 轻量服务、同步 SQLite 和本地 IPC 如何选型 | RT01–RT04、DB01/DB02 | technical-stack、startup-to-reply |
| SDK 版本与严格参数校验如何对应 | MC10/MC11、SC01/SC02 | technical-stack、interfaces/mcp |
| 首批为何选这些协议及可靠性边界 | OC01、PI01–PI03、IM01；本地 CLI schema 单列 | release-scope、startup-to-reply |

私有桌面 IPC、实验 Bridge、Inspector 和窗口缓存不在公开规范保证内。研究说明、协议参考和实机验收分别记录；对这些入口后续必须补版本锁定与失败条件，不能仅增加一个官方首页链接就宣称受支持。

Agent 控制面还参考 OC05、DB03，并重新核对 OC01、PI01/PI02；会话目录/字面搜索、实例启动/创建的范围与覆盖见 agent-control-plane.md。原生是否支持、DJ 是否装配和实机是否通过分别记录。

施工的编译配置参考同一固定快照 EL03；测试 runner 与 JUnit 参考新增 RT05/RT06。精确文件/命令与证据设计见 [施工手册](../construction/plan.md)及[测试实施](../construction/test-plan.md)，不把编写方案当作运行通过。

开工准备使用 MC12–MC15、PK01、RT07 固定依赖与SDK校验/代理生命周期，详见 [readiness](../construction/readiness.md)。源/包元数据、配置落盘、编译器同源、运行兼容及真实模型采用仍是不同证据，不由一个版本字符串合并。

Lark 国际版/as_user 的 OAuth 与消息列表、话题、事件身份区别见 IM07–IM10；DJ 自有轮询、PollCheckpoint、EchoGate 与默认 ~/.dj 布局见 adapters/im、construction/readiness。官方接收事件不等于用户全账号消息流，文档读取不等于 OAuth 或真实收信通过。
