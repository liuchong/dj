# DJ 唯一施工与验收 TODO

## 当前增量：Claude Code / Antigravity 本机接线（2026-10-27）

按用户最新范围，以 DJ 与既有 AI 工具的通信为验收目标；模型额度及模型实际完成任务不作为接线门禁。

- [x] 完成 Claude Code 原生 UDS 与 Antigravity 本机 HTTPS 适配、生产装配、进程/会话/工作区围栏及私有配置命令；不启动替代 AI，不使用云端控制。
- [x] Antigravity 原会话经公开 resolve/probe/discover/register/send 接通，实际读取主 Skill/clients.md 并调用独立 recipient 的 status/whoami；同键重放保持一条 direct delivery。
- [x] 一条授权 Lark 用户消息经订阅投递至同一 Antigravity 会话，持久 accepted，并有原生输入读回。随后模型返回 429 额度耗尽；不重发、不换模型，不将其当接线失败，也不声称产生了 IM 回复。
- [x] Claude Code 本机协议夹具覆盖 native idle、delivered、held、refused、迟到回执和无 ACK；配置、进程身份及有界消息读取已实现。
- [ ] Claude Code 实际会话收件：本轮只有 Claude Desktop 及其辅助进程，无运行中的 Claude Code/原生 session registry。按既定规则完成实现和打包，不启动替代 CLI、不等待用户开实例；实际收件留到该实例存在时。
- [x] 最小保护回归覆盖新工具输入编码、原生 ID/思考内容隔离、工作区严格匹配和配置传输互斥。未重跑全套功能或性能。


## 当前继续：原计划其余 Agent（2026-10-27）

范围为 OpenCode、Pi 达到 Codex/Cursor 当前核心可使用程度；其他 IM、性能、创建/启停等可选验收后置。最新要求明确：有运行实例的工具由本侧完成接线与真实验收，只有没有实例的才留给用户，不等待或启动替代 Agent。

- [x] OpenCode 已有 Desktop 原会话：保持 opencode-go / DeepSeek V4.1 Flash，经公开直发受理与原生回复、同键一条 delivery、主 Skill/clients.md 实际摘要、独立 recipient 的 status/whoami 和原消息订阅回复核对均通过。与 Pi 共用一条授权 Lark 人工刺激，平台读回证实各自回复原消息。
- [x] Pi 已有 TUI 原会话：原生扩展已临时加载进原进程，模型和原生会话均未替换；真实 socket 接收、公开直发/同键去重、主 Skill/clients.md 摘要与独立 recipient API、订阅消息及原消息回复均通过。临时 Inspector 已关闭，接收扩展留在当前 Pi 生命周期内可用，未修改持久客户端设置。
- [x] 验收收尾发现并修复服务停机调度：请求停机后不再先运行 tick 补排观察任务，由 drain 处理既有工作。原控制器收尾失败与受控取消记录保留；同库修复恢复后 4 条 accepted 均排空、0 新输入/新出站、正常退出，socket/租约/claims 清理。新 T45 延迟观察停机保护 7 断言通过。

本轮自动施工及已有实例的核心真实验收已完成。最终运行包与使用入口见 [交付与使用](docs/delivery.md)。原全矩阵、实际 MCP/Hook 配置启用、其他 IM 与性能未验事实保留，不重新启动全套验收。


## AI 调用面补齐（当前继续项）

- [x] GEPO：共用操作目录、权限和幂等；同路径 GET 用法/POST 调用，认证后的树形发现。build185 集成 22 断言与 build187 后置保护通过；CLI/MCP/API/GEPO 同键仅一笔投递，不代表各 AI 已安装配置。
- [x] Skill 安装与接线程序/说明：完整通用 Skill、8 个目标目录、显式 scope、冲突保护与 MCP 配置生成/GEPO 指引。build190 集成 39 断言、build192 后置保护 32 断言；目录包仓库外安装通过。只验证 Codex/Cursor 隔离目录，没有修改实际客户端配置；模型实际加载采用仍在真实交付项中，不把其他工具矩阵变为前置。
- [x] 订阅提示词与任务装配：instruction_policy 随订阅版本保存，提交前逐贡献重检并装配 prompt/task_template/task；正文不扩权，无表达式或脚本执行。build208 集成 27 断言、保护 29 断言通过，旧订阅/原快照兼容，超限阻塞且零原生输入。真实模型任务执行与 Skill 采用仍单独记录。
- [x] 订阅主动消费：delivery_mode=pull、subscription.pull/ack、独立持久待办与限时领取、跨重启幂等、按接收主体授权；不创建原生投递。build214 集成 31 断言、build218 的 MCP/GEPO 集成 46 断言、build220 后置保护 46 断言及原推送回归 27 断言通过；新目录包仓库外入口已检查，不代表真实 AI 已采用拉取。
- [x] Codex / Cursor 本机回调：dj hook pull 和 skill hooks 分别处理 UserPromptSubmit / stop，原会话与 recipient 绑定核对、固定回调幂等键、一项领取、显式 ack、Cursor 最多一次续轮。build230 的 T18 CLI/UDS 集成 99 断言、build232 后置保护 65 断言通过；只生成配置，不自动启用客户端 Hook。其他工具保持公共调用指引，专项适配后置。
- [x] Skill 只读采用：Cursor 原调试会话已读取主 Skill、算出一致摘要，并用独立身份调用 service.status/agent.whoami；Codex 新专用调试对话已读取主 Skill 和 clients.md、算出两份一致摘要，并真实调用相同两项查询。Codex 测试服务仅开放这两项，正确返回 unbound，未自行登记、订阅或发送；服务/租约/socket 已清理。两者不混同于 MCP/Hook 配置已启用；旧失败和原订阅会话证据保留。
- [ ] 实际客户端配置与回调采用：MCP 配置/Hook 尚未实际启用；Cursor 原对话的 clients.md 文件工具拒读记录保留。已有安装程序、配置生成和使用说明不替代实际启用证据；不再把自写临时调试限制当成用户未授权或反复索要相同授权。
- [x] Cursor 按 ID 加载既有本机会话：限定 local、非归档、精确工作区与既有 ID，查询不提交消息，引用按请求释放，保留信任/epoch 检查。build250 集成 137 断言、build252 保护 39 断言通过；原调试对话真实读回通过，不代表新建会话或全部客户端采用。

## 当前交付主线（2026-10-26）

当前先完成 key/secret 驱动的专用机器人接口；操作员本人通过 lark-cli 给机器人发送消息，检查订阅前后及原会话回复。AI 接入只用已有客户端接口，Cursor 使用 Desktop；没有专用授权的账号不用于调试。

当前密钥接口业务实现、接口集成验收和关键解析保护性单测已完成。国际版专用机器人真实收信与公共 message.send 发回消息均已取得平台读回；无订阅时零 Agent 投递已确认，临时服务正常停止。此前托管 CLI 接线和本地验证保留为协议试验，不算已有客户端接入；此前真实 Codex 的订阅与模型显式原会话回复属于托管 CLI 试验；Codex 原会话通知及独立 recipient API 原消息回复已真实跑通，Cursor 显式 native_api 已有客户端链路也已通过；该通道已补齐 DJ 按需开启/关闭原进程 Inspector，不等同于 Bridge 已启用，不恢复性能诊断或全工具矩阵。

