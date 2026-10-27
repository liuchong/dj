# 文档总索引

更新日期：2026-10-24（北京时间）。全部产品行为为设计契约；历史研究、官方协议能力、DJ 实现和真实验收分别记录。

| 文档 | 唯一负责内容 |
| --- | --- |
| [目录包运行说明](../packaging/runtime.md) | 成品闭包、默认私有配置、启动到回复、独立 recipient 重载与安全停止；实测状态另看 status/TODO |
| [0001 Lark 实时订阅规格](specs/0001-lark-realtime-subscriptions.md) | 长连接全消息接入、本人收发、默认 @ 与复杂过滤、精确原对话通知和 Skill；覆盖冲突的历史轮询约定 |
| [组件契约](component-contract.md) | 无 AI 硬边界、责任、热路径与性能目标 |
| [模型调用](model-facing.md) | 类型化引用、固定预览、错误与调用闭环 |
| [Agent 会话控制面](agent-control-plane.md) | 跨工具目录/机械搜索、免订阅直发、显式启动/创建与生命周期 |
| [设计审阅](design-review.md) | 本轮发现、基线、处置与剩余限制 |
| [需求](requirements.md) | 原始需求编号、范围、推导与建议 |
| [研究](research.md) | 已有证据、官方资料新增发现、可行性与缺口 |
| [技术选型](technical-stack.md) | Eliscript、宿主、持久化、依赖与组件构建边界 |
| [首批范围](release-scope.md) | 两 IM × 两 Agent、正向/拒绝/后续适用矩阵与兼容证据 |
| [启动到回复](startup-to-reply.md) | 部署、身份接线、登记订阅、输入与原话题回复 |
| [架构](architecture.md) | 进程、模块、依赖、扩展边界 |
| [领域模型](domain-model.md) | 对象、字段、标识、状态和订阅规则 |
| [流程](workflows.md) | 查询、直发、启动/创建、接线订阅、回复及停止/恢复的统一分支 |
| [投递与存储](delivery-storage.md) | 事务、去重、顺序、未知结果和恢复 |
| [权限](security.md) | 调用身份、授权、凭据、来源与控制边界 |
| [统一操作](interfaces/operations.md) | CLI/MCP 共用的业务操作、参数、结果与错误 |
| [CLI](interfaces/cli.md) | 命令映射、输入输出、退出码和示例 |
| [MCP](interfaces/mcp.md) | 规范版本、工具映射、传输、宿主扩展 |
| [GEPO](interfaces/gepo.md) | 同路径 GET 用法/POST 调用、认证发现与本地 UDS |
| [Agent 接入](adapters/agent-tools.md) | 工具能力矩阵、适配契约和版本证据 |
| [IM 接入](adapters/im.md) | 各平台事件、账号、权限与收件归属 |
| [Skill 设计](skill-design.md) | 内容边界、分发、发现、采用验证 |
| [Skill](../skills/dj/SKILL.md) | Agent使用流程与授权边界；客户端发现/采用仍须真实验收 |
| [验收](acceptance.md) | 给定/当/则场景、覆盖、证据和运行层次 |
| [设计决定](decisions.md) | 设计取舍与尚未决定事项 |
| [状态](status.md) | 当前产物和后续工作；唯一接续入口 |
| [施工手册](construction/plan.md) | eca0e26 当前快照、目标树/调用流、D01–D18 文件/符号和实现顺序 |
| [施工接口](construction/contracts.md) | 目标函数签名、内部字段、操作接线、事务/端口/构建合同 |
| [开工准备](construction/readiness.md) | 固定包/源身份/环境事实、I01配方、SDK校验接线、真实测试输入与剩余证据 |
| [操作字段表](construction/operation-catalog.md) | 61操作逐项必填/可选/互斥/幂等/修订/结果，供schema直接转写 |
| [用例卡](construction/case-cards.md) | 固定fixture、72主场景具体输入/断言、四组合分支、P/R/D和字段变体 |
| [真实验收准备](construction/real-preflight.md) | 15个授权控制器的现有协议、原始观察来源、资源与装配缺口；不构成运行证据 |
| [测试实施](construction/test-plan.md) | T01–T72 子例/文件/层次/适用范围、执行命令、计时/隔离/证据 |
| [唯一 TODO](../TODO.md) | S0–S3、I01–I30 施工和 A01–A20 验收 checkbox；唯一进度表 |
| [Goal 草稿](construction/goal.md) | 后续施工完整正文；文案与已有 active Goal 状态分开记录 |
| [官方资料](references/official-sources.md) | 官方 URL、用途、查阅日期、访问限制 |
| [资料阅读地图](references/reading-map.md) | 从设计问题找到相关来源 |

设计冲突先按所属文档修正，再同步直接消费者。外部规范仅约束相应协议，厂商文档不构成 DJ 已实现声明。日期与访问成功也不能替代安装版本实测。各类运行证据以status/TODO为准；索引变更本身不执行部署、Skill安装或外部动作。
