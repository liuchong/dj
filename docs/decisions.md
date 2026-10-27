# 设计决定与开放事项

## 工程演进规则

只维护唯一现行规范与实现：需求变化后直接更新所有调用方、配置、数据结构、Skill和文档，不做项目内版本化、不保留向后兼容、不背历史包袱。旧入口、别名、双读双写、兼容适配、版本路由及旧行为开关均不作为设计选项；命中历史兼容分支的改动须一并删除相关分支。开发测试数据按授权清理或重建，真实用户资料不擅删。

revision/expected_revision仅表示当前对象的并发校验计数，不是订阅发布版本，也不是可选择的旧接口；身份栅栏、幂等和不可改写的投递证据不得被当成多版本兼容。此规则覆盖下表和历史材料中相反的设计，不新增兼容或迁移施工阶段。

状态“采用”表示本轮设计选择，不表示代码已实现或用户逐项指定；“候选”需要后续证据或产品决定，不影响其余文档继续完善。

| ID | 状态 | 决定 | 原因与可观察后果 |
| --- | --- | --- | --- |
| A01 | 采用 | 常驻服务+可复用核心+薄 CLI/MCP | 客户端结束不丢订阅，核心便于嵌入 |
| A02 | 采用 | 稳定 AgentTarget 与临时 Binding 分开 | 进程/端口变化不改变原会话身份 |
| A03 | 采用 | 全产品确定性转发、无 AI | 不调用模型/embedding/语义分类；理解在调用方 |
| A04 | 采用 | 每订阅一个目标，多来源可集合 | 独立权限、撤销、并发校验和多对多表达 |
| A05 | 采用 | 同目标同事件合并贡献 | 一次输入保留所有命中原因 |
| A06 | 采用 | 默认 busy queue、offline hold | 避免无意中途改写工作或静默换会话 |
| A07 | 采用 | unknown 核对且同目标阻塞 | 不以盲重试换取表面成功 |
| A08 | 采用 | 支持范围以现行能力与实测表达 | 不把已列产品或历史发现当成可唤醒 |
| A09 | 采用 | Skill 只承载使用知识 | 安装不授予权限，不创建轮询任务 |
| A10 | 采用 | 文档以 MCP 2026-07-28 为明确新基线 | 仅实现所选现行协议，不提供历史兼容配置 |
| A11 | 采用 | 私有桌面适配隔离且默认关闭 | 升级失配可诊断，不自动启用调试器 |
| A12 | 采用 | bun:sqlite、WAL/FULL、单进程受控写连接 | 原子台账；同步停顿与实际 SQLite 版本必须验收 |
| A13 | 采用 | 类型化引用与固定预览 | 调用方选择目标，服务校验并拒绝漂移 |
| A14 | 采用 | 操作台账与输入/出站分开 | 超时按原键查回，不能靠猜重发 |
| A15 | 采用 | 多贡献明确合并 | queue 优先、上下文取小、每贡献独立过期 |
| A16 | 采用 | submitting 事务为提交点 | 暂停并发与崩溃窗口可解释 |
| A17 | 采用 | 人工结案仅允许不重发 | operator-only、manual，不伪造成功 |
| A18 | 采用 | 首轮不承诺跨 IM hop 证明 | 外部平台丢来源链时不能凭正文恢复 |
| A19 | 采用 | native 查询快照与 live 事件分离 | 查询不触发，也不吞实时事件 |
| A20 | 采用 | 用户指定前期 Eliscript，产物为 ESM，Bun 为服务宿主 | 维护 `.eli`，不以另写 JS/TS 业务层替代；不依赖 Native/WASM 服务 |
| A21 | 采用 | 首期 macOS arm64、UDS 本地控制与 stdio MCP 代理 | 无默认 TCP 监听，CLI/MCP 不拥有业务数据库 |
| A22 | 采用 | 官方 MCP SDK v2 + Ajv 8 严格 schema | 复用字段目录，协议基线不变，不静默强转参数 |
| A23 | 采用 | Lark 国际版（user）/Telegram × OpenCode/Pi | 首条闭环 Lark→OpenCode→Lark，首批仍需四组合 |
| A24 | 采用 | 首期 created 文本、current/queue/hold、local 查询、单条回复 | 未启用能力明确 unsupported，保留完整领域合同 |
| A25 | 采用 | 操作员/可信宿主启动身份与 managed profile | 登记不创建进程；共享凭据不能证明当前会话 |
| A26 | 采用 | 目录式生成 ESM 发布包、文件凭据和 ESM 嵌入面 | 无运行期编译器、无自动后台安装或 C ABI 承诺 |
| A27 | 采用 | 工具类型/运行实例/原生会话/登记目标分层 | 未登记/未订阅会话也可查，agent_id 不作为工具父节点 |
| A28 | 采用 | 有界本地目录与字面搜索 | B-tree/FTS5 候选加精确复核，无 AI；覆盖/新鲜度与分页分开 |
| A29 | 采用 | session.send 免订阅，TargetRoute 共用队列 | 不伪造 IM Event/订阅，unknown 不可跨入口绕过 |
| A30 | 采用 | 显式 instance.start/session.create 与生命周期核对 | 获准 profile、空会话、幂等/epoch；查询和发送不隐式启动/恢复 |
| A31 | 采用 | CLI/MCP/API 同一业务层，无 IM 操作界面 | IM 仍只作事件源/目的地，不解析管理命令 |
| A32 | 采用 | 首期 OpenCode existing + 显式 managed serve/创建 | Pi 保持 profile 初始会话，拒绝切走已绑定 RPC 的 create |
| A33 | 采用 | 仅优雅停止自有 managed 实例 | drain/归属检查，不停止借用实例或强停原任务 |
| A34 | 采用 | 搜索稳定键续扫与 catalog_seq 逻辑快照 | 有界扫描可分页且不承诺全局时间排名；撤权/删除优先，无长读事务 |
| A35 | 采用 | 统一实例 gate、slot 栅栏与安全停机 | direct/订阅/create 同提交门禁；manual 不证明旧进程退出，队列 hold 不阻塞 drain |
| A36 | 采用 | 稳定 session_key 与可续签短期引用分离 | 定点刷新/probe、过期查回、Pi 初始会话均无需重复 start/create |
| A37 | 采用 | 创建到订阅的可信接线显式保留 | 独立 recipient/工具作用域由部署面配置；创建者绑定不变，无隐式凭据复制 |
| A38 | 采用 | MCP低层Server+serveStdio、单一业务校验 | 同目录投影严格schema，业务错参由DJ统一envelope返回；catalog摘要不符拒绝，不靠SDK高层默认错误格式 |