- [x] 接通 Codex 已有实例的原订阅会话通知：同一原会话经生产 Desktop IPC 接受直发并读回模型标记；国际版 Lark 专用机器人消息经真实订阅送达同一会话，持久投递为 accepted，原会话读回匹配信封。没有新建会话或启动 Agent CLI。随后已通过独立 recipient 调用 DJ API 回复原消息，平台读回确认精确 reply_to 与单条机器人回复。
- [x] Codex 公开免订阅直发：当前目录包以无 IM、无 Agent 登记、无订阅的新服务，经 session.resolve/probe/send 通知同一原调试会话并读回唯一模型标记；同键重放仍为同一 delivery。持久 origin=direct，event_id/agent_id/reply_context_id 均为空；events/contributions/outbound/claims 均为零，服务/租约/socket 正常清理。证据 direct-session-265.json 与受控终态；不将此前端口级通知冒充此公开入口验证。
- [x] Cursor 公开免订阅直发：同一目录包以无 IM、无 Agent 登记、无订阅的新服务，经 session.resolve/probe/send 通知原 Cursor 调试会话并读回唯一模型标记；同键重放只有一条 direct delivery，event_id/agent_id/reply_context_id 为空，events/contributions/outbound/claims 均为零。服务/租约/socket 清理，Inspector 端口关闭；证据 direct-session-266.json 与独立终态。没有替换原会话、启动 Agent CLI 或改业务代码。
- [x] 接通 Cursor 已有实例的原订阅会话通知：按订阅保存的 ID 和名称等定位线索发现目标、核对原实例与会话，通过本机 IPC/socket/API/MCP 主动投递；不通过 CLI 参数传消息，不用同名或新建会话替代。生产 native_api 端口已按原会话完成真实 Lark 订阅通知与回复；显式配置 manage_inspector 后由 DJ 按需开启和关闭原进程 Inspector；提交返回即关闭，原会话继续工作，不需要操作员逐条开关。Cursor→DJ 的 MCP/API 不依赖 Inspector。
- [x] 国际版 Lark 专用机器人→原 Codex 会话→独立 recipient DJ API→原消息回复：接收模型真实调用 message.reply/outbound.get，平台发送者、精确 reply_to 与唯一回复已核验；未启动 Agent CLI、未改全局客户端信任或 MCP 配置。
- [x] 按已有客户端接口跑通国际版 Lark 专用机器人→原 Cursor 订阅对话→独立 recipient API 显式回复原消息：真实发送者/机器人/原 reply_to、原不可变 binding、单条 accepted delivery/outbound 及 claims0 均核对；临时服务已安全停止，Inspector 已关闭；后续自动开关/取消清理/保留既有端口的真实验证也已通过。原控制器停止观察超时的 exit1 保留，后续租约/socket/native_drained 终态证据单独记录。
- [x] 完成上述链路的精确会话发现、目标注册、直发、订阅转发及原话题回复；Codex 与 Cursor 的原生接收、独立 recipient API 调用及平台精确原消息回复已分别留证。Cursor 使用显式 native_api，不以仍受客户端启用限制的 Bridge/Agent Host 代替；只读历史、socket 存在或空列表均不替代接收证据。后续按 ID 原记录加载已接线并真实读回，不重发已接受消息。已知接口和限制见[本机接口记录](docs/construction/cursor-local-api.md)。
- [x] 本批实现完成后集中做与上述链路直接相关的必要验证：build174 定向集成 115 断言、后置配置保护 31 断言通过，build172 真实 Cursor 订阅回复闭环及后续停止终态已核验；不扩展全工具验收矩阵。
- [x] 完成当前主线真实业务交付：源码已签名推送，运行归档及使用说明已提供；Codex 原生 IPC 与 Cursor native_api 的公开免订阅直发、原会话订阅通知和独立 API 原消息回复均已有真实证据。Cursor 固定版本及 DJ 管理 Inspector 的条件保留；未自动安装、部署或启用客户端配置。其他工具、IM 和性能专项验收按用户要求延后，历史 A01–A20 未勾项不改为通过。
- [x] 提供可取用运行包与集中使用说明：当前目录包的 40 项载荷摘要及执行权限已核对，归档含 manifest 共 41 项，不含凭据、数据库或原始验收资料；未自动安装、部署或启用客户端配置。版本、摘要、启动和限制见[交付与使用](docs/delivery.md)。实际 Skill/MCP/Hook 采用缺口仍按顶部状态保留，不用归档成功替代。

可选增强：通过已有实例接口显式创建空对话，不作为上述核心链路的前置任务。历史创建连接器已打包但已停用；一次性 Inspector 调研已成功创建原生 local 空对话并关闭调试器。这些证据保留，不代表普通 IPC 通知已接通，也不要求重装扩展或继续创建调研。

RC 优化与其他工具完整验收已延后，历史失败和未验事实保持原样。以下 S/I/A 及修复表是既有阶段记录，不得据此恢复已延后的工作。

更新：2026-10-26；S0/S1/S2完成，当前S3。原定施工I01–I30全部写齐，正式验收A01–A20已勾12/20（60%），阶段计数3/4（75%）不代表工时或整体交付比例。最新PO本地组件冻结build115，130输入/578输出，79 unit、849 integration、25 system形成953项组合功能覆盖（非单次全跑）；179/180独立审核及必需断言已闭环。59业务源码/生产/性能产物未变。真实IM/Agent/Skill/资源与完整吞吐、最终签名交付保持开放；RC新批次A已写齐，按当前用户优先级延后，B/C不启动。

入口：[施工手册](docs/construction/plan.md)、[准确接口/字段](docs/construction/contracts.md)、[测试映射与执行](docs/construction/test-plan.md)、[Goal 正文](docs/construction/goal.md)。I=源码/配置写完才勾的施工项，A=实际测试通过才勾的验收项。I01–I30均已写齐并记录声明/消费者，施工勾不代表全部验收；当前S3的真实结果和失败批次见status。真实测试控制器与授权profile仍待核实，不能把本地通过替代真实IM/Agent/Skill采用。
开工直接使用 [依赖/环境与构建配方](docs/construction/readiness.md)、[操作字段表](docs/construction/operation-catalog.md)和[具体用例卡](docs/construction/case-cards.md)。它们补充原手册，不另起进度或改变既定首期。

## 阶段状态

- [x] S0 本轮施工设计文档完成：当前/目标树、基线锚点、D01–D18、接口、完整流程及测试方案。依赖未安装/验证，实现前按 I01 固化。
- [x] S1 完成 I01/I02/I04–I08 的依赖输入、全部测试/验收源码与必要配置准备；未编译、未运行、未预审。
- [x] S2 完成 I03/I09–I30：按依赖写齐首期全部生产实现/接线，逐项标“实现待验”，仍不运行测试。
- [ ] S3 全量实现后集中构建、测试、审阅及逐条验收 A01–A20，修复必要失败，完成签名交付。

S0 勾选只证明文档交付，不证明 S1 的精确依赖已经落盘；S3 要求真实必需证据，不以所有 I 勾选代替。阶段是首期整批的 A/B/C/D，没有把某个模块写完当成提前进入 S3 的授权。

## 施工清单

文件均为计划路径；当前不存在的标“新建”，新文件没有基线行号。D/B 定位详见施工手册，字段和目标符号详见 contracts.md。每项必须完成声明/实现/导入导出/调用接线才能勾。

