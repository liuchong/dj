# 首批接入与发布范围

2026-10-27 补充执行边界：缺少运行中 AI 进程时不询问、不等待，也不启动替代 CLI；持续完成全部已授权业务实现、接线、打包和说明。只有确实没有实例的工具才把真实验收留给用户；有实例时由本侧解决接线并实际验收，不能因接收扩展尚未加载就停止。

核心交付要求是：IM 消息到达后，DJ 根据现有订阅中的 ID、名字等定位线索，核对并主动通知原始订阅会话，消息经本机已有实例的 IPC/socket/API/MCP 送达，不经 CLI 参数传递。名字不是替换目标的依据。创建空对话仅为可选增强，没有创建接口不妨碍已有会话支持；没有原会话通知能力则不能报告该工具核心接入完成。

## 当前交付优先级（2026-10-26 用户调整）

2026-10-27 用户继续范围：在 Codex/Cursor 已有交付基础上，将原首期的另外两项 OpenCode、Pi 推进到同样的核心可安装、可使用程度，随后结束本轮 Goal。每项核对已有实例/原会话的发现、免订阅直发、订阅通知与独立身份回复，以及可提供的 Skill/API 使用入口。公共模块证据复用，只验证工具自身差异；其他 IM、完整性能及创建/启停等可选功能验收留到后续，不重跑全套。不得用新 Agent CLI 进程替代已有接收方；Pi 的普通 TUI 缺少原生收件口时必须先补现有进程内的接线，不能沿用旧 managed RPC 冒充。

当前交付先跑通 **Codex、Cursor** 的主要业务：精确发现与选择会话、注册目标、直接发送、订阅转发及回复原话题，完成可使用的项目交付。先完成这两个客户端所需的业务实现，再集中执行必要验证；不为每个 AI 工具铺设或重跑完整验收矩阵，不继续以新增测试替代业务施工。

OpenCode、Pi 及其他工具保留已有实现和证据，专项接入验收安排在本次交付之后，不作为本次 Codex/Cursor 业务交付的前置条件。RC1–RC3 性能优化候选停止推进；既有吞吐未达标结果保留并如实说明，不再以连续诊断和性能复测代替主要业务实现。授权、幂等、消息不串线、原目标不替换及发送失败不盲重试等正确性要求继续执行。

本文下方旧“首期”矩阵保留为历史设计范围；与本节冲突的工具优先级和验收执行顺序，以本节为准。尚未实现或跑通的 Codex/Cursor 能力不得标为已支持。

日期：2026-10-23。以下是结合轻量、公开协议和多对多需求作出的设计建议，作为当前首期基线；不是用户逐个平台指定，也不是已支持列表。尚未连接账号、启动目标或执行真实验收。

## 明确范围

首期运行环境采用 macOS arm64、本机单操作员与多个受约束 Agent 主体；Bun/工具链见 [技术选型](technical-stack.md)。Linux、Windows、远程公开服务和跨机器凭据分发不进入首期兼容承诺。

| 接入 | 首期模式与用途 | 支持边界 / 进入条件 |
| --- | --- | --- |
| Telegram | 专用 bot，getUpdates 长轮询 + Bot API 文本回复 | 不启 webhook；由 DJ 在入库后推进 offset；仅已配置且核验可见的会话/话题 |
| OpenCode | 已有本地 HTTP server/session；另可显式启动获准 managed serve profile | 原目标不被替换；运行实例内可创建新空会话；查询/发送不自动启动，不承诺桌面 Tab 同步 |
| Pi | 操作员批准的长期 managed RPC 子进程 | 固定工作区/资源/会话持久化配置；原生 session ID 核验后登记；不接管任意既有 Pi TUI |
| 调用入口 | CLI、本地 API、stdio MCP 和自包含 Skill；CLI 为两个 Agent 的共同最低入口 | 无 IM 操作界面；OpenCode 可在独立受信作用域配置 MCP；Pi 首期用 CLI |

Lark 用户身份适合验证当前主要聊天入口；Telegram 提供 DJ 自控接收确认的对照路径。OpenCode 验证公开协议连接已有会话，Pi 验证隔离的托管进程协议；两条路径共同检验 AgentPort，避免仅证明一个工具的特例。协议依据见 [OC01、PI01–PI03、IM01](references/official-sources.md)，接线全过程见 [流程](startup-to-reply.md)。

本轮追加 [统一 Agent 控制面](agent-control-plane.md)也进入首期：跨已配置/获准来源的工具/实例/会话目录、字面检索、免订阅直发、OpenCode 空会话创建、profile 显式 start/自有 managed stop 及生命周期核对。Pi 首期只创建/恢复 profile 的初始会话，不以 RPC new_session 切走已有绑定。其余工具的 scope/接口已设计，但没有适配证据时明确 unsupported/partial，不把“统一入口”写成已支持整台机器所有工具。

## 闭环顺序与多对多判定