无 AI 是用户明确约束，技术选型和扩展不能将其重新列为候选。整体审阅及修订依据见 [设计审阅](design-review.md)。

## 待取得的证据与后续事项

| ID | 事项 | 当前可推进部分 | 决定/证据需要 |
| --- | --- | --- | --- |
| O01 | 方向已定，依赖/构建证据待锁定 | Eliscript/ESM/Bun、目录包、ESM 核心；见 technical-stack.md | 完整编译器/产物哈希、精确依赖锁定和 T38–T40；不再等待选语言 |
| O02 | 范围已定，实机证据待取得 | macOS arm64，Lark 国际版（user）/Telegram × OpenCode/Pi；见 release-scope.md | 未来实现后的授权账号/目标、四组合与 T41–T45；不自行新建账号 |
| O03 | 每个桌面工具 idle 唤醒、重启和 lookup 保证 | 保留接口和错误，其他公开托管方式可独立设计 | 对相应安装版本的真实测试，尤其仅有 steer 证据的目标 |
| O04 | 远程部署、TLS/OAuth 与多租户公开服务 | 本地单操作员、多主体权限与端口 | 远程产品范围、部署环境及认证方式 |
| O05 | 历史 MCP 客户端兼容列表 | 新版本明确契约 | 目标宿主实际协议、SDK 与 conformance 测试 |
| O06 | 首期裁剪已定，后续媒体能力保留 | 首期 created/单文本/附件元数据；其他明确 unsupported | 扩展授权与各平台真实证据；不阻塞首期 |
| O07 | Lark user 授权/增量收件实证待取得 | CLI-only，国际版固定 user OAuth；消息事件仅 bot，当前采用 DJ 有界轮询 | 真实 OAuth/可见 chat/thread、分页恢复/延迟/gap/回复证据；不回退 bot |
| O08 | 施工文档已齐，代码与运行用例待授权 | construction/plan、contracts、test-plan 和根 TODO 已绑定精确目标文件/签名/依赖/测试入口 | 本轮只文档；获得实现授权后按 S1 写齐测试、S2 全实现、S3 集中验证 |

当前不因为 O 项而要求用户立即逐项回答；本轮先交付可审阅设计。未获得实现授权前不创建运行时、脚本、数据库、服务配置、测试 Agent 或真实订阅。

本轮用户要求技术选型与全流程设计，未授权实现。采用与首期建议的完整依据见 [技术选型](technical-stack.md)、[首批范围](release-scope.md)和[启动到回复](startup-to-reply.md)。

追加的统一会话控制及整体复审已纳入 Q14–Q18、T46–T72、R15–R28；正式操作与能力范围见 [Agent 控制面](agent-control-plane.md)和[首期适用矩阵](release-scope.md#首期统一能力与验收适用矩阵)。本轮仍无实现授权；索引/生命周期原生能力和精确依赖必须在实现阶段验收，不能将接口存在当成全部工具已支持。

本轮已进一步交付 [施工手册](construction/plan.md)、[接口落实](construction/contracts.md)、[测试实施方案](construction/test-plan.md)与[唯一 TODO](../TODO.md)，前期语言和首期范围不变。Goal 只保存草稿，依赖/测试/配置文件仍未创建，不把 O08 的文档准备完成等同软件实现完成。

开工准备进一步固化到 [readiness](construction/readiness.md)、[逐操作字段](construction/operation-catalog.md)、[用例卡](construction/case-cards.md)。SDK 2.3.1/Ajv 8.20.0 等是已查发布元数据的选定版本，不是已安装/验证依赖；当前 Bun1.4.0、目标1.4.4，Eliscript候选包缺同源证明。实际工具链/锁文件、测试源码和运行证据继续按原I/A推进，该轮未启动Goal；当前运行状态见 status。

本次准备复核覆盖旧 bot-only 选择：配置根为 `~/.dj`；首期 Lark 国际版使用用户 OAuth，由 DJ 自己有界增量读取后推给 Agent。旧 consumer 证据保留为历史，不能混用为 user 接入证据；准确字段/窗口/限制见 [IM 接入](adapters/im.md#lark-user-poll)。