| I | 写完 | 阶段 / 差异 / 需求 | 准确位置和动作 | 依赖 | 验收 |
| --- | --- | --- | --- | --- | --- |
| I01 | [x] | S1 / D01 / Q12 | 按readiness精确版本/SRI/配置配方新建 package.json、bun.lock、三个eliscript配置、.gitignore；已准备目标Bun1.4.4包、固定源输入清单/摘要与隔离重建配方；npm冻结产物差异如实保留，固定源stage3成品与身份验证留S3/A01，不把准备当构建通过 | 实现授权、B02、readiness | A01 |
| I02 | [x] | S1 / D02 / Q08/Q11/Q13 | 新建 tests/cases.json；按case-cards稳定ID/fixture/断言与test-plan文件/层次，展开T01–T72全部首期P/R及明确D分支/参数/资源/截止；不隐去deferred或计T42组定义为额外通过 | I01 设计 | A02 |
| I03 | [x] | S2 / D01 / Q12 | 已写 tools/build.eli/build-inputs.eli 的 buildEntries 与来源/输出manifest、package入口；host/bun/io.eli/process.eli/clock.eli 提供 createHostPorts 和显式 I/O/单调时钟/归属/取消端口；写齐待S3验证，未构建 | S1 全部完成 | A01/A18 |
| I04 | [x] | S1 / D02 / Q02/Q03/Q10/Q11 | 写齐 unit/contract、identity、rules、state 四个 .test.eli，覆盖严格字段/类型、三值规则、字节和状态；不运行 | I02、D03/D04 契约 | A03/A04 |
| I05 | [x] | S1 / D02 / Q14/Q16/Q17 | 写齐 integration/storage、query、lifecycle .test.eli；真事务/快照/索引/slot/gate/故障用例，不运行；已写齐待最终验证 | I02 | A05/A07–A10 |
| I06 | [x] | S1 / D02 / Q04/Q05/Q07/Q15/Q18 | 写齐 integration/delivery、im、agent、interfaces .test.eli；受控协议对端和三入口台账子例，不运行；源码写齐待最终验证 | I02 | A06/A11–A17/A19 |
| I07 | [x] | S1 / D02 / Q09/Q13/Q17 | 写齐 system/recovery、flows、ownership .test.eli，跨模块恢复/单 owner/监督器/停止竞态，不运行；源码写齐待最终验证 | I02 | A12/A14/A18 |
| I08 | [x] | S1 / D02 / Q01/Q06/Q10/Q13–Q18 | 写齐 e2e/relay、control、skill 和 performance/router、catalog；support/case/fixtures/faults、tools/verify.eli，分层选择器/逐例计时/real 门禁；不启动对端或跑测试 | I02、各测试设计 | A02/A09/A15/A16/A20 |
| I09 | [x] | S2 / D03 / Q10/Q11 | 新建 core/types/errors/limits/rules/states、application/operations/schema；按operation-catalog逐行写operationCatalog/validateRequest/normalizeArgs、固定状态/上限与三值AST | S1、I03 | A03 |
| I10 | [x] | S2 / D04 / Q02/Q11 | 新建 policy/principals/authorize/handles；authenticate/authorize/issueHandle/resolveHandle，精确 target_constraint、recipient、引用类型/当前授权 | I09 | A04 |
| I11 | [x] | S2 / D05 / Q12/E04 | 新建 storage/schema/sqlite/repository；openStore/migrate/transaction/readPage、WAL/FULL/FK、唯一/分页/版本索引、容量/备份 | I09/I10 | A05 |
| I12 | [x] | S2 / D05 / Q07/Q11/Q18 | 新建 application/execute.eli 的 executeOperation；原键先查/同 hash 重放当前可见结果、业务对象/台账同事务、typed resource_refs | I11 | A05/A19 |
| I13 | [x] | S2 / D06 / Q02 | 已写 registry/agents.eli 的 discover/register/rebind/unregister/handleOperation；候选/recipient/同目标校验、复用 route、不清 unknown；消费者已接 Core，见 contracts 的 S2 交接表；实现待验 | I12 | A06 |
| I14 | [x] | S2 / D07 / Q14/Q15 | 已写 catalog/service/snapshots/records 的 querySessions/getSession/resolveSession/probeSession、版本/typed ref/固定 cursor checkpoint；refresh/Core 消费者已写，见 S2 交接表；实现待验 | I12、Agent 端口 | A07 |
| I15 | [x] | S2 / D08 / Q10/Q14 | 已写 search/refresh、acceptRefresh/runCatalogBatch、索引与版本/checkpoint 原子、字面扫描/组内续算、配额/partial/continuation、删除屏障与分批清理；Core/端口/指标消费者已写，实现待验 | I14 | A08/A09 |
| I16 | [x] | S2 / D09 / Q16/Q17 | 已写 lifecycle/service/gates 的 accept/run/reconcileLifecycle、assert/closeGate/releaseSlot、token/epoch/初始 session key、unknown/manual/absence、历史/当前状态；Core/Agent 调度消费者已写，实现待验 | I12/I14 | A10 |
| I17 | [x] | S2 / D10 / Q03/Q11 | 已写 subscriptions/service 的 preview/commit/changeSubscriptionState 与 handler；固定票据、双主体授权、revision/gate/start/cutover、提交点前撤销；原生分发与 Core 消费者已写，实现待验 | I13/I16 | A11 |
| I18 | [x] | S2 / D11 / Q04/Q05 | 已写 ingestion/service/visibility 与 routing/matcher；事件/诊断/游标原子、索引候选、预算续算与决定/贡献/checkpoint 同事务；ACK 与公平调度的 Core/IM 消费者已写，实现待验 | I11/I17 | A12 |
| I19 | [x] | S2 / D12 / Q04/Q15 | 已写 delivery/service/envelope；acceptDirect/planContribution、两 origin、共享 route/序号、独立 TTL/当前 grants、本人贡献取消与最小撤权投影；I20 提交及 Core 消费者已写，实现待验 | I16/I18 | A13 |
| I20 | [x] | S2 / D12 / Q05/E03/E04 | 已写 delivery/scheduler 的 claimRoute/beginSubmission/recordReceipt/dispatchRoute/reconcileDelivery/observeDelivery；提交前 gate/idle/授权/全部有效贡献、冻结信封/ReplyContext、unknown 与原 attempt；Core 调度、恢复和原生消费者已写，实现待验 | I19 | A14 |
| I21 | [x] | S2 / D13 / Q13 | 已写 adapters/im/lark-cli、telegram 工厂；固定 user/profile、冻结窗口/分页事务与共享预算器、持久 offset/webhook 拒绝、created/单条原话题回复；配置/Core 的 watch 初始化、全局 limiter、逐 update 提交后 ACK、健康/停止消费者已写，实现待验 | ImPort、I18、D15 签名 | A15 |
| I22 | [x] | S2 / D14 / Q05/Q14–Q17 | 已写 adapters/agent/opencode-http、pi-rpc；HTTP/JSONL 查询/probe/输入/观察及 managed 生命周期；Core/profile 实例消费者及 Pi get_entries 原生身份、OpenCode 原关联 ID/managed 就绪、安全 drain 已写；实现待验 | Agent 端口、I14–I16/I20 | A16 |
| I23 | [x] | S2 / D15 / Q07 | 已写 messaging/service 的连接/地址/本地消息查询、queryMessages/acceptOutbound/dispatchOutbound/reconcileOutbound、单文本 outbox 与 EchoGate；权威分组/Core/原生精确地址核验和结果投影消费者已写，实现待验 | I12/I20、ImPort | A17 |
| I24 | [x] | S2 / D16 / Q09/Q12 | 已写 service/config/ownership/recovery 与 policy/registry：严格私有配置、唯一 owner、恢复台账/slot/unknown 再开 intake、主体不复用；可信 policy reload 与 SIGHUP 接线。实现待验 | I11–I23 | A18 |
| I25 | [x] | S2 / D16 / Q12/Q17 | 已写 service/core/runtime/projections/main 和 library：ports/handler 装配、公平有界 jobs、无导入启动副作用、恢复/安全 drain、容量与 PASSIVE checkpoint/保留维护。实现待验 | I24 | A18 |
| I26 | [x] | S2 / D17 / Q18 | 已写 interfaces/client/api：callService/handleApiRequest、私有 UDS/当前身份/请求预算/目录摘要握手、统一 execute 与丢响应 unknown，无影子库。实现待验 | I12/I25 | A19 |
| I27 | [x] | S2 / D17 / Q07/Q18 | 已写 interfaces/cli/mcp、application/help：runCli/runMcp、SDK Server+serveStdio、同目录 tools/list/strict schema、业务参数原样代理/统一错误/逐操作帮助、EOF 不撤销台账。实现待验 | I26 | A19 |
| I28 | [x] | S2 / D18 / Q02/Q06/Q13 | 已写 config/service.example.json、client.example.json 和更新后的 skills/dj：独立 recipient/精确 target/grants、真实运行时和 typed ref/原键调用规则。没有安装 Skill 或采用证据，实现待验 | I21/I22/I27 | A06/A20 |
| I29 | [x] | S2 / D18 / Q08/Q12 | 已写 tools/package.eli、bin/dj、packaging/runtime.md/launchd.example.plist 与构建输入接线：固定 runtime ESM 目录包、摘要/许可证/source map、编译器不进运行闭包、前台安全停止。尚未打包、安装或加载服务，实现待验 | I25/I28 | A01/A18/A20 |
| I30 | [x] | S2 / 全 D / Q01–Q18 | 装配注册/导出、每操作分组与 capability、manifest/维护输入和源码位置已写，声明/消费者见 contracts 的 S2 交接表；实现待验，下一阶段统一构建/审阅 | I03/I09–I29 | A01–A20 |