首条验收链选择 Lark → OpenCode → Lark。首批完整范围仍为两 IM、两 Agent，不能把一条闭环通过当作首批全部完成。后续实现仍遵守全设计、完整测试用例、全实现、最后集中验收；这里的顺序是最终验收定位顺序，不授权边写边验收。

最终测试建立四条独立订阅：Lark 用户来源 → OpenCode、Lark 用户来源 → Pi、Telegram 来源 → OpenCode、Telegram 来源 → Pi。相同来源可投两个目标，每个目标也能收到两种来源，回复分别留在各自原始对话。两个 IM/两个目标之间的四种组合全部留独立证据；不要求 Agent 之间互发、不做竞争消费或任务编排。

每种组合至少覆盖：来源获准、目标 idle、busy queue、正文读取引用、原话题回复与 accepted/started/回合结束的独立记录；未知结果、重启和重复事件按所属适配器追加故障验收。工具只完成本地调用、模型没有调用 reply，或 outbox 没有原生消息 ID，都不能写成“完整收信回复闭环通过”。

## 首期功能裁剪

- 接收仅 `message.created` 文本；来源准确保留连接、作者、原消息和话题。非文本保留必要元数据和 unsupported 诊断，不 OCR/摘要、不当作空文本触发。规则引擎的 edited/deleted 合同保留，但这些首期连接的订阅预览返回 unsupported；不承诺察觉源端未推送的删除。
- 规则采用既定确定性谓词；默认只接所选范围内的人类来源，机器人链需另行显式授权。首期运行配置采用 busy=queue、offline=hold、context=current；steer/recent 不作为首期发布能力，预览明确拒绝而不静默替换。
- 对话列表来自操作员允许范围与核验结果，complete 只指该范围的快照列完；不声称能枚举 Telegram bot 的所有聊天。需要精确原生地址时走 conversation.resolve，不按名称试发。
- `message.list/search` 首期只查 local 入库语料；native corpus 返回 unsupported。精确地址验证所需的平台元数据读取不等于开放 native 历史检索。附件仅元数据，无下载/上传、富文本编辑、反应或撤回功能。
- 首期发送/回复只发单条纯文本。保持统一 16384 UTF-8 字节上限，并在受理前按平台的更低字符/字节限制检查；超限明确拒绝，不摘要、不截断后冒充完整发送。多片 outbox 合同与 T34 保留为后续能力，首期不对外声明已支持。
- 身份、登记、预览/订阅、暂停/恢复/删除、操作台账、输入与出站状态/核对/安全取消、operator-only 不重发结案都属于首期。不能因裁剪平台功能而裁掉 unknown、权限撤销或幂等。
- 自动把 Agent 的最后回答发回 IM 不在首期；Agent 使用 CLI/MCP 的 `message.reply` 明确提交。输入提示只告知可回复能力，不自动授权所有未来消息外发。

## 首期统一能力与验收适用矩阵

“启用”表示未来首期必须交付的设计范围，当前没有实现。CLI/MCP/API 同时投影全部启用操作；宿主可经 CLI 使用，不等于所有 Agent 都是 MCP client。以下区分正向验收、拒绝验收与保留场景，避免以整个 T 编号一刀切宣称通过。

| 能力 | 首期正向范围 | 首期必须明确拒绝/保留缺口 | 主要验收 |
| --- | --- | --- | --- |
| 工具/实例/会话目录 | 已配置 OpenCode/Pi；精确 key/实例/工作区/多工具过滤、get/resolve/probe | 未配置范围无机器全盘发现；无 desktop-open 证据不伪造；其他工具 unsupported/partial | T46/T48/T50/T63/T71 |
| 元数据/正文搜索 | 本地授权索引、字面精确复核、稳定键分页、定点 refresh/continuation、版本快照 | 无 AI/向量/相关度；search 时间排序拒绝；未采集正文不算无命中 | T47/T48/T57/T59–T61/T69 |
| 免订阅 Agent 输入 | 单个未登记或已登记精确会话、纯文本、queue/hold、独立 direct 台账和共享 route | 不群发、不自动启动/恢复/注册，不附 IM 历史；不截短后发送 | T49/T50/T54/T62/T72 |
| 启动/创建/停止 | 预配 OpenCode/Pi start；OpenCode 实例内空 create；自有 managed 安全 stop | Pi 同 RPC create unsupported；不停止 existing，不强停，不用 manual 结案释放未知 slot | T51–T53/T58/T64–T66/T68 |
| 新会话接入订阅 | 操作员预配 recipient/工具作用域并核验后登记、preview/create | create 不自动配置凭据/Skill/MCP，不改绑创建者；未接线不报回复可用 | T33/T43/T44/T67 |
| IM 订阅与回复 | 两 IM × 两 Agent、created 文本、确定性规则、current/queue/hold、local 查询和单条回复 | edited/deleted、steer/recent、backfill、native IM corpus、媒体操作、多片出站均不启用 | T01/T06/T41/T42；下述分支表 |
| 共同正确性 | 权限撤销、三入口幂等、unknown、人工不重发结案、容量/公平调度、停机恢复 | 无 source replay/lookup/原生 fencing 的能力如实报告，不虚构保证 | T08–T21/T25–T29/T31/T33/T35/T38–T40/T45/T55/T56/T65/T70 |

