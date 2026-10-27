# 测试实现、执行与验收方案

本文落实 [T01–T72 行为规格](../acceptance.md)，不重编号或重复维护业务预期。首期适用性继承 [发布矩阵](../release-scope.md#首期统一能力与验收适用矩阵)，当前S3完整构建、unit/integration/system已有通过证据，性能与真实组仍在收口；准确状态以TODO/status为准。TODO的A清单是唯一验收进度；本文件负责文件/子用例/环境/命令/证据。

可转写的 fixture、稳定主case_id、给定/操作/机械断言、八个真实四组合分支与远期D卡见 [用例卡](case-cards.md)。I02 先据此生成完整参数 manifest，再由 I04–I08 写测试源码；本文和用例卡都不能冒充已经生成的 tests/cases.json。61 操作的参数矩阵输入见 [字段表](operation-catalog.md)。

## 1. 全部先写、最后执行

未来获实现授权后，B 阶段一次写齐以下全部 `.test.eli`、fixture、fault hook、用例 manifest 和真实验收步骤；不加载 runner、不编译、不执行。先声明依赖已设计的目标符号，即使实现文件尚不存在也不能为“看失败”试跑。C 阶段全实现写完后，D 阶段才构建、按层运行、汇总失败成批修复并必要复验。

使用 Bun 自带 runner，测试经 Eliscript 编译为 .test.mjs 并显式导入 bun:test；不另造断言框架。Bun 官方说明支持 .test.mjs、按明确文件选择以及 JUnit 输出，[runner](https://bun.com/docs/test)、[reporter](https://bun.com/docs/test/reporters)于 2026-10-23 查阅；这只是实施依据，Eliscript interop 和锁定版本仍须 T38 实证。

## 2. 文件、选择器与报告

所有下列路径均归施工 D02；S1 已创建目标测试文件，仍按 TODO 补齐细节，不能将文件存在当作覆盖通过。测试不是 TS/JS 手写业务副本。单元、集成、系统、E2E 流程和性能分别标记；fast/slow 只管调度，不改变测试边界。

| 组 | 准确测试文件（tests/ 下，均 .test.eli） | 对象、真实边界及默认调度 |
| --- | --- | --- |
| unit | unit/{contract,identity,rules,state}.test.eli | 参数/类型、纯授权投影、规则、状态；可控时钟/ID，无网络/进程/真实数据库 |
| integration | integration/{storage,query,lifecycle,delivery,im,agent,interfaces}.test.eli | 实际 SQLite、组件调用、受控 HTTP/JSONL/CLI 对端；不证明真实厂商/model 唤醒 |
| system | system/{recovery,flows,ownership}.test.eli | 完整 DJ 进程/UDS/重启/配置/监督、跨模块路径；默认受控协议替身 |
| e2e | e2e/{relay,control,skill}.test.eli | 测试账号的真实两 IM/两 Agent、创建/启动/回复/Skill 采用；显式授权才运行 |
| performance | performance/{router,catalog}.test.eli | 真 SQLite/本地真实 I/O，隔离数据；路由/查询/公平性与资源统计，外部模型另计 |

tests/support/case.eli 的 `withCase(case_id, setup, exercise, teardown)` 包裹原生 test，记录分段单调耗时/失败/资源引用并交给 Bun 断言；fixtures.eli 的 `createFixture(case_id, worker_id)` 分配隔离状态；faults.eli 的 `atFault(point, action)` 仅在测试装配时注入，生产运行不接受请求触发故障。

tests/cases.json 为版本化 manifest，每个子例固定 `case_id,parent_id,file,suite,level,e2e,applicability,parameters,required_profile,timeout_ms,resource_group,requirements,acceptance_ids`。case_id 形如 T65.stop-before-submit.sqlite 或 T42.feishu.pi.busy.real，不能只用同一个 T42 名称代表四组合。applicability 精确为 enabled-positive / required-rejection / deferred；每个父 T 的首期子例均明确列出，deferred 保留理由且不算已通过。同例多标签按 case_id 去重。

tools/verify.eli 仅做薄选择器：读取 manifest → 验证请求 suite/case/资源授权 → 生成精确编译后文件列表 → 参数数组调用 Bun runner → 关联原生 JUnit 与 withCase 记录 → 检查缺失/重复/未执行项。它不实现新测试平台、不改生产功能、不隐式构建、不安装依赖或拉起真实组。组入口限制文件集合；需要跨组的子例分别命名，不依赖运行另一个组留下的数据。

| 未来 package script | 对应 verify 参数 | 运行条件/副作用 |
| --- | --- | --- |
| test / test:unit | --suite unit | 默认入口，只有纯单元；无慢组 |
| test:integration | --suite integration | 真实隔离 SQLite/受控对端，可能较慢，显式选择 |
| test:system | --suite system | 本次自有 DJ/替身进程与 UDS，不触及已有服务 |
| test:e2e | --suite e2e --real | 还须 DJ_TEST_REAL=1 与已授权测试 profile，缺失返回未执行而不当 skip-pass |
| test:performance | --suite performance | 独立负载，不自动进入 test/unit 或 E2E |

以上 scripts 的实际命令为 `bun dist-tools/tools/verify.mjs` 加表中参数；verify 调用 Bun 时传精确的 `./dist-tests/tests/<组>/<文件>.test.mjs`，加 `--reporter=junit --reporter-outfile=<本次证据文件>`，不依赖位置字符串包含匹配或无过滤自动发现。额外支持 `--case CASE_ID`，无匹配必须失败。不得用未限定的 `bun test` 作为项目日常入口。

## 3. T 场景到子例与文件映射

下表 P=首期正向，R=首期明确拒绝/限制，D=远期保留。P/R 都是首期验收必需；表中含 D 不代表父项可以整体填“不适用”。具体给定/当/则使用 acceptance.md 对应行，边界输入在 B 阶段参数化到 manifest。file 用上表文件名，组名消除同名歧义。

| 父 T | 适用性与必需分支 | 主要文件/环境 | TODO 验收 |
| --- | --- | --- | --- |
| T01 | P 四组合多对多 | system/flows；e2e/relay | A12/A20 |
| T02 | P 同名/身份冲突，R 猜标题写入 | unit/identity；integration/agent | A06 |
| T03 | P 历史离线保持，R 自动替代 | system/flows | A06/A14 |
| T04 | P 三值/来源/话题边界 | unit/rules | A03/A11 |
| T05 | P 同 route 多贡献与扇出 | integration/delivery | A12/A13 |
| T06 | P 两目标 idle 原会话唤醒回复 | e2e/relay | A16/A20 |
| T07 | P queue/permission；R steer；D 正向 steer | integration/agent；e2e/relay | A14/A16 |
| T08 | P 可控 ACK 崩溃、R 提前 ACK 缺口公开 | integration/im；system/recovery | A05/A15 |
| T09 | P 写出后落盘前 unknown | system/recovery | A13/A18 |
| T10 | R 原生去重未证限制；D 正向稳定 dispatch key | integration/agent | A16 |
| T11 | P 重启/引用过期/稳定源与同 session 恢复 | system/recovery | A06/A18 |
| T12 | P pause/update/delete 与匹配提交竞态 | integration/delivery | A11/A13 |
| T13 | P 自身消息 ID 抑回声、R 不猜来源链 | integration/im；system/flows | A15/A17 |
| T14 | P 队列/正文/预算边界、R 未启用附件操作 | unit/contract；integration/delivery | A03/A13 |
| T15 | P 断线 gap 不冒充恢复 | integration/im；system/recovery | A15/A18 |
| T16 | P accepted/started/settled/自报分别投影 | unit/state；integration/agent | A14/A16 |
| T17 | P 撤权/凭据失效，R 自报 operator | unit/identity；system/ownership | A04 |
| T18 | P CLI/MCP 同键一次受理 | integration/interfaces | A19 |
| T19 | P 代理断线/服务不可用；R 未验证宿主/旧版 | integration/interfaces；system/ownership | A19 |
| T20 | P 过期/撤权引用拒绝、不改目的地 | integration/im；integration/interfaces | A17 |
| T21 | P 自身 owner/claim；R 已有 webhook/外部竞争 | system/ownership；integration/im | A15/A18 |
| T22 | P 首期协议/权限/运行错误；D 其他私有工具 | integration/agent；e2e/control | A16 |
| T23 | P 两 Agent CLI Skill；D 其他客户端采用 | e2e/skill | A20 |
| T24 | P created/local/UTF-8/主动发送；R edited/deleted/native；D 其正向 | unit/contract；integration/im | A03/A17 |
| T25 | P DJ 无推理依赖/调用；外部模型另列 | system/ownership | A03/A20 |
| T26 | P 错类型/额外字段/越权/过期零效果 | unit/contract；integration/interfaces | A03/A04/A19 |
| T27 | P 热路径/巨大扇出/公平/背压 | performance/router | A20 |
| T28 | P 固定票据/revision/重复提交 | integration/delivery | A11 |
| T29 | P 响应丢失/原键找回/迟到提交竞态 | system/recovery；integration/interfaces | A05/A19 |
| T30 | P queue/current/不同 TTL/grants；R steer/recent；D 其他正向合并 | integration/delivery | A13 |
| T31 | P submitting 前后 pause/cancel/崩溃 | integration/delivery；system/recovery | A13/A18 |
| T32 | P 截断否定/空 all；R 未启用事件；D edited/deleted 正向 | unit/rules | A03 |
| T33 | P recipient/权限/提交前回复引用；R 缺约束/越权 | integration/delivery；system/ownership | A04/A06/A17 |
| T34 | R 多片受理前拒绝；D 多片恢复/后缀 retry | unit/contract；integration/im | A17 |
| T35 | P operator manual/保持 busy；R Agent resolve | integration/delivery；system/ownership | A04/A14 |
| T36 | P 外部 JSON/role 隔离；D IM 删除通知/未提交原文 tombstone | unit/contract；integration/delivery | A03/A13 |
| T37 | R 首期 native IM corpus；D native 快照/live 联动 | integration/im | A17 |
| T38 | P Eliscript 多入口/互操作/false/null/大序号；nativeGet缺失/显式null保真回归 | unit/contract；integration/interfaces；system/ownership | A01 |
| T39 | P 核心/UDS/代理唯一 owner；R 共享身份伪装 | system/ownership；integration/interfaces | A04/A18/A19 |
| T40 | P 真 SQLite 模式/版本/崩溃/备份/停顿及可选revision守卫 | integration/storage；performance/router | A05/A20 |
| T41 | P Lark user 固定身份/增量窗口/分页/dedup、Telegram offset | integration/im；e2e/relay | A15 |
| T42 | P 四组合各 idle/busy、原话题回复 ID | e2e/relay | A20 |
| T43 | P Pi 初始/获准同 session 恢复；R 替新目标 | e2e/control；system/recovery | A06/A16/A18 |
| T44 | P CLI 正确采用/超时/reply 缺失；D 未验证 MCP 宿主 | e2e/skill | A20 |
| T45 | P 首次/重复/新 schema/停止恢复；R 影子库/未启用能力 | system/recovery | A18 |
| T46 | P 多维范围/未登记/同名/稳定分页 | integration/query | A07 |
| T47 | P FTS 字符/中文/emoji/短串/精确偏移 | unit/contract；integration/query | A08 |
| T48 | P 覆盖/撤权/删除/刷新中断无触发 | integration/query | A08/A09 |
| T49 | P 无 IM/登记 direct、共享 unknown | integration/delivery；e2e/control | A13/A20 |
| T50 | P 精确 resolve/epoch/offline hold；R 隐式启动 | integration/agent；e2e/control | A07/A14 |
| T51 | P OpenCode 空 create；R Pi 同 RPC create | integration/lifecycle；e2e/control | A10/A16 |
| T52 | P 并发 start/丢响应/重启归属 | integration/lifecycle；system/recovery | A10/A18 |
| T53 | P 生命周期 unknown/原键；R 换键再建 | integration/lifecycle；system/recovery | A10 |
| T54 | P 读/发/create/start 分权；R argv/任意路径 | unit/identity；integration/interfaces | A04/A19 |
| T55 | P 三入口字段/幂等/资源类型一致 | integration/interfaces | A19 |
| T56 | P IM 正文不解析管理指令、字面检索 | system/flows | A03/A19 |
| T57 | P 大目录/索引/帧/并发转发真实资源 | performance/catalog；integration/agent | A09/A20 |
| T58 | P 自有 stop/drain/队列；R existing stop | system/ownership；e2e/control | A10/A18 |
| T59 | P 空页续扫/键顺序；R search 时间排序 | integration/query | A08 |
| T60 | P 版本快照/checkpoint/驱逐/撤权 | integration/query；integration/storage | A07/A09 |
| T61 | P partial 不删、可证删除屏蔽 | integration/query | A09 |
| T62 | P direct 自有记录/注销后路由；R 其他主体读取 | integration/delivery | A04/A13 |
| T63 | P 精确 keys/get/probe 不输入不登记 | integration/query；integration/agent | A07 |
| T64 | P 初始/新会话 key 与过期句柄，历史 ready | integration/lifecycle；e2e/control | A10 |
| T65 | P stop/send/create/订阅提交先后与非空队列 | integration/lifecycle；system/flows | A10/A14 |
| T66 | P 单 slot/退出证据；R manual 后重复 start | integration/lifecycle；system/ownership | A10 |
| T67 | P 独立 recipient 接线、创建者不改绑 | system/flows；e2e/skill | A06/A20 |
| T68 | P 活跃/unknown drain；R 期限到伪停/强杀 | system/ownership；e2e/control | A18 |
| T69 | P 巨帧有界排空/失步隔离/在途 unknown | integration/agent；performance/catalog | A09/A16 |
| T70 | P 三入口/Skill 发布适用一致；R 身份字段混用 | integration/interfaces；e2e/skill | A19/A20 |
| T71 | P 新鲜度过期不覆盖明确 offline | unit/state；integration/query | A07 |
| T72 | P policy/TTL/入队后限额；R context/超长直发 | unit/contract；integration/delivery | A03/A13 |

## 4. 测试数据与故障注入

每例分配 run_id/case_id/worker_id，状态库/socket/profile/连接/原生 namespace 隔离；只读编译产物复用，不共享可变 SQLite/固定端口。拒绝以开发者现有 IM/Agent 工作目录作为 fixture。真实组的 profile 由可信测试配置提供，只记录安全引用，不把 token/cookie/cwd 绝对路径或原始正文写进报告。

固定语料包括：两个同标题但 namespace 不同的会话、同 session 多视图、未登记/离线/忙碌目标、单/双字符/中文/emoji/组合字符、FTS/SQL 特殊字面串、跨分块关键词、截断否定、不同 TTL/grants、多主体撤权、目录缺页与可证删除。排序数据刻意让 updated_at 顺序不同于 session_key；不得用顺序恰好相同的 fixture 掩盖 R15。

故障点为稳定 ID，参数由测试端口注入，不公开给业务请求：

| fault point | 注入方式与证据 | 预期不变量 |
| --- | --- | --- |
| event.after_commit_before_ack | 隔离进程在真实事务提交后中断，记录提交水位 | Telegram 不丢未确认批次、重投不重复；Lark 未提交页重读去重、窗口不提前越过，源可见性缺口明确 |
| routing.before_checkpoint_commit | 在一批贡献/进度提交前后分别中断 | 决定/贡献/Delivery/checkpoint 不半提交 |
| delivery.after_submitting_before_write | 落盘后未写出时中断 | 恢复仍 unknown，不能因实测未写出就改变通用合同 |
| delivery.after_native_accept_before_receipt | 受控对端记接受、本地未存回执即中断 | unknown、同 route 后续不写、原键重放不重复 |
| lifecycle.after_spawn_before_ready | 保留自有 launch token/进程证据后中断服务 | 单 slot 不重复拉起，握手与当前 epoch 分别核验 |
| lifecycle.after_create_before_receipt | 原生已建、响应丢失 | unknown 不按标题猜；可证关联才 reconcile |
| gate.stop_race | 屏障控制两个事务前后顺序，不用 sleep 拼概率 | stop 先则后提交 none；在途先则 stop drain，未提交队列 hold |
| catalog.after_batch_before_checkpoint | 版本/索引/checkpoint 的原子点前后中断 | 不吞页、不混正文版本、不把 partial 当删除 |
| protocol.oversized_no_lf | 对端缓慢吐超长帧/缺 LF/混事件 | 有界缓冲、5 秒排空截止、失步隔离，无杀工具或猜响应 |
| storage.disk_full_or_lock | 隔离存储错误/受控第二连接锁、真实版本/mode 拒绝 | 不提前 ACK、不影子库、不删除幂等墓碑 |

进程崩溃注入只作用本次隔离 DJ/替身进程；真实活跃 Agent 的正常停止验收不能以强杀完成 teardown。无法安全结束的 unknown 资源保留受控现场与归属记录，测试结果标未完成，不误杀其他任务。逻辑 TTL/句柄过期用可控时钟；验证真实 drain/超时的场景用真实边界和有截止的条件等待。

## 5. 集中执行、计时与验收门禁

以下命令全部是未来 package scripts，工作目录为 DJ 仓库根；当前不执行，也不宣称文件已存在：

```bash
bun run build:tools
bun dist-tools/tools/build.mjs --scope all
bun run test:unit
bun run test:integration
bun run test:system
bun run test:e2e
bun run test:performance
```

先构建工具图，再一次构建全图，复用产物运行各组；每组只执行适用 manifest 子例。real 组还需环境中 DJ_TEST_REAL=1 与 DJ_TEST_PROFILE 指向受保护测试配置；不能用环境开关替代真实外发/资源授权。没有这些条件时明确未执行/blocked，默认快速命令不触发 real。未来已授权实现若仍缺真实资源，应完成所有可做的本地工作并保留 A15/A16/A20 待验，不把首期缩为模拟版。

| 组 | 初始调度建议（未测基线） | 截止与处置 |
| --- | --- | --- |
| unit | 一个 runner；纯例目标通常 <50 ms | 普通子例默认 5 s，实际超时/慢例留证，不能改层级掩盖 |
| integration | 先 1 worker；证明隔离/资源后可到 2 | 默认每例 30 s，故障/流截止单列；真实磁盘等待不可无限重试 |
| system | 按 resource_group 隔离；同 owner/slot 场景串行 | 默认每例 60 s；多进程现场/退出未完成分别记录 |
| e2e | 首期每 profile 一个在途真实任务，四组合独立记录 | 每个外部状态等待默认 120 s、子例最多 300 s；到时未完成，绝不强杀在用 Agent 或伪通过 |
| performance | 本次重负载先单跑、预填 corpus/磁盘配额 | 负载窗口 60 s、整例默认 180 s，不把准备/清理摊入热路径；按主机资源收敛 |

以上数值是初始截止/调度设计，I02 将特例显式写入 manifest；实际测得合理调整须保留依据，不无限加超时。编译器和重型负载按届时资源保护规则单跑未知重任务；不对普通 Git/文档操作套运行限制。实际测试可长于工具等待周期，执行者应以短周期读取进度、保持沟通，不能一次阻塞失联。

报告放本地持久 `.local/acceptance/<run_id>/` 并忽略 Git：manifest-snapshot、environment、JUnit XML、逐例 timing NDJSON、redacted receipts、failures、summary。每例记录 case_id/parent/T/Q/A、source commit+dirty tree fingerprint、构建/编译器/依赖哈希、suite/level/e2e/applicability、attempt、status、setup/exercise/teardown duration、整组墙钟、超时/中断、资源归属/清理。原始敏感诊断另受保护，不默认保存模型会话全量正文。

状态区分 pass/fail/not_run/blocked/interrupted/deferred；不能把 deferred/skip 或重试后通过改写成首轮 pass。A 项只有所有必需 P/R 子例实际通过且证据绑定当前产物才勾；D 不记为通过。父 T 的汇总可以“首期适用通过、远期分支未执行”，不能“整项全功能通过”。

性能记录路由 CPU p95 ≤10 ms 的既定目标、入库→ready 延迟、p50/p95/p99、吞吐/积压、事件循环/fsync/checkpoint 停顿、目录/FTS 扫描量、内存和总磁盘。使用既定 100 连接/10000 订阅/1000 目标、100 事件每秒/4 KiB/≤64 候选基准；目录分别测规模增长、10 万元数据和正文配额边界。DJ 与自有 consumer/代理内存目标 256 MiB，外部 Agent 单列且报告总量，不用模型耗时掩盖转发性能。冷热缓存与索引/回退分别报告。

最终审阅检查无 AI、越权/未知不被绕过、所有分支接线和真实证据边界；这是当前执行者自评，除非另有授权不派独立 Agent。失败一次汇总成批修复，复验失败项及确实受影响范围；没有源码/依赖/环境变动不重复全套。最后按 TODO A20 执行 status/diff/秘密路径扫描、签名验证、有明确 remote 才立即推送；不隐式部署、安装系统服务或发布版本。

Lark user 与默认目录的新增参数覆盖按 case-cards 末节展开到既有 T13/T38/T39/T41/T42，仍由 I02/I04–I08 一次写齐。内部读取不作为公共 native 历史查询正向用例；轮询时间以可控时钟测调度，真实组另测 source→observed→route 延迟及 CLI 总成本。测试根不使用用户真实 ~/.dj。


S1 补充的 poll.before_page_commit/poll.after_page_commit 在真实页面持久事务前后中断，断言旧断点可重读、已提交页不重复以及身份/generation 不漂移；不把 routing checkpoint 故障冒充页面入库前故障。withCase 的真实授权缺口记录 not_run，verify 同时建立本次 native-evidence/performance NDJSON 与 environment/manifest/JUnit/timing/summary，缺结果不能判通过。真实观察器实现与授权资源接线仍必须齐备，不能仅凭 driver 名称生成验收证据。

本期性能 Core 合成对端基准之外，最终仍须单独证明实际消费者/代理的自有进程、峰值/稳定内存、外部模型进程及合计；两种范围明确分列，不能将一个 in-process RSS 当成整个部署的通过结论。

真实驱动 profile 的 drivers 项必须明确 kind=test-controller、authorized=true、safe_to_terminate=true，且是本次自有有限期控制/观察进程；不得直接把原生 AI 工具或既有活会话进程当驱动来终止。最终真实验收前核对实际 argv/程序归属，驱动自身的观察仍需由 DJ/原平台记录交叉核对。

S1 原生协议用例补充使用 support/agent-protocol：OpenCode 为随机 loopback 端口上的真实 HTTP 协议对端；Pi 为 ProcessPort 流/JSONL 通道对端。它们证明的预期边界是适配器协议映射，不能代替真实工具/模型/IM证据。storage 用真实第二连接写锁、max_page_count 的 SQLite FULL 与 WAL一致性备份；query/lifecycle 补正文版本/删除/撤权/块边界与未知slot/手工结案/已证退出/历史状态分离。所有分支在 cases.json 各有独立 ID，源码写齐状态见唯一 TODO，当前仍未运行。

I06/I07 的后续源码补齐了原生 Telegram offset/论坛回复/429/unknown、Lark user 发送命令、固定 preview/update cutover、共享 route/unknown、三入口真实代理/延迟受理，以及生产 main 空服务启动/唯一 owner/未来 schema/正常停止。EchoGate 的 unknown/manual 保留与已证 ID 后重新匹配、完整 Core+Pi 流 Port 的 busy/drain 管道另有系统子例；该 Pi Port 仍是受控原生流对端，不冒充真实 Pi 进程。test-host 的请求屏障只在测试代码，不复制到产品。

T14.global-queue-limit.sqlite 单独声明 slow 资源组/120秒截止，11个busy目标分摊10000条输入，验证全局限制而非先碰到单目标1000；它仍是数据库/队列集成用例，不因为较慢而改名性能或进入默认 unit。当前未执行，耗时、fsync和资源成本须在S3逐例报告，不能提前宣称速度合格。

I08 源码收口：路由基准为6000事件/60秒，另有10000候选/1000目标的分批扇出；目录为10万元数据与8193条64KiB正文的配额输入，并在刷新期间实际入队转发，不能只断言“丢失计数为0”而没有转发目标。正文用例独立600秒截止、目录用例300秒，属于预设有界负载而非实测速度结果；S3须先核对磁盘/资源余量，不能擅自改小语料让门禁变绿。

`test:performance` 选择本地负载；`test:performance:real` 额外要求 --real/DJ_TEST_REAL/当前授权profile，包含真实部署资源。真实资源缺失时可完成独立本地组，完整A20仍未验。verify记录被排除的真实必需case，suite_complete只在完整所选组的全部必需项实跑后成立。真实fixture模板见 config/acceptance.example.json，控制器与样本字段见 contracts；它是待绑定输入，不能伪造为已实现原生观察器。S1的写齐不替代S3对实际控制器源码/版本/归属和真实数据的核验。

Skill 采用用例以 preview_id 和原生 preview/create 工具调用关联，另有“原生已结束但没调用 reply”的负例；reporter/manifest/资源求和的错误分支写入 unit/state，尚未执行。最终A02同时检查编译与依赖身份、全部T父场景和caseID、原生JUnit/逐例分段计时、not_run及真实证据；文件和计数不能代替验收。

S2 新增的必要合同变体均先写用例、后写对应生产接线，当前未运行：T63.pi-native-entry-id.integration 通过受控 Pi JSONL 的 get_entries 检查稳定 entry ID 和只读正文覆盖；T67.recipient-reload.system 检查 managed start 后独立 recipient 原子重载、主体类型不可复用及创建者不改绑；T24.address-proof.integration 检查原生地址拒绝/允许与异步返回后的撤权；T16.pi-end-is-not-settled.unit 区分结束和最终静止。T40 原 SQLite 用例补实际 sqlite_version、PASSIVE checkpoint 与活页容量读回。

T38.directory-runtime.system 调用源摘要绑定的 Eliscript 打包器，复制目录包到仓库外的私有持久路径，在不同 cwd 启动生产 main 和 MCP，核对两者实际 build_id 与包清单；它属于系统/E2E 流程，单例180秒、隔离 package 资源组，归 A01/A18/A19/A20。该用例既不访问真实 IM/模型，也不证明真实两工具采用 Skill。Bun.build 只在 S3 运行它或显式打包时发生；依赖身份检查不能替代实际成品独立运行和生产闭包审阅。

## S3 修复回归补充

T38.native-access.unit 验证宿主对象读取的missing/显式null/false/0/空串/可选receiver语义，不能依靠Eliscript集合get的缺省值代替。T40.repository-revision.sqlite 使用实际SQLite，分别验证省略内部revision、不省略且匹配、显式旧revision回滚；不放宽线上严格schema。T02.same-title.integration 同时断言agent.discover不消费适配器拥有的原始会话数组。稳定父T不增加，逐例ID仍以tests/cases.json为准；当前实际结果统一见status与TODO。

性能修复回归T40.metadata-quota-rollback.sqlite：实际SQLite预置99999条live元数据，在同一事务内写到边界再越界，断言整批回滚；新事务读取真实99999并提交第100000条，既有live更新不占新容量，后续新增拒绝。CatalogQuota仅活在该同步事务，不跨批次/回滚缓存；此例归原T40/A05/A09，计时/结果以manifest与status为准。性能advanceCatalog逐批让出macrotask，使框架截止和原生对端获得运行机会，不增加300/600秒预算。
# S3 待处理工作查询修复

真实路由负载的 JSC 采样中，`delivery_reconcile` 查询占约 42% 样本；旧查询在约 738MiB 数据库上无结果扫描约 1.4 秒。保持调度器固定 SQL、keyset 公平性、批量上限和状态语义，给三个 `reconcile_requested=1` 队列及未排空 accepted 观察队列添加部分索引。schema-1 启动时幂等补建，不降低 WAL/FULL。

`T40.pending-work-indexes.sqlite` 检查真实 SQLite 查询计划使用指定部分索引（含 `selectHead` 五状态队首 `deliveries_route_head` 与四个待处理队列索引）且不另建排序树，旧 schema-1 补建/重复迁移，五状态队首跳过 `accepted` 历史且保留 `unknown/submitting` 屏障，以及 absent/false/true、keyset 和标志变更的结果。随后重跑原定 6000 事件路由性能及受影响集成/系统门禁。诊断采样不是性能验收。

验收映射补正：八个T42真实四组合同时归A15/A16/A17/A20；T44.skill-reply.real归A17/A20；T49.direct-control.real归A13/A16/A20。A13的本地队列契约虽已过，完整无IM原生闭环仍须该真实子例，故A13恢复未勾。只补标签不改变场景、输入或断言，不能因原标签遗漏就把真实IM/Agent/回复条件自动判为通过。

写合批与提交通道回归：`T40.write-batch-{commit,isolation,failure,bound}.sqlite` 在真实 SQLite 上验证同轮微任务单次持久提交、提交后 Future 才可见、领域 Result 失败及写入后 `must(failure revision_conflict)` 均按 SAVEPOINT 单项回滚且保留同批邻项、抛错/常规同步回调返回 Future（thenable）/底层事务拒绝时整批回滚，以及 64 项有界队列与 async/事务内重入拒绝。`T31.submit-cutover.sqlite` 在外部 `submit` 入口用独立只读 SQLite 连接核验 `submitting` 已持久提交落盘，并验证 `draining` 下已进入 `submitting` 的在途回执仍可合批落盘、尚未进入 `submitting` 的同批其他 route 保持 `deferred (service_draining)` 不触发外部输入。`T16.observation-checkpoint.sqlite` 与 `T10.no-native-dedup.integration` 额外核验 `reconcileDelivery` 在单次合批回调内：`recordReceipt` 失败时不清除 `reconcile_requested`，清除 `reconcile_requested` 失败时连同回执一起按 SAVEPOINT 回滚。`T27.route-load.performance` 与 `T27.large-fanout.performance` 新增独立只读 SQLite `durablePending` 检查，停源后同时等待并断言内存 `inputs` 与持久 `deliveries/claims/routing_work` 全部排空。

事务只读复用、健康状态合批与调度配额回归：`T40.write-batch-commit.sqlite` 额外验证 `withContributionReads` 仅允许同步事务回调、仅缓存 `agents/subscriptions/connections/sessions` 四表（256 项上限，超额退回即时 `repository.get`）且返回冻结对象、拒绝 `routes`、作用域 `finally` 撤销 `read`、跨事务立即看到新值（如 `paused`/`identity_revision` 变更），以及 `repository.defineTable` 预计算 SQL 在复合键 `poll_checkpoints` 与乐观锁 `expected_revision` 上的回归；`T40.write-batch-failure.sqlite` 验证 `withContributionReads` 回调返回 Future（thenable）时回滚外层事务；`T40.pending-work-indexes.sqlite` 验证仅取 `key` 的 `pendingRows` 查询计划命中部分索引。`T12.update-cutover.sqlite` 验证同 `route` 多订阅/多事件在 `matchBatch` 下单调递增分配 `delivery_seq`，以及提交前跨事务暂停订阅或撤销主体授权时 `effectiveContributions`/`matchBatch` 读取最新状态不失效。`T41.im-ingress.integration` 验证 `readSource` 末尾健康更新经 `enqueueWrite` 合批时，单来源 `identity_revision` 失配仅回滚该来源健康项、不影响同批邻接来源健康更新，且事件持久落盘早于 `ack` 回调。`T31.cancel-before-submitting.sqlite` 验证 `queueWriteJobs` 单轮 `routes<=32`、`outbound<=16`、总在途 `jobs<=64`、连续 tick 间 `routes`/`outbound` 优先级轮换及满额余量 0 时不丢失 keyset 游标。`T27.route-load.performance` 在 6000 事件及持久排空成立后、`service.status` 前冻结 `wall_ms` 与 `actual_events_per_second`，显式断言 `actual_events_per_second >= 100`。

队列计数与回执投影热路径回归：`T40.pending-work-indexes.sqlite` 额外验证删除 `attempts_delivery`、`attempts_outbound` 与 `deliveries_route_head` 后经两次 `migrate` 幂等恢复且 `user_version=1`；验证 `queueCapacity` 单 route 五状态 `COUNT(*)` 固定 `INDEXED BY deliveries_route_head` 的查询计划命中 `deliveries_route_head`（不走 `deliveries_route_pending`），并在真实 `deliveries` 表混合 `accepted`/`failed`/`cancelled`/`expired`/`resolved` 与五种待处理状态（`ready/deferred/blocked/submitting/unknown`）时与原计数语义完全一致；验证 `delivery` 与 `outbound` 两种回执 `JOIN` 查询计划命中 `attempts_delivery`/`attempts_outbound` 与 `receipts_attempt`（不发生 `SCAN r`），且多 `delivery`/多 `outbound` 混合落库时各自仅按 `receipt_id` 顺序返回自身回执、不串行混入其他记录。`T16.observation-checkpoint.sqlite` 额外验证后台无 `context.principal` 调用 `projectDelivery` 时 `repository.get` 调用次数严格为 0 且返回字段精确等于 `minimalDelivery`，同时验证存在授权 `principal` 时完整投影（含 `session_key`/`source`/`contributions`/`receipts`）、无权限 `principal` 退回最小投影、以及事件正文 `tombstone` 失效后退回最小投影。

有序匹配写入组与单事件规划/观察元数据回归：`T40.write-batch-{commit,isolation,failure,bound}.sqlite` 额外验证 `withEventPlans` 仅允许同步事务与字符串 `event_id`、返回 thenable 时回滚事务、单事件最多缓存 128 条 `route`/`delivery`（超限退回实时查询）、惰性读取全局五状态计数一次且仅在真实 `created(delivery)` 后递增（含真实 SQLite 9999 全局待处理下单事件两不同 `route` 候选仅查询一次全局五状态 `COUNT(*)`、最多新增 1 条至 10000 并标记 `delivery_capacity` 阻塞，下一事务释放 1 个容量后重试补齐第 2 条至 10000 且不产生重复 `match_decisions` 或 `contributions`）、拒绝跨事件 `event_id` 或重复 `route` 创建、退出 scope 后撤销全部方法；验证 `matchBatch`/`matchTurn` 准备阶段复用 `connection` 调用 `eventContentAvailable`（单事件多候选仅读一次准备期 `connections` 与一次提交期 `connections`、`withEventPlans` 单事件多订阅仅读一次 `routes`）；验证 `matchTurn` 空组成功、非数组或超过 16 项拒绝且零写入、准备阶段抛错时解除所有等待 slot Future 并整组零写、乱序完成准备（`routing.before_checkpoint_commit` 延迟首事件）仍严格按输入 `ingress_seq` 顺序入队提交并分配 `delivery_seq`、混合 `not_found`/`done`/`sender_not_allowed` 早退项不挂起、单项 `revision_conflict` 仅回滚自身 `SAVEPOINT` 而邻项正常提交并仅对成功提交项发布 `routing_samples`、未知写异常整批回滚且零样本发布。`T12.update-cutover.sqlite` 额外验证 `routeEvents` 下准备阶段抛错还原 `routing_after` 并在下一轮重试成功、同 route 多事件准备乱序仍按 `ingress_seq` 顺序提交 `delivery_seq`、以及准备完成与提交之间撤权按提交点实时重检。`T16.observation-checkpoint.sqlite` 额外验证 `observeDelivery` 对非 `accepted` 状态零次读取 `attempts`/`bindings`/`instances` 提前返回，对 `accepted` 状态通过 `observationAttempt` 元数据 SQL 避免空页/游标未变时调用 `repository.get("attempts")` 反序列化 `envelope_snapshot`，兼容 `0`/`false` 等游标 JSON 值并在游标更新时重读完整 `attempt` 保留 `envelope_snapshot`。

路由候选查询与有限连续派发回归：`T40.pending-work-indexes.sqlite` 额外验证 `queueWriteJobs` 的 `routes` 候选 `EXISTS (... INDEXED BY deliveries_route_head ...)` 查询计划命中 `sqlite_autoindex_routes_1 (route_id>?)` 与 `deliveries_route_head`、无 `TEMP B-TREE` 与 `deliveries_state` 扫描，验证 `runRouteJob` 窄投影续派预检 `SELECT state FROM deliveries INDEXED BY deliveries_route_head ... ORDER BY delivery_seq LIMIT 1` 查询计划命中 `deliveries_route_head` 且无 `TEMP B-TREE`，并在含 `accepted` 历史、重复 `ready`/`deferred`/`blocked`、仅含 `accepted`/`submitting`/`unknown`、`unknown_delivery_id` 非空但有 `ready`、以及 `unknown`/`submitting` 队首后有 `ready`/`deferred`/`blocked` 的真实表上，验证预检队首状态判定（空头返回 `null`、`unknown`/`submitting` 队首原样返回不越过、`ready` 队首返回 `ready`）及跨空/中间/末尾 `after` 与不同 `limit` 下 `EXISTS` 与旧 `JOIN + DISTINCT` 查询结果集完全等价。`T31.cancel-before-submitting.sqlite` 额外验证同一 `route` 预置 6 条 `ready` 投递时，单次 `tick` 的 `runRouteJob` 岗位在目标空闲下最多连续消费 4 条（按 `delivery_seq` 严格递增且不重复），岗位退出后下一 `tick` 继续消费剩余 2 条；预置 4 条 `ready` 时第 2 条 `probe` 返回 `busy`（`deferred`）或第 2 条 `submit` 抛错（`unknown` 队首屏障）立即停止本岗位后续连续提交，未知队首未人工解除前后续 `tick` 不越过屏障，解除后仅剩 1 条 `ready` 时单次派发后预检空头直接退出（`claim_epoch` 与 `probe` 仅增加 1 次、不触发额外空头 claim 写事务）。`T31.submit-cutover.sqlite` 额外验证同 `route` 预置 2 条 `ready` 且第 1 条原生 `submit` 在途期间进入 `draining` 时，第 1 条回执照常落盘为 `accepted`，而本岗位不再启动第 2 条（第 2 条保持 `ready`、仅触发 1 次 `probe`）。

容量驱动与超时隔离回归：`tests/support/resources.eli` 导出 `runCapacitySchedule`，为 `T27.route-load.performance` 提供绝对 `start + index * 10ms` 摄取日程 producer（仅在 `delay > 0` 时等待且唤醒后循环重验目标时间 `start + index * pace_ms`，正常 `tick` 完成仅在 `in-drain-phase` 或 `stopped` 时唤醒等待器以防提前摄取；落后追赶每连续 16 条让出一次 `nativeSetTimeout(0)` 宏任务）与独立 `20ms` 周期非重入 `nativeSetInterval` consumer（与 `main.eli` 一致，上次 `tick` 未完成时跳过当前周期并计数 `tick_skipped_count`，异常或 `{ok: false}` 立即置 `stopped` 阻断后续输入与调度并作为失败传播）；内置 70 秒有界内部截止（60 秒摄取日程 + 10 秒排空预算），`finally` 中无论成功、异常或内部截止均清除全部定时器、阻止新 `ingest`/`tick`、等待在途 `tick` 完成后再执行 `closeFixture`；6000 事件与 60000 原生输入且独立只读 SQLite `durablePending` 确认 `accepted=60000`、`unaccepted=0`、`claims=0`、`routing=0` 时在 `service.status` 采样前冻结端到端 `wall_ms`，先向 `DJ_TEST_PERFORMANCE_FILE` 写入同时记录 `schedule_completed: true` 与按全部吞吐/路由门禁求值的 `status`（若 `actual_events_per_second < 100` 则如实记 `status: "failed"`、`cancel_reason: "throughput_below_target"`）后再执行 `actual_events_per_second >= 100` 等硬断言，未完成时写入 `schedule_completed: false`、`status: "failed"`、`cancel_reason`、实际计数与持久积压并抛错失败。`T70.resources.unit.physical-total` 与 `T31.cancel-before-submitting.sqlite` 覆盖 consumer 频繁完成下按时 producer 不提前摄取、落后 producer（16 条追赶宏任务让出）、单 `tick` 非重入跳过、consumer 异常传播、内部截止取消、`finally` 等待在途 `tick` 且退出后零新任务及真实 SQLite Core 排空的回归断言。四个本地 performance 用例在集中验收中通过 `tools/verify.mjs --suite performance --case <case_id>` 分别以独立受控进程串行执行，防止单题外部超时或同步阻塞污染后续性能用例的事件循环。

匹配与投递重复写收敛回归（R1–R5）：`T40.write-batch-commit.sqlite` 额外验证 `repository.insertIfAbsent` 仅允许同步事务内操作 `match_decisions` 与 `contributions` 两表（无事务或其他表抛错拒绝），使用精确复合主键 `ON CONFLICT(...) DO NOTHING`（首次插入返回 `true`，同复合主键重复返回 `false` 且不覆盖既有 `payload`，不同 `revision` 正常插入；不使用泛化 `OR IGNORE`，`CHECK`/`NOT NULL`/`FOREIGN KEY` 约束违例照常抛错）；验证 `allocateSequence` 通过单条 SQL 同时自增 `routes.next_delivery_seq` 列与 `json_set(payload,'$.next_delivery_seq',CAST(next_delivery_seq+1 AS TEXT))`（零次 `repository.replace("routes")`、保留 `>2^53` 64 位文本序号、回滚不消耗序号、`9223372036854775807` 溢出返回 `limit_exceeded` 且零变更）；验证 `withEventPlans` 第四可选参数 `complete-in-one-turn`（`planning.initial_ready`、`planning.finish(state)->needsUnlock`：一次完成新建 `ready/revision=2` 且 `finish("done")->false`，非 `done` 时恢复本轮新建投递为 `blocked/routing_incomplete/revision=1` 且不触碰既有 `ready` 投递，读到持久旧投递设置 `existing_delivery_seen` 使 `finish("done")->true`，退出后 `finish` 撤销）。`T40.write-batch-isolation.sqlite` 额外验证单轮完整匹配事件（`mt-ev-0`）通过 `insertIfAbsent` 零次调用 `repository.get("match_decisions")`/`get("contributions")`、零次 `repository.replace("routes")`/`replace("deliveries")`、零次二次解锁 `UPDATE deliveries` SQL 并直接落库 `ready/revision=2`；验证 `9999→10000` 容量阻塞（`mt-ev-cap`）时首轮 `finish("blocked")` 将本轮已建首条 `route` 投递同事务恢复为 `blocked/routing_incomplete/revision=1`，释放 1 容量后次轮重试补建第 2 条并统一解锁两条至 `ready/revision=2`；验证多轮续页（`mt-ev-paged` `max_candidates=1`）首轮落库 `blocked/revision=1`、次轮续页完成后统一解锁至 `ready/revision=2`。`T40.pending-work-indexes.sqlite` 额外验证 `beginSubmission` 队首窄查询 `SELECT delivery_id FROM deliveries INDEXED BY deliveries_route_head ... ORDER BY delivery_seq LIMIT 1` 查询计划命中 `deliveries_route_head`（无 `TEMP B-TREE`）且返回精确队首 `delivery_id`。`T16.observation-checkpoint.sqlite`、`T31.cancel-before-submitting.sqlite` 与 `T12.update-cutover.sqlite` 额外验证 `claimRoute` 单语句更新 `claim_epoch`/`claim_owner`/`payload`（`CAST(claim_epoch+1 AS TEXT)`，零次 `repository.replace("routes")` 与 64 位溢出保护）、`recordReceipt` 仅在 `claim` 匹配当前 `owner_token` 与 `attempt.claim_epoch` 时删除 `claims` 并仅在 `unknown_delivery_id` 或 `claim_owner` 实际变化时执行一次窄状态替换（无变化零次写 `routes`，外国 `claim_owner` 或新 `claim_epoch` 保持不动），以及 `beginSubmission` 同事务复用已加载 `agent` 传入 `freezeEnvelope` 并保持 `ready(revision=2)->submitting(3)->accepted(4)` 及完整信封语义。

状态窄更新与贡献/投递只读收敛回归（P1–P3）：`T40.write-batch-commit.sqlite` 额外验证 `repository.replaceProgress(table, record, expectedRevision?)` 仅允许同步事务内更新 `deliveries`（`state/revision`）、`attempts`（`state/definite_not_sent`）与 `routes`（`binding_id/claim_owner/unknown_delivery_id`）及完整 `payload`（无事务抛 `Error`，非支持表或对无 `revision` 表传 `expectedRevision` 在 SQL 前抛 `TypeError`，缺失主键或逐一篡改任意未更新 typed 列均由 `WHERE column IS ?` 守卫拦截并返回 `revision_conflict` 且零变更，兼容 `NULL`、布尔 `0/1` 与 `>2^53` 64 位字符串整型，支持乐观锁 `expectedRevision`、外层回滚与 `enqueueWrite` 单项 `SAVEPOINT` 隔离，并通过只读 `EXPLAIN` 验证 `attempts`/`routes` 窄更新零 `IdxInsert`/`IdxDelete` 且 `deliveries` 字节码减少）；验证 `repository.getSubscriptionState(subscriptionId)` 仅投影 `subscription_id/owner_principal_id/state/revision` 四列（不含 `payload` JSON 解析后的 `agent_id` 等字段，缺失返回 `nil`，空串或非字符串抛 `TypeError`，跨事务实时反映 `owner_principal_id/state/revision` 更新，原 `repository.get` 完整读取不变），以及 `withContributionReads(context, work, subscriptionStateOnly?)` 默认省略或 `false` 时走完整 `repository.get("subscriptions")`、非布尔第三参抛 `TypeError`、显式 `true` 时对 `subscriptions` 调用 `getSubscriptionState`（零次完整 `get("subscriptions")`）并保持 256 项上限、冻结、`finally` 撤销与跨事务新鲜读取。`T40.write-batch-isolation.sqlite` 额外验证 `matchBatch` 传入 `subscriptionStateOnly=true`，使两候选匹配期间 `getSubscriptionState` 调用 2 次、`repository.get("subscriptions")` 调用 0 次。`T16.observation-checkpoint.sqlite` 与 `T12.update-cutover.sqlite` 额外验证 `attachBinding`、`releaseClaim`、`holdDelivery`、`beginSubmission`、`recordReceipt`、`reconcileDelivery` 与 `observeDelivery` 均通过 `repository.replaceProgress` 更新进度且零次调用全列 `repository.replace`（含 `reconcileDelivery` 清除 `reconcile_requested` 失败时连同回执一起按 `SAVEPOINT` 回滚），并验证 `beginSubmission` 在单次 `withContributionReads(context, work, true)` 作用域内完成，对双订阅投递仅读取 `sessions` 1 次、`agents` 1 次、`connections` 1 次（`isContributionEffective` 与 `replyContext` 共享 `read`）、`subscriptions` 全列 `get` 0 次且 `getSubscriptionState` 2 次，返回 `frozen` 与持久 `attempts` 不挂载 `read`/`reader` 且保留完整 `matched`/`reply_context_id`/`allowed_actions` 与 `routes` 列/JSON 一致性。

单事件 `match_decisions` 与 `contributions` 合批写入收敛回归（W1–W3）：`T40.write-batch-commit.sqlite` 额外验证 `repository.insertManyIfAbsent(table, records)` 仅允许同步事务内操作 `match_decisions` 与 `contributions`（无事务抛 `Error`；非支持表、非数组、长度 `>128`、含空洞的稀疏数组或含 `null`/`undefined`/原语/数组元素在执行任何 SQL 前抛 `TypeError` 且 `total_changes()` 零增长，即便第 1 块 16 条合法而第 17 条为空洞或坏元素也不执行第 1 块 SQL；`0/1/16/17/128` 边界按 `<=16` 条预计算 `INSERT ... VALUES ... ON CONFLICT(<pk>) DO NOTHING` 分块执行并返回实际新增行数，对同块重复主键、跨块重复主键与已存在主键去重且不覆盖既有 `payload` 或 typed 列；保留 `CHECK`/`NOT NULL`/`FOREIGN KEY` 约束抛错，且第 2 块违例时通过外层事务完整回滚第 1 块已插入的 16 行），并验证 `planContribution(tx, event, version, decision, read?, planning?, pendingContributions?)` 第 7 可选参数省略或 `nil` 时保持立即 `insertIfAbsent("contributions", ...)`、传入非数组或 `length>=128` 在创建 `delivery` 与分配序号前抛 `TypeError`、事务外即使传入合法数组也抛错拒绝且零变更、传入合法数组时立即写 `deliveries` 并将 `ready/deferred/blocked` 投递的贡献推入 `pendingContributions`（0 次 `insertIfAbsent`，无效贡献或 `accepted` 终态投递不入队）。`T40.write-batch-isolation.sqlite` 额外验证 `matchWithWriter` 对双订阅事件 `mt-ev-0` 调用 `insertIfAbsent` 0 次、`insertManyIfAbsent` 2 次（`match_decisions` 与 `contributions` 各 1 次 2 条、底层各 1 条合批 SQL）；在 `9999->10000` 容量阻塞时首轮写入全部 3 条 `match_decisions` 与前 2 条 `contributions` 且 `last_subscription_id` 停在 `mt-sub-2`，释放 1 容量重试时第 3 候选 `match_decision` 去重返回 0、新写入第 3 条 `contribution` 返回 1；在 `>16` 候选（18 条订阅，`16+2` 分块）下，`matchTurn` 中单事件在合批写完 `deliveries/next_delivery_seq/match_decisions/contributions` 后若 `routing_work` 返回领域失败（`revision_conflict`）仅回滚该事件的 `SAVEPOINT dj_write_item` 而邻事件完整提交，若 `insertManyIfAbsent("contributions", ...)` 第 2 块触发非领域 SQLite 外键异常则整批 `ROLLBACK`（含邻事件及当前事件第 1 块已写数据）且零样本发布，恢复后重试每表每事件按 2 条分块 SQL 完整落库。`T12.update-cutover.sqlite` 额外核验多订阅/多事件乱序准备按 `ingress_seq` 提交及准备后提交前撤权（`after-revoke` 落库 1 条 `match` 决策、0 条 `deliveries` 与 0 条新增 `contributions`）的持久计数一致性。

订阅状态批读与冗余 `deliveries_route_pending` 索引收敛回归（K1–K3）：`T40.write-batch-commit.sqlite` 额外验证 `repository.getSubscriptionStates(ids)` 仅允许同步事务内调用（事务外、非数组、`length>128`、含空洞的稀疏数组或含非字符串/空串元素——即便第 1 块 16 项合法而第 17 项为空洞或坏元素——均在执行任何 SQL 前抛 `TypeError` 且 0 条 SQL 执行；空数组返回 `[]` 且 0 条 SQL；按首次出现顺序 `Set` 去重后以 `1..16` 预计算 `SELECT subscription_id,owner_principal_id,state,revision FROM subscriptions WHERE subscription_id IN (?,...,?)` 分块执行，覆盖 `0/1/16/17/128` 边界与 20 项含重复/缺失去重后归并为单块 16 项查询，仅返回实际存在的四列对象且不解析 `payload`、缺失键不伪造空行、同事务/跨事务实时反映 `owner_principal_id/state/revision` 变更，原 `getSubscriptionState` 保持不变），并验证 `withContributionReads(context, work, subscriptionStateOnly?, subscriptionIds?)` 第四可选参数非空时强制要求 `subscriptionStateOnly === true`（否则在 SQL 前抛 `TypeError`）、进入 `work` 前一次调用 `getSubscriptionStates` 预填冻结四列对象并把缺失 ID 负缓存为 `nil`（`work` 内读已预加载存在/缺失 ID 时 `getSubscriptionState` 与 `get("subscriptions")` 调用均为 0 次，读未预加载 ID 回退单键 `getSubscriptionState`，保持 256 项上限、禁止 `routes` 与 `finally` 撤销）；`T40.write-batch-failure.sqlite` 额外验证带 `subscriptionIds` 预加载的 `withContributionReads` 返回 thenable 时回滚外层事务。`T40.write-batch-isolation.sqlite` 额外验证 `matchWithWriter` 提取 `plan.answer === "true"` 的 `subscription_id` 列表并在写事务内传给 `withContributionReads(..., true, subscriptionIds)`（双订阅事件 `mt-ev-0` 调用 `getSubscriptionStates` 1 次/1 条 `IN (?,?)` SQL、`getSubscriptionState` 0 次、全列 `get("subscriptions")` 0 次；18 订阅双事件 `mt-ev-5`/`mt-ev-6` 调用 `getSubscriptionStates` 2 次/4 条 `16+2` 分块 SQL、`getSubscriptionState` 0 次；全 `no_match` 事件 `mt-ev-nomatch` 传入 `[]` 执行 0 条订阅 SQL 并落库 18 条 `no_match` 决策）。`T16.observation-checkpoint.sqlite` 额外验证 `effectiveContributions` 通过 `SELECT c.payload,c.subscription_id AS contribution_subscription_id,s.subscription_id AS current_subscription_id,s.owner_principal_id AS current_owner_principal_id,s.state AS current_state,s.revision AS current_revision FROM contributions c LEFT JOIN subscriptions s ON s.subscription_id=c.subscription_id WHERE c.delivery_id=? ORDER BY c.subscription_id,c.revision` 流式 `:iterate/:next/:return` 与行局部 `item-read` 完成提交前重验（`beginSubmission` 对 `subscriptions` 的 `get`/`getSubscriptionState`/`getSubscriptionStates` 调用均为 0 次，对单 delivery 跨页累积 `135` 条贡献——含 `131` 条有效、`1` 条 `paused->revoked`、`1` 条 `revision` 失配 `->revoked`、`1` 条过期 `->expired`、`1` 条撤权 `->revoked`——在 `matched-bytes > native_frame_max_bytes` 时第 6 步提前停止迭代并调用 `rows.return()` 置 `blocked/limit_exceeded`，正常预算下流式产出全部 `131` 条有效 `matched` 不受单轮 128 候选上限截断并准确回写 4 条 `expired/revoked`）。`T12.update-cutover.sqlite` 额外验证 `routing.before_checkpoint_commit`（准备与 `subscription-ids` 提取完成后、写事务提交前）暂停订阅时，写事务内 `getSubscriptionStates` 读取最新 `paused` 状态，仅落库 1 条 `match` 决策而 0 条 `deliveries`/`contributions`。`T40.pending-work-indexes.sqlite` 额外验证新库不创建冗余 `deliveries_route_pending`、模拟含 `deliveries_route_pending` 的旧 `schema-1` 空库与已写入 26 条 `deliveries` 的非空库经两次 `migrate(db)` 先确保 `deliveries_route_head` 再幂等 `DROP INDEX IF EXISTS deliveries_route_pending`（`user_version=1`、数据零丢失、`UNIQUE(route_id,delivery_seq)` 重复序号照常拒绝、`delivery.list` 主键与 `deliveries_state` 分页计划无 `TEMP B-TREE`，且只读 `EXPLAIN` 证实移除 `deliveries_route_pending` 后 `deliveries` 插入与 `replaceProgress` 窄更新的 `IdxInsert/IdxDelete` 字节码减少）。

实体主键时间局部性回归（U1–U3）：`T38.entity-ids.unit` 在 `tests/unit/identity.test.eli` 验证 `entityUuidV7(milliseconds, randomUuid)` 固定向量（`0`、48 位上限 `281474976710655`、`1792851600000` 及 `8/9/a/b` 四种 RFC 9562 variant）、同毫秒相近键前缀区间（`xxxxxxxx-xxxx-7`，不假设同一 4KiB B-tree 页或生成顺序单调）下对输入 `randomUuid.slice(15)` 的 74 位 CSPRNG 随机尾位逐字符原样保留且无内部 counter 或跨调用状态（同输入重复调用幂等，无全局共享计数器仅代表 `ids.next` 无共享计数状态而不代表消除一切吞吐推断）、跨毫秒同前缀字典序与时钟回拨保留实际时间戳（不夹紧或取整）、先校验 `milliseconds` 合法范围（对 `-1`/`-0.0001`/`1.5`/`281474976710656`/`9007199254740991`/`9007199254740992`/`NaN`/`±Infinity`/非 number 在检查 `randomUuid` 前抛 `RangeError`）再校验小写标准 UUIDv4 字符串（非 string、长度不符、大写 hex、非 `4` 版本位、非 `8/9/a/b` variant、缺连字符或非法字符抛 `TypeError`）；同时验证 `nextHostId(prefix)` 与 `createHostPorts().ids.next` 严格接线：仅 `event`/`delivery`/`attempt`/`receipt`/`binding`/`reply_context_record`/`route`/`agent`/`subscription` 九个精确实体主键前缀读取宿主 `Date.now()` 与 `crypto.randomUUID()` 生成 UUIDv7（异常时钟直接传播不吞错不回退），其余控制/幂等/受限句柄/未知/大小写或后缀不匹配前缀（`owner`/`launch`/`epoch`/`dispatch`/`outbound_dispatch`/`lifecycle_dispatch`/`preview`/`req`/`create`/`snapshot`/`catalog`/`outbound`/`part`/`lifecycle`/`instance`/`ingress_rejection`/`reply_context`/`message`/`cursor` 等）原样生成 UUIDv4 且不读取 `Date.now()`，默认 `createHandleAuthority` 全部 `handleKinds` 继续签发独立 UUIDv4 并照常执行主体/版本/TTL 校验。`T40.mixed-entity-ids.sqlite` 在 `tests/integration/storage.test.eli` 验证真实 SQLite 下既有 UUIDv4 与新 UUIDv7 实体主键混存：静态混合 `agent.list`/`subscription.list`/`delivery.list` 按不可变键全序完整无重复分页，而 `delivery.list` 打开游标后并发插入 `<= 当前 cursor` 的较小键不要求进入已打开的旧游标续扫、重新发起新查询则完整包含全部行；同 route 混合 `v4-high(seq 1)`、`v7(seq 2)`、`v4-low(seq 3)` 投递严格按 `delivery_seq` 顺序派发（不由 `delivery_id` 字典序决定），持久 `attempt_id`/`receipt_id`/`reply_contexts.reply_context_id`（`reply_context_record_...`）为 UUIDv7 而 `dispatch_key` 与信封 `reply_context_id`（`public_ref`）保持 UUIDv4，无权主体 `"X"` 读取与裸内部 `reply_context_record_...` 回复照常拒绝；通过公开 `delivery.reconcile`、`f.tick` 与 `delivery.get` 验证后台 `pendingRows` 游标推进至末尾高键 `delivery_ffffffff-...` 后遇到空页从 `""` 回绕并处理较小的新 UUIDv7 投递（不导出 `pendingRows`，也不宣称持续任意外部写入下的绝对等待上界）；构造重复 `delivery_id` 验证触发 SQLite `PRIMARY KEY` 唯一约束返回 `storage_unavailable`、操作台账原子回滚且既有记录不被覆盖。

tick 内有界第二轮派发回归（J1–J3）：复用 `tests/integration/delivery.test.eli` 的 `T31.submit-cutover.sqlite` 与 `T31.cancel-before-submitting.sqlite`（不新增 `tests/cases.json` 子例 ID），在真实 SQLite Core 上验证：（J-A1）预置 64 条独立 `ready` route（每条 4 条 `ready` 投递，共 256 条）与 32 条 `ready` outbound 时，单次 `f.tick()` 在两轮 `queueWriteJobs` 内完成全部 256 条 route 投递（按每 route `delivery_seq` 严格递增且不重复、外部 `submit` 入口前 `deliveries/attempts.state='submitting'` 已持久落盘）与 32 条 outbound（持久与公开 `outbound.get` 终态均为 `'accepted'`），单轮并发 `jobs<=64`（`routes<=32`、`outbound<=16`）、两轮之间经一次 `0ms` 宏任务让出且不产生第 3 轮；（J-A2）保留第 1 轮在途满额 `jobs=48/64`（`dispatched=0`）不进第 2 轮的旧语义，并验证同 tick 内第 1 轮与第 2 轮分别使用 `routeFirst` 与 `!routeFirst` 翻转角色优先级，而 `runtime.write_route_first` 每 tick 仅翻转一次（连续两个均触发两轮的 tick 的第 1 轮首角色交替为 `routes` 与 `outbound`）；（J-A3）从空游标起扫且返回行数 `< budget`（1 条 route `<32`、0 条 outbound `<16`）时 `scan.from_start=true` 使 `wave1.more=false`、每个角色候选 SQL 仅执行 1 次且不进入第 2 轮，而第 1 轮满 32 条 route（其中 1 条预置 6 项消费 4 项余 2 项 `ready`、1 条预置 2 项第 2 次 `probe` 忙余 1 项 `deferred`、其余 30 条各 1 项全部 `accepted`）触发第 2 轮从空游标回绕再次扫出该 2 条 route 时，按本 tick `seen` 集合去重跳过，不启动第 2 个同 tick 岗位、不增加 `probe` 或 `claim_epoch`；（J-A4）34 条 `ready` route 下第 1 轮 32 条产生 1 条 `unknown` 与 31 条 `deferred`（`wave1.dispatched=0`）时不进入第 2 轮（剩余 2 条保持 `ready`），第 1 轮原生 `submit` 在途进入 `draining`（`T31.submit-cutover.sqlite`）或第 1 轮完成 32 条后在两轮间 `0ms` 宏任务让出期间触发 `core.stop` 进入 `draining` 或 `service_lease.owner_token` 失配（返回 `owner_conflict`）时均阻止第 2 轮启动（剩余 2 条保持 `ready`）；（J-A5）`source_progress` 更新触发 SQLite `ABORT` 使 `runtime.storage_blocked=true` 发生在第 1 轮前或发生在两轮间 `0ms` 宏任务让出期间时，第 1 轮已启动的 32 条 route 正常提交为 `accepted`，而第 2 轮被 `!runtime.storage_blocked` 守卫阻断（剩余 2 条保持 `ready`，时钟推进 1000ms 重探恢复后下一 tick 排空）。

单事件投递批量创建与派发窄读回归（L1–L3）：复用 `T40.write-batch-{commit,isolation,failure}.sqlite`、`T40.pending-work-indexes.sqlite`、`T16.observation-checkpoint.sqlite` 与 `T12.update-cutover.sqlite`（不新增 `tests/cases.json` 子例 ID），验证：（L-A1）`repository.insertMany(table, records)` 仅允许同步事务内操作 `deliveries`（事务外抛 `Error`；非 `deliveries` 表、非数组、`length>128`、稀疏数组空洞或含 `null`/`undefined`/原语/数组元素在执行任何 SQL 前抛 `TypeError` 且 `total_changes()` 零增长，即便第 1 块 16 条合法而第 17 条为空洞或坏元素也不执行第 1 块 SQL；`0/1/16/17/128` 边界按 `<=16` 行严格 `INSERT INTO deliveries(...) VALUES ...` 预计算 SQL 分块执行，写入 12 列与 `payload` JSON 并返回实际插入条数；不使用 `OR IGNORE`/`ON CONFLICT`，对重复 `delivery_id`、重复 `(route_id,delivery_seq)`、`CHECK`/`NOT NULL`/`FOREIGN KEY` 违例照常抛错，且第 2 块违例时通过外层事务或 `SAVEPOINT` 完整回滚第 1 块已插入的 16 行）；（L-A2）`withEventPlans(context, event, work, completeInOneTurn?, bufferDeliveries?)` 第 5 可选参数默认 `false` 保持原即时落库语义，显式 `true` 时暴露 `planning.defer_insert = true`，将新建 `delivery` 暂存于单事件内存并在 `finish(state)` 中统一规范化终态（`done` -> `ready/revision=2/blocked_reason=nil`，非 `done` -> `blocked/revision=1/blocked_reason="routing_incomplete"`）后调用 `repository.insertMany("deliveries", created-records)` 一次批量落库（0 次单行 `repository.insert("deliveries")`），不修改通过 `planning.delivery` 读取的既有持久记录，缓存满 128 项或第 129 次 `created(delivery)` 在 SQL 前抛 `TypeError`，同事件未持久化 `created(delivery)` 实时计入全局五状态容量（`9998 + 2 = 10000` 拒绝第 3 条）与同 route 待处理容量（`999 + 1 = 1000`），`finish` 仅允许调用一次且成功后撤销全部 `planning` 方法，缓冲模式下 `work` 未调用 `finish` 即成功返回时抛 `TypeError` 回滚、返回领域失败 `Result`（`ok===false`）时允许直接退出并由 `SAVEPOINT` 回滚，回调返回 thenable 时回滚外层事务（`T40.write-batch-failure.sqlite`）；（L-A3）`planContribution` 在 `planning.defer_insert === true` 时在分配 `delivery_seq` 前强制要求同步事务与合法 `pendingContributions` 数组（省略/`nil`/非数组/`length>=128` 抛 `TypeError` 且不消耗序号），新建 `delivery` 仅经 `planning.created(delivery)` 暂存（0 次 `repository.insert("deliveries")`），同事件后续同 `(event_id, agent_id)` 贡献直接复用该缓冲 `delivery`（不重复分配 `delivery_seq`），且跨页既有持久 `delivery` 由 `planning.delivery(route_id)` 命中返回且不被 `finish` 内存态重写；（L-A4 & L-A5）`matchWithWriter` 传入 `bufferDeliveries = true`，先计算 `current.state` 再调用 `planning.finish(current.state)` 使 `insertMany("deliveries")` 严格先于 `insertManyIfAbsent("match_decisions")` 与 `insertManyIfAbsent("contributions")` 执行（保证 `contributions.delivery_id -> deliveries.delivery_id` 外键成立），覆盖单事件 2 路与 18 路（`16+2` 分块）批量创建、`9999->10000` 容量阻塞首轮以 `blocked/revision=1` 批量落库首条并在释放容量重试后经解锁 `UPDATE` 恢复 `ready/revision=2`、既有持久 `blocked` 投递与新建缓冲投递同事件共存时 `finish("done")->true` 解锁既有行、分块外键异常或领域失败回滚，以及 `T12.update-cutover.sqlite` 同 route 双订阅（准备后暂停 `A` 的订阅但保留 `O` 的订阅）各自独立重检 `owner/revision/expires_at` 不跨订阅串用有效性结论；（L-A6）`claimRoute` 使用 `SELECT delivery_id,state FROM deliveries INDEXED BY deliveries_route_head WHERE route_id=? AND state IN ('ready','deferred','blocked','submitting','unknown') ORDER BY delivery_seq LIMIT 1`（查询计划命中 `deliveries_route_head` 且无 `TEMP B-TREE`，0 次 `SELECT payload FROM deliveries WHERE route_id=? ...`），在空队列、仅 `accepted` 历史、`submitting` 队首、`unknown` 队首与 `ready` 队首上保持原屏障语义，且导出 `selectHead` 仍返回完整解析后的队首 `delivery` 对象；（L-A7）`beginSubmission` 对 `subscription_event` 投递使用窄查询 `SELECT state FROM routing_work WHERE event_id=?`（0 次 `repository.get("routing_work")`），在 `routing_work` 缺失或 `state !== "done"` 时置 `blocked/routing_incomplete` 并释放 claim，在 `state === "done"` 时正常推进冻结提交。


tick 内第二组匹配准备回归（N1–N2）：复用 `T31.cancel-before-submitting.sqlite` 内受控嵌套 fixture（不新增 `tests/cases.json` ID，不新增跨 case 辅助）；routing 计数与抛错只匹配 `SELECT payload FROM routing_work WHERE state IN ('ready','held','blocked') AND ingress_seq...`，不把 `runtime.eli:264` 的 `SELECT COUNT(*)` 背压查询计入。N-A1：32 事件/32 route 单 tick 两组各 16，routing 扫描=2、routes/outbound 扫描各 2、32 done/32 accepted/无待处理/claims=0、in_flight=0；首个 `peer.submit` 入口由独立只读 SQLite 连接核验该 delivery 与 attempt 已持久 `submitting`，finally 恢复原 submit。N-A2：32 事件同一 route，本 tick 4 accepted/28 待处理、routing/routes 扫描各 2、claims=0；下一 tick accepted=8、待处理=24，`claim_epoch` 精确 +8（每 tick +4），保持四步上限。N-A3a：18 事件全 busy，probe=16、routing 扫描=1、done16/待处理2、inputs=0；N-A3c：18 事件下 16 个首组 submit 抛错形成 unknown，零 accepted 时 routing 扫描=1、done16/待处理2，随后在本 fixture 内逐个 `delivery.resolve(abandon_no_retry)`；N-A3d：18 事件下首组 probe 全部挂起、零 accepted 时 routing 扫描=1，释放 waiters 后有界 tick 至 `in_flight=0`，finally 释放全部等待并关闭；N-A3b 单事件短页仅 1 次 routing 扫描、accepted=1。N-A4 gate：0ms 让出期间分别 drain（`core.stop`，状态 draining/stopped）、异主（本 fixture `service_id`+原 `owner_token` 更新 `changes=1`，finally 恢复）、storage（`source_progress` 触发器）→ routing 扫描=1、routes 扫描=1、Wave 1 accepted=16；owner 返回原 `owner_conflict`；drain 恢复为至多 16 次公开 `core.stop` 并硬断言 stopped。N-A4 second：第二组 await 期间 drain（fault 内 `core.stop`）、异主（fault 内独立连接改租约，`changes=1`，finally 恢复）、storage（`WHEN NEW.ingress_seq>16` 的 `routing_work` UPDATE 触发器）→ routing 扫描=2、routes 扫描=1、第二轮不启动；drain/owner 组后 done=18，storage 组后 done=16+2 待处理，移除触发器并推进时钟后下一 tick 达 18。N-A5：首组 `routeEvents` 级 Result 失败（`routing_work` UPDATE 触发器）恢复游标、done=0、无第二组，移除后下一 tick 达 18 done/18 accepted；第二组 Result 失败同样不派发第二轮并从 16 恢复至 18；第二组真实抛错改为在**第 2 次** routeEvents payload 扫描处由 `Database.prototype.query` 抛错（位于 `routeEvents` try 之外），断言 tick 被拒绝、首组 16 done，恢复后下一 tick 18 done/18 accepted；组内单项 `revision_conflict` 另设 18-route tick 级场景：在首个 before_checkpoint hook 用独立连接暂改该 work 的 `payload.last_subscription_id` 造成 checkpoint mismatch，该事件无 delivery/decision/contribution 且保持 ready，其余 15 项成功、Wave 1 有进展，第二组 2 项仍准备并派发（routing 扫描=2，accepted=17），恢复原 payload 后下一 tick 达 18；`T40.write-batch-isolation.sqlite` 的既有 `matchTurn` 空组、>16 拒绝与 `success(results)` 内单项 `revision_conflict` 断言继续作为匹配层证据，不冒充新增 tick 覆盖。N-A6a：16 work 中首个 work 注入同一 `revision_conflict` 保持 ready；第二组尾空页后回绕仍选中它，但 tick 局部 seen 阻止第二次 match 尝试（该 event 的 before_checkpoint 访问计数=1），routing 扫描=3、routes 扫描=3、done=15/待处理1、该事件 0 delivery；恢复 payload 后新 tick 新 seen 完成至 16 done/16 accepted（访问计数=2）。N-A6b：32 事件反序映射使第二组创建更低 route key，routing 扫描 2–4、最终 32 done/32 delivery、`COUNT(DISTINCT delivery_id)=32`、accepted=32。容量保护沿用 integration47 已真实通过的既有 L/T40 10000/1000 断言，不冒充新增两组压力实测。N-A7 仍由 D 统一构建、75 unit/25 system/其余 844 integration 的精确范围复用决定与四项 performance 串行验收；不声称未运行已通过。


在途存储调用与安全停止回归（V1–V2）：沿用 `T31.cancel-before-submitting.sqlite`，不新增 case ID。V-A1：N-A4 gate-drain/second-drain 保留未来 deadline，捕获并发 `core.stop` 的 Promise，断言 tick 仍在途时返回 `state="draining"`，随后 `connection.list` 仍可读，tick 正常 Result 且第二轮不启动，最后有界 stop 硬断言 stopped。V-A2：N-A5 第二组 payload 扫描真实抛错恢复后，以及首组/第二组 Result 失败、组内 revision_conflict 恢复后，显式 `nStopToStopped` 硬断言，证明计数释放且不吞原异常；owner 失败保持原 restart 用例。V-A3：三个轻量独立 fixture 分别让 `ingest` 停在 `event.after_commit_before_ack`、`execute(agent.probe)` 停在 native probe、`reloadConfig` 停在 `host.files.mkdir`；挂起时 future-deadline stop 返回 draining 且 `connection.list` 仍可读，释放后原 Result 按合同完成（ingest ok、probe ok、reload `state="reloaded"`），最终 stop 为 stopped；barrier/fault/`files.mkdir` 均在 finally 恢复。V-A4：在本 fixture 自有 opencode agent port.close 上装 barrier，stop 进入最终 close 等待后，`tick`/`ingest`/`execute(connection.list)`/`reloadConfig` 全部返回既有 `unavailable`，且 `files.mkdir` 计数保持 0、无 native/fault 动作；释放 close 后 stop 正常 stopped，finally 恢复 close。V-A5a：port.close 首次返回 `{state:"draining"}`，stop 原 Result 保持 draining；恢复 close 前 tick 与 `connection.list` 在 draining 仍成功，第二次 stop 达 stopped。V-A5b：port.close 首次抛受控异常，调用方 await/catch 到原异常；未关闭 store 时 tick/`connection.list` 仍成功，恢复后后续 stop 达 stopped，不留未消费的 stop Promise。V-A6：仅文档登记 D 待跑；core 生命周期影响全局，后续需完整 75 unit/845 integration/25 system 与四项独立 performance，不沿用旧 844 复用结论。所有新增 loop 有界、case timeout 保持 30s，布尔使用 t/false，生产 core/runtime 未改、未运行。

N-A4第二组失主断言按真实事务owner守卫对齐：准备hook变更owner后，原owner不得提交第二组；应为16项done、第二组2项保持待处理，且第二组delivery与match_decision均为0。post-await仍返回owner_conflict并阻断第二轮；不能要求失主后先落盘18项再报错。此为D待复验断言，非预先通过声明。

V-A1两处drain期间tick现显式断言Result.ok=true；V-A4最终封闭窗口额外对比fault visits与native inputs无增长，保持mkdir=0。此为独立D覆盖发现的补强，待当前冻结定向复验，不改变生产或性能目标。


连接临时子日志策略回归（Y1–Y2）：复用 `T40.wal-fault.sqlite` 与其 `.backup-wal`、`T40.write-batch-commit.sqlite`/`T40.write-batch-failure.sqlite`，不新增 Case ID、不改 cases.json。Y-A1：对 setup 的真实 `openStore` 连接读取 `PRAGMA temp_store` 必须为 2；由 `PRAGMA database_list` 取得主库路径后，另建独立 raw 连接显式设 `temp_store=FILE` 并断言为 1，且不影响受测连接；再次 `openStore` 同一库仍为 2，`journal_mode=wal`/`synchronous=2`/`foreign_keys=1`、`user_version=1` 与既有数据（counters 行）保持不变；backup-wal 用例中由备份恢复的 `openStore` 连接同样为 2、备份数据与 integrity 不变。Y-A2：用 `Database.prototype.run` 精确拦截 `PRAGMA temp_store=MEMORY` 抛错，以及用 `Database.prototype.query` 对 `PRAGMA temp_store` 返回 temp_store=1；两次 `openStore` 均须 `ok=false`/`storage_unavailable`，不返回 store、不降级；try/finally 恢复原型后正常 `openStore` 为 2 且 counters 可读，原库/版本/数据未变。Y-A3：`T40.write-batch-commit.sqlite` 在独立表预置 64 行×4KiB，单批三项中间项以单条 UPDATE 修改全部 64 行后返回 `revision_conflict`，仅该 SAVEPOINT 回滚，前后成功邻项提交；逐行验证完整旧值及邻项新值、事务计数=1、Promise 在 COMMIT 返回后才可见、`temp_store=2`。`T40.write-batch-failure.sqlite` 在独立 CHECK 表预置 64 行×4KiB，单批三项中间项以单条多行 UPDATE 在末行触发 CHECK，三项均 `storage_unavailable`，全部 64 行旧值完整保留且前后邻项零残留、`temp_store=2`。原 FK/NOT NULL/unique/后块回滚及 64KiB 以下既有断言全部保留。Y-A4：沿用现有 storage WAL/backup/future-schema 与完整 system 恢复/安全停止用例作为提交切点、submitting/unknown 与拒绝新 schema 的覆盖，不由 temp_store 断言替代。Y-A5：B 全写齐、C 实现后冻结，受控完整 75 unit/845 integration/25 system、独立审核及四项 performance；6000/60000/FULL/100EPS/持久空队列门槛不变，失败保留。所有 raw/临时 statement 及时 close/finalize，故障注入只经真实 run/query 接线并在 finally 恢复。


提交期 EchoGate 再检的规划收尾回归（EG1–EG2）：复用 `T40.write-batch-isolation.sqlite`，在独立 `eg-` 连接/会话/route/agent/subscription/versions/source/events/operations/outbound 命名空间中验证，不新增 Case ID 或共享 helper。EG-A1：初始 echoState=clear 的事件，`routing.before_checkpoint_commit` 内用独立事务插入匹配 echo_gate；`matchBatch` 返回 ok，routing_work 为 `held`/`reason=echo_gate`、原 cursor 不变、hook 确实执行，且该事件无新 delivery/decision/contribution。EG-A2：同类 clear 事件在 hook 中插入精确 connection/native_message_id 的 echo_index；`matchTurn` 以正常 no_match 邻事件在前、echo 目标在后同批，两项均 ok，邻事件 done 并按原语义落库决策，目标为 `done`/`own_echo` 且无新 delivery/decision/contribution，证明遗漏 finish 不再触发缓冲成功守卫导致的非领域整批回滚。EG-A3：held 竞态事件预置 `blocked/routing_incomplete/rev1` 投递与非空 last_subscription/revision；提交前出现 gate 后，routing_work held/echo_gate、cursor 不变、原 blocked 投递 typed 列与 payload 逐字段不变、无 ready 解锁 SQL。EG-A4：在 echo 早退分支对目标 routing_work 的 replace 注入 `revision_conflict`，同批前邻正常 done；目标返回原错误码且 routing_work 保持 ready、已有投递/cursor 回滚，邻项提交；hook 独立事务写入的 echo_gate 仍存在，证明其不属于当前 SAVEPOINT。所有 fault/spy/query 包装 finally 恢复，循环有界；保留原未知异常整批回滚、准备前 gated 与既有全部断言。EG-A5 由 D 在 C 修改后新冻结执行完整 75 unit/845 integration/25 system、独立审核和四项 performance；旧 build88/performance25 失败不改写，不降低 6000/60000/FULL/100EPS/256MiB 门槛。

EG D整合：独立eg夹具放在旧T40断言之后，使用独立EG-R recipient；no_match邻事件在chat-2且保留两订阅候选，晚到gate仅作用chat-1，避免把邻项一起held。每个向量finally删除本夹具echo事实并恢复fault/spy，hook标志逐次重置且安装前断言事实为空；SQL spy保留原db receiver，既有9003号投递由route序号9003覆盖。恢复原case括号并修正新hook声明作用域。仅测试夹具修正，EG-A仍待新冻结执行。

EG-A4 D断言对齐：初始routing_work未持久化reason键，回滚后缺失仍应缺失；改为对比before-4完整记录，而不是将undefined误断言成null。state/cursor/原领域码与邻项提交等原断言保留，业务源码不变。


同组匹配容量计数复用回归（G1–G2）：原固定搭档写入G-A1/A3/A6后两次正式交回仍缺A2/A4/A5，root接回同一三文件所有权，现已一次补齐整个B源码，未编译、测试或静态预检。全部复用T40.write-batch-isolation.sqlite的独立g块，不改cases.json/旧断言/helpers。G-A1两组16事件各一次global COUNT、单route逐事件COUNT、matchBatch真读、空/no_match不读；同一route的两订阅合并，33事件为33 deliveries、66 decisions/66 contributions。G-A2真实五状态9998→10000以及同route999→1000，后续事件阻塞且不超限；临时填充行finally清理。G-A3中间/首/末项revision_conflict及新组重读，失败项原序号/投递/决策/贡献回滚，邻项提交。G-A4真实17条contributions第二块FK异常整批回滚、原COMMIT注入失败后新组真读，echo/no_match零COUNT。G-A5暂收本测试queueMicrotask flush，60+16仅前4接纳、64+16全拒绝，原64上限和全部Future终态可观测，finally恢复并执行尚挂起的自有回调。G-A6在真实打开事务中检查非法state的TypeError、work/SQL零调用，成功发布实际数值、关闭planning/共享state、failure/domain异常/thenable/漏finish均失效。G-A7待全部C后集中D，源码写齐不表示已通过。


授权部署物理资源捕获回归（M1–M3）：`T70.resources.unit.capture-controller`（unit，10000ms）覆盖 144 字节 usage 固定向量（RSS 1024/physical 2048/出生 `9007199254740993`）、坏类型/短 buffer/超安全整数拒绝；capture request 合法与 operation/run_id/标识/时长/间隔/关联非法；capture binding 合法四角色、authorized false、空 roots、重复 pid、跨类别 roles；`driverStdoutLimit` measurement=8388608、其他=1048576；fake reader/clock 在内存推进 601 点（0..60000，100ms）经 `captureOwnedDeployment` 后由原 `summarizeResources` 接收，不等待真实一分钟，也不作真实部署证据。`T70.resources.integration.native-reader`（integration，15000ms）用当前测试 process.pid 打开真实 libproc reader，两次 read 核 pid/uid/execPath/出生稳定/安全非负 RSS 与 physical，非法 pid 与 close 后 read 拒绝，finally close；在 `.local/tests` 私有 0700 目录/0600 文件上验证合法 binding、0666、符号链接、路径逃逸、>64KiB、authorized false 均拒绝并清理；ReadableStream 合法请求与坏 JSON；`handleResourceRequest` 用 fake runtime 核 request_id/run_id/operation 与 complete。仅自身只读、不贴部署角色、不运行 60 秒、不启动 Agent/IM；M-A5 的 build/947 范围、真实 256MiB/T27 与其余 14 controller 仍待 D/真实资源。

M B由root在原Go168明确部分交回且进程清理后接回补齐：request/binding/stream全边界、601点模拟与早timer/迟到/缺口/回退、后代/孤儿/退出/复用/嵌套外部根独立分类、33进程/截断/UID权限失败，以及真实CLI失败的安全输出/自有child收尾。所有测试先写未运行；模拟数据和自身libproc均不构成真实部署256MiB证明。原B部分字节副本与交回说明保留。

S3 OpenCode 只读原生观察 O1–O3：`T38.opencode-observer.unit`（unit，15000ms）以隔离 fetch 覆盖三操作关联/冻结参数、未授权/URL/认证/targets 校验、首 HTTP 前拒绝、direct/native-start/empty 成功、错 run/tool/identity、重复 native 证明、跨 session/part、非 JSON/UTF8、分页 64+1 与第二页 assistant parent、重复 cursor/message id、16 页/1024 行、2MiB/8MiB、HTTP/version/deadline/fetch 失败和全部 GET/redirect:error；`T38.opencode-observer.integration`（integration，30000ms）使用本测试自有 loopback `Bun.serve`、真实 fetch、编译后 controller CLI 与 `.local/tests` 私有 0700/0600 绑定，覆盖关联/Basic/路径、empty 真实 HTTP 身份（projectID/directory/session_key/instance）不符、symlink/组读/缺失/超 64KiB 绑定、分块/多 JSON/超限/非法 UTF8 stdin 与 cancel、CLI 固定错误和秘密/正文不回显，finally 只回收本次服务、子进程与目录。两者均不执行真实模型/外部服务；`T51.empty-create.real` 新增 session.get 地址解析，只把 native_session_id 交给 observer 并核对 session_key。

O D证据对齐：build106 unit43的77项与integration62新O项通过，174/175独立审核已采用root补齐B及五组必需断言。新增断言精确覆盖错instance/未授权native ID前置零HTTP、两反向origin/错assistant session、完整元数据与正文不回显、CLI exit1/固定stderr/null关联字段、1024成功与第17页的1025组合拒绝，并覆盖第二页parent/不透明cursor/超限reader取消。949为既有字节不变范围的组合覆盖；真实endpoint/凭据/资源验收仍未运行，不能由本地fixture替代。

### Lark 验收控制器 LI1–LI3 测试编写

新增 `T38.lark-acceptance.unit` 隔离组件用例与 `T38.lark-acceptance.integration` 真实文件/SQLite/自有子进程集成用例。前者覆盖请求/绑定冻结、精确目标与用户、刺激模板、原生幂等键、unknown 先持久且不盲重发、已有 ID 只读恢复、原始父消息/话题/全部回复关联及分页/字节/期限边界；后者覆盖独立日志标记、双连接提交可见性、唯一创建、状态转换、重开未知记录、typed/payload 一致性、外来库不变、保护文件与真实 pipe/超时/取消回收及固定错误 stdio。共享 factory 不执行网络或 CLI。Lark realRelay 追加 connection 与原始父消息，Telegram 的四字段参数保持原义。全部 B 源码先写，C 全齐之后才运行；这些本地用例不证明真实 Lark 用户态 API 或获准 chat/topic 已验收。

LI D本地终态：build109/unit45/integration65及177/178独立审核通过。补齐chat非选中其他话题噪声、thread容器与允许root、sibling/selected错thread拒绝、confirmed已删消息不重发、16成功/17唯一目标拒绝及有效保护绑定下非法stdin隔离。保留build107错误应用标记失败；main先解析请求的原顺序未变。真实资源仍not_run。

### PO1–PO3 只读原生日志与共享观察入口（B已写，未运行）

新增T38.pi-observer.unit隔离Pi v3 header/parent树与当前delivery/run证明、两平台分流和direct-control目标授权/地址重检；新增T38.pi-observer.integration连接真实受保护文件、局部文件系统变化与handle finally、固定8MiB尾窗/行界、实际controller stdio与本地HTTP O分支。fixture只构造原生格式，不读真实Pi日志或占用RPC。源码全部先写，不在B运行或编译。旧OpenCode与新增T49.direct-control.pi.real共享相同无IM/direct/原生证据断言；helper显式导入waitStarted，原control在T49前已单独导入，并无旧缺失导入故障。真实case默认需现有real授权，目标authorized/allow_model_work和原生地址必须准确；新增源码不等于实际模型/平台验收。

PO独立179审核未发现两工具确定实现错误，D阶段补齐：同user的两个合法assistant按追加顺序选首个（夹杂无效候选）；文件指纹不变但返回正数短读时拒绝且关闭handle；native/pi两个合法保护绑定超过64KiB拒绝。既有9MB Unicode旧行已使尾窗起点位于行中间，现额外显式断言起点前非LF及保留entries精确等于目标尾部，避免把它与恰好LF的另一向量混淆。补强后统一重冻复验，原build113通过和审核记录保留。

PO本地D终态：build115、unit48完整79/79（1182断言）、integration68 PO 1/1（98断言）通过；180已核收179四项必需补强和截断向量事实更正，无新确定缺陷。953为79+849+25的未变范围组合覆盖，真实Pi/IM/模型与四组合仍未运行。

OpenCode 现有 Desktop 分页修复：复用 T63.opencode-native-read.integration，验证 limit/before 不透明游标、超响应预算逐次缩页、单条仍超限 partial、无 POST；功能通过后复用 T38.native-access.unit 保护跨会话及非法游标在网络前拒绝。真实输入只发一次，观察超时后只读同一原会话，不换目标或重发。

## 消息触发过滤（规格0002）

仅运行 filters 集成3项及保护单测1项；验证人员/字面字符可组合、策略权限/版本/幂等/重启、消息仍可 list/get、排队push取消、pull领取复核、已提交/领取可见性不变及显式直发。空/重复/未知规则与Unicode、截断、策略更新不复用旧结果由单测保护，不扩展为全平台或性能验收。