## 验收清单

最近完成验证的业务为repair65，build69已核对114输入/526产物零漂移；unit26完整75/75、integration38其余844项加integration41的T31定向通过、system19完整25/25，组合945项功能覆盖成立。66→68与68→69仅T31.cancel-before-submitting内部夹具恢复边界修正，逆向摘要证明其他用例/共享函数未变；原始失败记录保留。performance21独立进程3/4通过，route-load在70122.717208ms负载窗口内部截止，6000事件/60000输入/FULL/100事件每秒门槛未达。以下保留build69组合证据；受L直接影响的A01/A05/A11/A12/A14/A19已恢复待验，未受影响条目的旧证据继续保留，完整性能、真实资源及最终交付仍开放。

每项“实测”均在 S3，先确认前置输入/所选子例，再按 test-plan 的确切命令执行；真实组必须具备当前授权测试 profile。证据统一 `.local/acceptance/<run_id>/` 的 manifest、JUnit、timing、脱敏回执/归属及汇总，运行后在同一行补 run_id/子例/结果，不另造全套 checkbox。

| A | 通过 | 需求 / I / T 入口 | 前置、输入与操作/环境 | 明确通过条件 | 实际结果/证据 |
| --- | --- | --- | --- | --- | --- | --- |
| A01 | [x] | Q12 / I01/I03/I09/I29 / T38 | S2 完成，固定编译器/依赖；build:tools → buildEntries all，再 integration/interfaces 的互操作子例 | `.eli` 多入口/依赖/false/null/缺失/UTF-8/Seq 保真；生产包可导入且不携编译器/测试闭包，无 JS/TS 重写 | 当前build75：unit31完整75/75、integration46完整845/845、system24完整25/25覆盖本项本地必需用例；114输入/526产物无漂移，59业务匹配repair70，全部guard清理完成。原始失败保留；真实范围由未勾项约束。 |
| A02 | [x] | Q08/Q11 / I02/I04–I08 / 全 T | 运行各层选择器/错误选择器、real 未授权拒绝和逐例 reporter 子例 | 无漏父 T/重复子 ID、P/R/D 明确；默认仅 unit，慢/real 显式；逐例分段计时与真实状态齐全 | 当前build75：unit31完整75/75、integration46完整845/845、system24完整25/25覆盖本项本地必需用例；114输入/526产物无漂移，59业务匹配repair70，全部guard清理完成。原始失败保留；真实范围由未勾项约束。 |
| A03 | [x] | Q03/Q10/Q11 / I09 / T04/T14/T24–T26/T32/T36/T56/T72 | test:unit contract/rules/state，系统无 AI 子例；错字段/三值/UTF-8/注入/超限输入 | 零智能兜底、严格错误/effect_state、截断否定不触发、外部正文不逃逸，不静默截短 direct | 当前build75：unit31完整75/75、integration46完整845/845、system24完整25/25覆盖本项本地必需用例；114输入/526产物无漂移，59业务匹配repair70，全部guard清理完成。原始失败保留；真实范围由未勾项约束。 |
| A04 | [x] | Q02/Q11/E05 / I10 / T17/T26/T33/T35/T39/T54/T62 | unit/identity、system/ownership、撤权/冒充/跨主体/读发分权子例 | 不靠标题/clientInfo 赋权，无越权存在性/片段/秘密；operator-only 受控，撤权只保留最小自有状态 | 当前build75：unit31完整75/75、integration46完整845/845、system24完整25/25覆盖本项本地必需用例；114输入/526产物无漂移，59业务匹配repair70，全部guard清理完成。原始失败保留；真实范围由未勾项约束。 |
| A05 | [x] | Q11/Q12/E04 / I11/I12 / T08/T29/T38–T40 | integration/storage、系统故障；提交前后崩溃/锁/磁盘/重复键/备份 | WAL/FULL/版本合规；台账/事件/游标原子、未知不重发、无影子库/浮点序号损失 | 当前build75：unit31完整75/75、integration46完整845/845、system24完整25/25覆盖本项本地必需用例；114输入/526产物无漂移，59业务匹配repair70，全部guard清理完成。原始失败保留；真实范围由未勾项约束。 |
| A06 | [ ] | Q02/Q06 / I13/I28 / T02/T03/T11/T33/T43/T67 | registry/agent 集成与真实 Pi 恢复/新 recipient 接线子例 | 精确原目标、绑定权限独立；注销不杀实例/清 route；新会话不改绑创建者，接收方 whoami 符合事实 | 本地registry/recipient及系统恢复通过；真实Pi恢复/接线待资源 |
| A07 | [x] | Q14/Q15 / I14 / T46/T50/T60/T63/T71 | integration/query/agent；同名/未登记/多工具/key/过期 ref/epoch/观察到期 | 范围正确且稳定分页，get 重取引用、probe 零输入；老 live 不冒充当前、已证 offline 不反转 unknown | 当前build75：unit31完整75/75、integration46完整845/845、system24完整25/25覆盖本项本地必需用例；114输入/526产物无漂移，59业务匹配repair70，全部guard清理完成。原始失败保留；真实范围由未勾项约束。 |
| A08 | [x] | Q10/Q14 / I15 / T47/T48/T59 | integration/query；中文/emoji/短串/FTS 符号、时间与 key 乱序/空页 | 字面精确、偏移保真、空 items+cursor 不报无结果；无全文先排序/无未授权片段、无 AI | 当前build75：unit31完整75/75、integration46完整845/845、system24完整25/25覆盖本项本地必需用例；114输入/526产物无漂移，59业务匹配repair70，全部guard清理完成。原始失败保留；真实范围由未勾项约束。 |
| A09 | [x] | Q14/E05 / I15 / T48/T57/T60/T61/T69 | query/storage/agent 集成与 performance/catalog；partial/删除/版本/超帧 | checkpoint/正文/FTS 同版本；partial 不删；驱逐/撤权明确失效；有界帧/扫描/配额与公平性留证 | 当前build75完整功能945/945，performance22十万目录和正文配额各独立通过，刷新中分别转发500/84条、配额拒绝成立；原始报告及全部guard清理证据已归档。完整吞吐由未勾项单独约束。 |
| A10 | [ ] | Q16/Q17 / I16 / T51–T53/T58/T64–T66 | integration/lifecycle、e2e/control；并发 start/create/stop、丢响应/过期引用/未知进程 | slot/gate/epoch 原子，Pi initial_session_key/OpenCode 空 create 可证；unknown/manual 不重复拉起、停机不等清空队列 | 本地lifecycle/协议子例通过；真实create/start/stop待资源 |
| A11 | [x] | Q03/Q11 / I17 / T04/T12/T28 | integration/delivery；preview 改参/revision/过期/并发暂停 | 固定票据、start/cutover 规则、提交点顺序一致，不补发暂停期、旧贡献不复活 | 当前build75：unit31完整75/75、integration46完整845/845、system24完整25/25覆盖本项本地必需用例；114输入/526产物无漂移，59业务匹配repair70，全部guard清理完成。原始失败保留；真实范围由未勾项约束。 |
| A12 | [x] | Q01/Q04/Q05 / I18 / T01/T05/T08/T12/T21 | integration/im/delivery、system/flows；重复 created、扇出、分批中断 | 同源去重、四方向独立贡献、路由 checkpoint 不吞工作；非匹配/未算/未知不混淆 | 当前build75：unit31完整75/75、integration46完整845/845、system24完整25/25覆盖本项本地必需用例；114输入/526产物无漂移，59业务匹配repair70，全部guard清理完成。原始失败保留；真实范围由未勾项约束。 |
| A13 | [ ] | Q04/Q15/E04 / I19 / T05/T09/T12/T14/T30/T31/T36/T49/T62/T72 | delivery 真 SQLite/协议集成；无 IM 的 direct、多 TTL、注销/撤权、入队后限额变化 | 两 origin 同 route/unknown/序号，无假 Event/Contribution；本人可查控、不借订阅权限、direct 不被退订取消 | 本地direct/订阅队列契约通过；补正T49真实闭环映射后恢复待验，未运行原生direct-control |
| A14 | [x] | Q05/E03/E04 / I20 / T03/T07/T09/T16/T31/T35/T50/T65 | integration/agent/delivery、system/recovery/flows；busy/offline/permission/unknown/gate 竞态 | 原目标排队/hold、不绕过审批；submitting 提交点、回执分层、未知不重发不越序，安全 retry 证据充分 | 当前build75：unit31完整75/75、integration46完整845/845、system24完整25/25覆盖本项本地必需用例；114输入/526产物无漂移，59业务匹配repair70，全部guard清理完成。原始失败保留；真实范围由未勾项约束。 |
| A15 | [ ] | Q13/E04 / I21 / T08/T13/T15/T21/T41 | integration/im 与当前授权 Lark user/Telegram bot 话题；窗口/分页/重启、offset/ACK、webhook、回声 | Lark message_id/轮询延迟/源缺口、Telegram 持久 offset 正确；原话题/原生 ID 保留，无 UI 回退/竞争接管 | 本地IM协议/窗口/ACK子例通过；Lark国际版user服务器验证与只读群名检索成功，两个项目名称关键字均返回total=0，尚无选定授权chat/topic；不等于真实消息摄取/原话题验收，Telegram真实话题同样未运行 |
| A16 | [ ] | Q05/Q14–Q17 / I22 / T06/T07/T10/T16/T22/T43/T51/T57/T69 | integration/agent + 两目标真实协议；idle/busy/handled/204、查询/create/start/帧故障 | 接受/开始/稳定分开；OpenCode/Pi 原生身份/覆盖可证，未支持能力拒绝，existing 不接管、巨帧不杀工具 | 本地两Agent协议/故障子例通过；真实原目标唤醒/创建待资源 |
| A17 | [ ] | Q07/E05 / I23 / T13/T20/T24/T33/T34/T37 | integration/im/interfaces 与真实回复；local 查询、过期引用、单文本/多片拒绝/unknown | 查询不触发；固定目的地单条回复与出站台账；未知不整条重发、不自动回群主流，未启用 native 明确拒绝 | 本地引用/回复台账及unknown子例通过；真实原话题回复未运行 |
| A18 | [ ] | Q09/Q12/Q17 / I24/I25/I29 / T09/T11/T15/T21/T31/T39/T43/T45/T52/T58/T68 | system 全进程/监督器+真实 managed 安全停止；重复 owner/新 schema/活跃 drain/重启 | 一个调度者、恢复屏障后开流、无影子库；期限到仍 draining 可核对，非自有不杀，强制中断风险如实记录 | 当前build69的system19完整25/25覆盖进程/owner/恢复/目录包；真实managed停止/安全drain待资源 |
| A19 | [x] | Q07/Q18 / I26/I27 / T18/T19/T26/T29/T39/T54–T56/T70 | integration/interfaces；同主体 CLI/MCP/API 完整操作目录、超时/错字段/断线 | 参数/授权/能力/错误/幂等一致，stdio 无日志污染；薄客户端不建库，资源 ID 类型/引用续签正确 | 当前build75：unit31完整75/75、integration46完整845/845、system24完整25/25覆盖本项本地必需用例；114输入/526产物无漂移，59业务匹配repair70，全部guard清理完成。原始失败保留；真实范围由未勾项约束。 |
| A20 | [ ] | Q01/Q06/Q08/Q10/Q13–Q18 / I08/I28–I30 / T01/T06/T23/T25/T27/T40/T42/T44/T49/T57/T67/T70 | 全部本地门禁后，当前授权 real relay/control/skill、performance，再审阅/签名交付 | 四组合 idle/busy 原话题回复 ID 齐；无 IM direct/start/create 闭环齐；Skill 实际采用；性能目标与总资源如实报告；全部必需 P/R 有证据、无秘密/无实现范围漂移，签名验证、明确 remote 才推送 | 当前75项unit、845项集成组合证据及25项system覆盖通过；performance21为3/4，route-load在70122.717208ms内部截止失败（6000事件/50006已接受输入，882条routing_work待物化、1174条投递ready，实际距60000尚差9994条），100事件/秒目标未达，真实19例/资源占用/Skill采用及最终签名交付待完成 |