本矩阵是全首期统一发布门禁。每个复合场景在实现阶段拆出稳定子用例后归档，至少如下：

| 原场景 | 首期执行并留证据 | 保留待扩展，不能标运行通过 |
| --- | --- | --- |
| T07/T30 | queue/current、不同 TTL/grants 的合并与撤销；显式请求 steer/recent 的 unsupported | 正向 steer/recent 与跨策略合并 |
| T10/T22 | 缺原生去重/版本/运行权限时的明确限制或失败；只测首期适配器 | 其他厂商正向适配、稳定 dispatch key 保证 |
| T23/T44 | OpenCode/Pi 的 CLI Skill 采用；MCP 代理协议另测、宿主兼容有证才声明 | 其他客户端采用与 Pi MCP 宿主能力 |
| T24/T32 | created、local 查询、分页、截断三值判定；未启用事件/native corpus 拒绝 | edited/deleted、native IM 历史的正向路径 |
| T34/T36/T37 | 多片请求受理前拒绝；外部正文隔离；目录明确删除导致索引/读取失效归 T61 | 多片恢复、IM 删除通知与原文投递 tombstone、native IM 快照和 live 联动 |

每个首期子用例记录 enabled-positive / required-rejection / deferred，不以父编号通过掩盖 deferred。启动/创建与订阅共享 gate 的冲突验收、无 IM 闭环、四组合回复、性能和依赖门禁均不可省略。接口存在、空会话创建成功或消息受理不能代替这些证据。

## 各协议的可靠性边界（平台说明）

### Lark 国际版用户身份


历史 bot consumer 合同还包括 ready marker、stdin 生命周期及提前 ACK 风险；这些不属于当前 user 轮询实现/验收。当前 user 也只从 DJ 持久入库开始提供内部保证，不能拿历史 consumer 的 ready 或接收结果证明 user 接入通过。

当前首期采用 Lark 国际版、用户 OAuth、DJ 自有有界轮询；App 凭证不等于用户授权。CLI 1.0.76 的消息事件仅支持 bot，不能把 `--as user` 硬加给 event consume。2026-10-23 只读核对消息/话题列表支持 user、分页和原消息回复；完整轮询与恢复合同见 [IM 接入](adapters/im.md#lark-user-poll)。内部读取不开放公共 native 历史查询、不把旧历史触发工作；收信延迟及源缺口单列，不降低四组合验收。

### Telegram

仅使用 getUpdates，启动先检查既有 webhook；存在则阻止此连接并报告，不自动删除或丢弃 pending updates。将每个已处理 update 的事件或拒绝/不支持诊断与连续游标一并提交后，才用更高 offset 进行下一次请求；崩溃后未提交批次仍从旧 offset 取。保留源平台有限缓存与断线 gap 边界。发送响应丢失后无已证原生查询/幂等保证就 unknown，不靠重发换消息 ID。[Bot API](https://core.telegram.org/bots/api#getupdates)

### OpenCode

健康/版本、项目/namespace、session 与事件流先核对，再对指定 session 异步提交。204 只算输入受理，不是开始或完成；messageID 只是关联候选，不在未验证前当作原生去重键。busy 先在 DJ 排队，原生竞争导致状态变化按实际协议结果处理。控制和回复工具使用同一受约束 recipient 身份，不能用通用项目级 MCP 凭据推断是哪一会话调用。[Server](https://opencode.ai/docs/server/)

### Pi

RPC 每条命令唯一关联 ID，持续解析 JSONL 响应与事件；get_state 获取真实 sessionId 等事实。持久 session/profile 是操作员配置，不使用临时无 session 模式作为长期目标。`started/queued/handled` 分别记录，handled 不证明模型运行。busy 等可靠稳定状态再提交；不靠最后一条文本判断 idle。子进程退出后原会话不会自动被一个新会话替换，恢复需要 profile 明确授权且核验同一身份。[RPC](https://raw.githubusercontent.com/earendil-works/pi/main/packages/coding-agent/docs/rpc.md)、[命令](https://raw.githubusercontent.com/earendil-works/pi/main/packages/coding-agent/docs/rpc-commands.md)

## 版本与范围证据



## 后续接入顺序

下一项建议 Codex 公开 App Server managed 方式，再考虑 Claude Code 的公开 Channels/托管路径；Cursor ACP、agy stream-json 后续按需求排序。已有 Codex/Antigravity/其他桌面私有接收器保持独立实验且默认关闭；Slack、Discord 与剩余 IM 不进入首期。公开协议有文档也仍须逐版本验证，不能为了凑平台数量略过 idle 唤醒与回复工具的真实接线。