每个 A 覆盖的父 T 可能有 deferred 子分支；A 的勾只说明首期必需 P/R 均通过，不能宣称远期正向功能通过。完整 T→文件→A 映射在 test-plan，不因为表格中“主要 T”短写漏掉其余必需子例。

## 需求到施工/验收

| Q | 差异 / 主要施工 | 必需验收入口 |
| --- | --- | --- |
| Q01 | D10–D14；I17–I22 | A12/A20 |
| Q02 | D04/D06/D18；I10/I13/I28 | A04/A06 |
| Q03 | D03/D10；I09/I17 | A03/A11 |
| Q04 | D11/D12；I18/I19 | A12/A13 |
| Q05 | D11/D12/D14；I18/I20/I22 | A14/A16/A20 |
| Q06 | D18；I28 | A06/A20 |
| Q07 | D05/D15/D17；I12/I23/I27 | A17/A19 |
| Q08 | D02/D18；I02/I29/I30 | A02/A20 |
| Q09 | D16；I24/I25；当前仅文档 | 当前文档边界；未来 A18 |
| Q10 | D03/D08/D16；I09/I15/I25 | A03/A08/A20 |
| Q11 | D03–D05/D10/D17；I09–I12/I17/I27 | A03–A05/A11/A19 |
| Q12 | D01/D05/D16；I01/I03/I11/I25 | A01/A05/A18 |
| Q13 | D13/D14/D16/D18；I21/I22/I24/I28 | A15/A16/A18/A20 |
| Q14 | D07/D08/D14；I14/I15/I22 | A07–A09/A16/A20 |
| Q15 | D07/D12；I14/I19/I20 | A07/A13/A14/A20 |
| Q16 | D09/D14；I16/I22 | A10/A16 |
| Q17 | D09/D14/D16；I16/I22/I25 | A10/A16/A18 |
| Q18 | D03/D17；I09/I26/I27 | A19/A20 |

## 接续与阻塞记录

以下为施工历史，当前阶段以文末“当前 S3 批次”和status为准。当时阶段：S1 测试/依赖编写进行中，I04–I07测试源码写齐待验；后续S1/S2已完成源码施工，不能把历史起点误作当前进度，也不能把源码写齐当验收通过。

依赖锁定、账号/profile、原生能力和资源授权的解除条件见 plan.md P01–P05。未来阻塞记录使用“影响的 I/A、事实证据、已尝试、解除条件、下一项”五列，只阻塞依赖它的工作；不把缺真实测试资源伪装为首期整体通过，不围绕未变条件空转。

本次准备复核：默认 ~/.dj 与独立测试根接线纳入 I01/I09/I24/I28；Lark 国际版 user OAuth、PollCheckpoint、DJ 有界轮询纳入 I11/I18/I21，source_health 投影纳入 I09/I26/I27；T13/T38/T39/T41/T42 的参数变体由既有 I02/I04–I08 写齐，最终 A03/A05/A15/A17/A18/A19/A20 留证。不新增第二套进度，不勾任何 I/A，运行 Goal 未改动。

S1 接续记录（5629237 后）：I01 已有 package/bun.lock/三个配置及本地依赖，formal source 80/84 对应，4 项来源绑定未解，保持进行中；I02/I04–I08 已写 manifest、四单元/七集成文件与 support，仍需补全参数/断言、system/e2e/performance/verify。全部未运行，不勾任何 A。具体当前树与下一项见 status 末节；不得从部分源码越级进入 S2/S3。

本轮 S1 源码续写：19 个目标测试文件均有源码，新增进程宿主/UDS/CLI/MCP/真实观察器与 Lark 子进程 fixture；I04 四个单元文件写齐（严格参数、UTF-8/Seq、身份/ref、三值/边界、状态），标写齐待验。I02/I05/I06/I07/I08 仍须补协议/故障/参数细节与真实驱动接线；未运行任何构建或测试，不以文件数或清单行数证明覆盖通过。

16d0001 后的 S1 接续：I05 三个集成文件补齐写入结果回滚/唯一/FK/真实锁/SQLite FULL/备份/未来schema、正文版本/删除/授权快照/精确刷新/块边界、slot unknown/manual/absence/历史ready与当前stopped/stop gate，标“源码写齐待验”。I06 的 Agent 测试新增原生 HTTP/JSONL 对端与204、disposition、LF/UTF-8/关联ID/超帧/丢响应断言；I06 其他接口/投递/IM细节、I07/I08真实驱动/资源报告仍待补。新用例已写入 manifest，不代表用例覆盖或运行通过；所有 A 仍未运行。origin/master 已建立，交付使用原明确远程，不再记录为无远程。

edba99d 后接续：I06 补齐 Telegram 原生 offset/诊断/论坛回复/unknown/429、Lark user CLI纯文本/原话题发送、固定票据与 update cutover、10000全局队列/完整原生帧预算、shared route/unknown，以及真正CLI/MCP/API同键受理/请求迟到；I07补齐生产main空配置启动/唯一owner/未来schema/正常停机、routing/submitting崩溃恢复、EchoGate unknown/manual及Core+Pi流Port安全drain。对应源码与参数ID已写入manifest，I06/I07标写齐待验，未执行。下一项为I08的E2E/Skill真实观察与性能/选择器闭包，再固化I01/I02；真实资源缺口不以合成端口或空服务退出代替。

S1 收口与 S2 起点：I02 全 T01–T72 清单及参数向量、I08 的真实观察器输入合同/Skill 正反例/60秒路由/大扇出/十万目录/正文配额/物理footprint报告/分层选择器已写齐；未经执行，不代表覆盖正确或运行通过。真实控制器是受保护外部fixture，模板所有授权默认false；其存在、原生证据和实际资源归属留S3核验。I01隔离源489项和Unicode补充输入已准备，编译器未执行。接续I03和I09–I30，不再重开S1或提前检查正确性。

S2 本轮已写：I03 构建器及宿主入口源码完成；I09 的 core 五文件、operationCatalog/schema/results，I10 的 principals/authorize/handles，I11 的 schema/sqlite/repository，I12 的 executeOperation 已写入。I09–I12 继续保留未勾：尚需与后续业务/服务模块接线，结果投影和变更守卫也须随真实消费者落地。下一项接 I13 registry、I14/I15 catalog 和 I16 lifecycle，不为已写模块提前运行或预审。当前未执行任何 A，也未创建新的已验证提交。

S2 本轮接续：新增 application/context、registry/agents、catalog/records/snapshots/service/search 与 lifecycle/gates/service；存储增加带排序/范围索引的 session_versions、正文独立 message_versions 及 snapshot 结果引用索引。短期 cursor 保存不可变页位置并绑定 operation/主体/授权/查询，正文引用绑定 catalog_seq/content_version；读方法不会启动或输入 Agent。Lifecycle 先受理 slot/gate 与 attempt，再外部 I/O；reconcile 不重新 start/create，人工结案不当 absence。I13/I14/I16 模块文本已写，但 Core/适配器消费者未装配，保持未勾，所有 A 未运行。下一项是 I15 refresh，接着 I17–I30；不围绕已写模块预审或运行。

S2 本轮接续：I15 refresh、I17 subscription、I18 ingestion/matcher、I19 delivery 已写入源码；没有构建、测试或运行。完整原生覆盖后的 source/body 删除屏障先屏蔽读取，再分批清理；partial 不证明删除。matcher 默认每批64候选（硬上限128），memo/编译缓存有界，预算耗尽保留状态而不判 no_match。候选贡献齐备才解除 routing_incomplete。下一项 I20 scheduler，然后 messaging/适配器/Core/三入口；所有 A 未运行，尚无新的已验收提交。

S2 接续：I20 scheduler、I23 messaging、I21 两 IM 与 I22 两 Agent 工厂的源码已写入；同时补 delivery/outbound 安全回执投影、连接 source_health 字段、当前连接身份的 Event 读屏障和按实例收紧的目录原生请求。它们尚未接入 Core/服务/三入口，I20–I23 保持未勾。下一项是 I24 config/recovery，再 I25–I30；其中 Pi 正文身份、原生地址核验、所有连接共享读取预算和 managed 排空须随全量装配补齐。没有执行编译、产品程序、测试、lint/静态检查、真实 OAuth/IM/Agent 或预审；A 全未运行，Goal 保持完整。既定 origin/master 已核对并推送现有签名基线，未把未验证源码纳入新提交。

## S3 早期批次记录（历史，当前以顶部状态和文末修复表为准）

最近完成验证的基线为build58，58份业务源码匹配repair-57。W1–W3三文件实现完成，unit20为74/74、integration32其余843项与integration33的T40定向通过组合覆盖844项、system14为25/25，合计943项功能覆盖。57→58仅W2夹具两处局部身份字符串，非测试产物完全同摘要；保留所有失败原始报告。

当前build61的A01–A05、A07–A09、A11/A12/A14/A19共12项本地验收恢复。performance19路由负载在70秒内部截止失败，3908事件/29366输入、持久剩余9714；另外三项性能独立通过。A06/A10/A13/A15–A18/A20、真实19例、原话题回复、Skill采用、物理资源与最终签名交付继续开放。Lark user OAuth已验证，专用IM/Agent授权资源及真实控制器仍缺。

FULL、6000/60000、100事件/秒端到端门槛保持不变。冻结build58私有编译图的SQL计时23与页缓存观察24已完成，未获得调缓存的依据；下一步根据实测和独立源码分析确定合并修复范围，不把施工完成、主机快照或私有采样当作吞吐通过。


## S3 修复记录

| 修复 | 施工完成 | 验收完成 | 位置 / 契约 / 证据 |
| --- | --- | --- | --- |
| 路由候选与有限连续岗位 | [x] | [ ] | build47基线；runtime的EXISTS、runRouteJob四次上限与窄head预检全部写齐；业务快照58份。测试已具备，build49、完整integration24 844/844、system09 25/25通过；性能14已终态：3项完成，T27在300秒超时且缺终态，整组失败；取消/清理与生产一致容量驱动待补齐，修复验收不勾；contracts/plan末节 |
| 容量驱动与超时隔离 | [x] | [ ] | contracts/plan末节；build51补齐绝对日程重验、等待/排空唤醒分离及如实报告门禁状态。unit14 74/74、T31定向integration26 1/1通过；独立逐例执行及70秒内部截止清理已有证据，T27吞吐仍失败，保留验收未勾 |
| 匹配与投递重复写收敛 R1–R5 | [x] | [ ] | build51/repair-48基线；五文件业务已写齐，repair-52快照58份，括号静态平衡通过；T40/T12/T31/T16整批测试已写齐，新增operation唯一性及真实CHECK探针fixture已修正，build52成功、unit15 74/74、integration27 843/844。唯一T12的观察边界已在build53修正，integration28定向1/1通过，生产产物零变化；system10为25/25；performance16四例独立收齐，大扇出/目录/正文配额通过，路由负载内部70秒截止失败；不跨事件缓存授权，不改变FULL/32/16/64/4或100门槛 |

Skill文案维护已完成：原生YAML保留，MDP/MDS最小结构和原生Skill格式校验通过；仅文案结构已验，真实客户端采用与A20未验。生产源码未改，不为文案格式重跑产品性能。

| 当前集中修复 | 施工完成 | 验收通过 | 基线、范围与证据 |
| --- | --- | --- | --- |
| 状态窄写与订阅窄读 P1–P3 | [x] | [ ] | build53/repair-52；诊断20只定位成本，正式T27仍失败。contracts/plan末节定义五文件内部变更；测试已写齐，五文件业务实现完成并保存repair-54的58份源码快照；build56冻结核对成功，unit18 74/74、integration30与T16定向31组合覆盖844项、system12 25/25；新增fixture问题已修齐并复验。performance17路由负载内部截止失败，其他三项通过，整体性能验收未勾。FULL、配额与当前授权重检不变。 |
| 单事件有界多行写入 W1–W3 | [x] | [ ] | build56/repair-54；诊断22排除query准备为主热点，contracts/plan末节定义repository、delivery.service、matcher三文件改动。契约及整批测试已交接；三文件业务实现全部完成，58份repair-57快照冻结，只有既定三文件变化；另补W2事务外暂存零变更回归。build58的113输入/522产物无漂移；unit20 74/74，integration32其余843项加T40定向33通过组合覆盖844项，system14 25/25；W2 recipient夹具改为独立身份，业务未变；performance18终态3/4，路由负载未达标，整体性能验收未勾；FULL、授权、容量停止点及门槛不变。 |
| 订阅状态批读与索引收敛 K1–K3 | [x] | [ ] | build58/repair-57；诊断23确认当前订阅单键查询与delivery写入成本，24未获调缓存依据。contracts/plan末节已写齐五文件的准确契约、位置、前后流程及验收：K1 repository四列16键批读与read-scope第四参数预载；K2 matcher传命中ID、scheduler LEFT JOIN保留流式贡献和逐条授权；K3补head后幂等删除冗余route_pending索引。T40/T16/T12整批测试及说明已交回且未运行；主开发五文件已全部实现，58份repair-59快照仅既定五文件变化，root-freeze-59保存113份绑定输入。build61构建通过；unit21为74/74、system15为25/25、integration34原始840/844加integration35四项定向全部通过。测试四例之外字节一致、58份业务未变，功能943项覆盖成立；performance19四项终态3/4：route-load内部截止失败（3908事件/29366输入、持久未接受9714），另三项独立通过且全部清理，不预先承诺吞吐收益。 |
| 实体主键时间局部性 U1–U3 | [x] | [ ] | 九类纯实体ID采用48位宿主毫秒+74位CSPRNG的UUIDv7，无counter；控制/幂等/秘密句柄仍v4。repair62共59份业务源码，build64冻结114输入/526产物；U-A1/U-A2/U-A3及组合945项功能覆盖通过，performance20为3/4，U-A4完整吞吐未过，整体验收保持未勾。异常时钟拒绝，不夹紧；旧v4共存无迁移。 |
| tick内有界第二轮派发 J1–J3 | [x] | [ ] | build64基线；contracts/plan已写齐。每轮32/16、全局64、同route每tick一个四步岗位，最多两轮；已提交进展/候选未穷尽才让出并重检owner/state/storage，优先级跨tick翻转一次、第二轮反向。仅runtime业务文件；扫描metadata/局部进展/单tick去重/轮间重验与一次优先级翻转已全部写齐。build69组合945功能通过，J-A1–J-A5在两例T31定向复验中通过；drain恢复循环已限制至多16次并硬断言stopped，租约精确注入/恢复已验。performance21终态3/4，route-load完整吞吐未达；诊断37已完成，下一批范围待定，整体验收未勾。 |
| 单事件投递批量创建与派发窄读 L1–L3 | [x] | [ ] | build69/repair65基线；五文件业务按contracts/plan完成，repair70冻结59源码。build75冻结114输入/526产物无漂移，unit31 75/75、integration46完整845/845、system24 25/25，L-A1–L-A7功能通过；构建/夹具断言的全部原始失败保留，最终期望对齐标准Result、现有批SQL和busy推进语义，生产未变。performance22独立3/4，route-load内部截止（5955事件/32088投递），其余三项通过且全部清理，完整吞吐仍待证明，不加routeEvents轮次、不缓存授权结论、不跳过查重，FULL/配额/6000/60000/100门槛保持。 |
| 真实验收控制器与profile装配 | [ ] | [ ] | 现有real.eli已实现授权/摘要/关联/回收协议；M批已本地验证原生reader/固定根采样基础（实际CLI短进程拓扑仍未覆盖），但示例仍默认未授权、14个其他driver仍指向缺失入口。real-preflight已按现有调用整理协议与资源入口；控制器实现/供应、原生观察来源和资源装配仍待完成，不能仅登记为凭据缺口，也不自动部署或运行真实外发。关联A06/A10/A13/A15–A18/A20。 |
| 第二组匹配准备 N1–N2（D功能覆盖成立，性能未通过） | [x] | [ ] | 原integration48关闭DB竞态已由V修复，失败原样保留。build84完整75 unit/25 system及其余844 integration，结合build87 T31定向771断言形成945项组合覆盖；新N/V段外源码与生产产物字节不变，独立审核无生产阻断。performance23四项收齐3/4通过，route-load内部截止失败；目录首次磁盘中断后经获准清理复测通过，原始记录保留。完整吞吐及真实S3、签名交付开放。 |
| 在途存储调用安全停止 V1–V2（D功能覆盖成立，完整验收未闭环） | [x] | [ ] | 四入口计数/finally、drain排空重验、同步seal/失败解封与受跟踪stop Promise已全量实现；future deadline不改。独立审核及build87定向测试通过，显式验证drain期间tick成功Result和seal窗口无fault/native动作。945为组合覆盖，不改写integration49原始失败；V-A6四项性能收齐3/4，route-load未达标，真实安全停止证据仍开放。 |

| 连接级临时子日志内存策略 Y1–Y2（D功能全通过，性能3/4） | [x] | [ ] | build88仅sqlite.eli业务设置+readback，完整75/845/25共945功能通过，独立审核无确定缺陷；Y-A1..A4本地证据成立。performance25四项独立收齐，大扇出/目录/正文配额通过；route-load内部截止：6000事件全部匹配、56970accepted、3030待接收，routing/claims=0，负载70010.171416ms。Y-A5完整吞吐与真实256MiB/S3仍开放，不由组件或跨轮差值替代。 |

| 提交期EchoGate规划收尾 EG1–EG2（D功能成立，性能3/4） | [x] | [ ] | build91/repair89冻结114输入、526产物与59业务，EG-A1..A4通过，原固定OpenCode Go/High搭档独立审核无确定业务缺陷。功能945为组合覆盖：build90 unit35 75/75、integration54其余844项、system28 25/25，加build91 integration55定向T40 1/1（197 expect）；90→91仅EG-A4测试两处，生产/工具/其余测试产物字节一致，不称单次845/845。performance26四项独立串行收齐3/4通过、全部cleanup_complete：route-load完成6000事件/60000投递，待处理/routing/claims均0，但完整负载67070.761375ms（ingest60890.257375ms、drain6180.504ms），89.45775889516656 EPS，status=failed、schedule_completed=true、throughput_below_target；另三项通过。EG-A5完整吞吐、真实256MiB/IM/Agent/Skill及最终签名继续开放，不把排空或跨轮差值当作性能达标或EG净收益。 |

| 同组匹配容量计数复用 G1–G2（D功能成立，性能3/4） | [x] | [ ] | build94/repair92冻结114输入、526产物与59业务；G-A1..A6通过、原搭档独立审核无确定缺陷，945组合功能覆盖成立。performance27三项通过；route-load内部截止：4549事件/34110accepted、负载70011.342125ms，完整100EPS与真实验收仍开放。 |

| 授权部署物理资源捕获 M1–M3（原生基础及局部修复通过，真实拓扑未闭环） | [x] | [ ] | build104冻结116输入/534产物，947组合功能覆盖；F1指定时序修复经独立172确认，59业务未改。自身/自有child libproc与纯采样/保护协议已验；固定根/静态角色尚不覆盖真实runCli短进程，完整覆盖与真实60秒部署仍未验，其他14控制器和100EPS仍开放，不自动部署。 |

| OpenCode只读原生观察 O1–O3 | [x] | [ ] | build106本地组件/必需断言及174/175独立审核通过，949为组合覆盖；59业务/生产/performance不变，真实E2E未运行。完整O验收与真实授权资源仍开放，见contracts/plan末节；不把endpoint标签称PID证明，不替代Pi或M生命周期覆盖。 |

| Lark刺激与独立回复观察 LI1–LI3 | [x] | [ ] | build109本地组件与177/178独立审核通过，124输入/562输出零漂移，951组合功能覆盖；unknown先FULL提交、一次刺激与原生父消息证明。真实user端点/chat/topic/四组合尚未运行，完整LI/S3验收仍不勾。 |

| Pi原生日志与双工具观察 PO1–PO3 | [x] | [ ] | build115本地D与179/180独立审核通过，130输入/578输出零漂移，953组合功能覆盖；完整日志尾窗、原生父链、保护文件与共享入口已验。真实Pi日志/模型、IM四组合未运行，完整PO/S3仍不勾；不竞争RPC或另起Pi。 |

最新吞吐复核performance28：build115的T27.route-load单项在70082.022ms负载窗口内部截止，5582事件/42614已接受投递，unaccepted9893、routing396、claims0（remaining10289为混合计数）；其他三项未变性能未复跑，完整100EPS/A20仍不勾。私有组件63（NULL-owner部分索引）和64（额外微任务ABBA）均未提供足够生产采用依据，保留原参数和调度；下一事务收敛候选仍在A设计讨论，未开始B/C。清理仅涉及已授权且无占用的本项目测试/临时数据，源码、build115和验收证据保留。

## 已延后的性能候选：RC1–RC3

| 当前增量 | 施工完成 | 验收完成 | 精确范围与下一步 |
|---|---|---|---|
| 同岗位回执与下一新claim合并提交RC | [ ] | [ ] | 仅保留已写 A 设计；按 2026-10-26 用户要求延后，不编写 B 测试、不实施 C、不启动性能复测。未来专项优化时再决定是否采用，不阻塞当前 Codex/Cursor 主要业务交付。 |

## Lark 实时收件与本人身份（规格 0001）

| 当前增量 | 施工完成 | 验收完成 | 精确范围与下一步 |
|---|---|---|---|
| 长连接 → Core 订阅规则 → 精确原 AI 对话；本人 / bot HTTP 身份与 Skill | [x] | [x] | 官方 WebSocket/HTTPS 直连已部署，无 SDK/外部 IM CLI；真实默认@和组合关键词经 Core 投递原 Codex 对话，原生输入及确认读回；本人发送、机器人原消息回复均经官方读回。7项定向检查通过。应用事件范围不冒充全部个人收件箱，其他 IM、全工具矩阵和性能不恢复为本项前置；进一步场景见规格0001未勾项。 |

## 消息触发黑名单（规格 0002）

| 当前增量 | 施工完成 | 验收完成 | 范围 |
|---|---|---|---|
| 人员/字符可组合规则、suppress_trigger 与统一管理接口 | [x] | [x] | [0002](docs/specs/0002-message-trigger-filters.md)；收件和可见性保持，匹配与提交前仅拦自动动作。已完成业务、3项集成及1项保护单测（52断言），常驻服务已更新并核对空策略；未配置实际屏蔽条目。 |
