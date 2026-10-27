# 可转写的测试用例卡

本轮只写用例资料，没有测试源码或运行结果。父 T 的业务定义见 [acceptance](../acceptance.md)，文件/层次/计时与适用映射见 [test-plan](test-plan.md)。本文给出固定 fixture、输入动作和机械断言，供 I02 转 tests/cases.json、I04–I08 写全测试时使用；只在根 TODO 的 I/A 计进度。

P=enabled-positive，R=required-rejection，D=deferred。case_id 稳定，不随测试顺序变化；参数展开使用原 ID 加明确参数名/值，不把多个组合藏在同一个通过记录。对每个 operation 自动生成的字段边界见文末，不能以通用 schema 测试取代具体原生/事务/跨模块场景。

## 1. 固定 fixture 合同

所有 ID 都是测试逻辑别名，装配时从可控 IdSource 或真实测试 profile 取得，不是可向现有服务调用的地址/凭据。所有时间点为可控 UTC+单调时钟，真实流/停止例外使用实时时钟；数据库/UDS/端口隔离规则沿 test-plan。

每个子例有自己的数据/幂等键命名空间；默认创建全新逻辑请求，只有验证重放的明确步骤复用原键/输入。不同 A 可以复用同一当前版本用例证据，不因此把同一 case 重跑一遍。

| fixture | 完整必要状态/输入 | 隔离和资源归属 |
| --- | --- | --- |
| F01 identities | operator O、发送方 S、recipient A/B、无权限 X；S 有精确 session.send 与自有台账读取；A/B 各有独立绑定/来源/回复；X 无资源 grants | 凭据只在测试装配中生成并经认证通道传，不进入业务输入或报告 |
| F02 targets | OpenCode/Pi 两类；同标题 s1/s2、不同 namespace 同原生 ID；live idle/busy/permission/offline/history-only 各观察；epoch e1/e2 | 目录/原生 receiver 是不同事实；既有工具不被模拟创建替换 |
| F03 im | Lark 国际版 user 与 Telegram bot 两连接；各获准主流 c1/话题 t1、另有无权 c2；created e1、重复源键、重叠窗口/不同分页 token 的同 message_id | 受控协议集成用本次对端；real 组从当前授权 Lark user/Telegram bot profile 获取实际原群/话题 |
| F04 subscriptions | 同 route 的两订阅，TTL 60/120 秒、同 e1、固定同一 recipient；各 owner 来源 grants 不同，版本 v1/v2；另一 route 有独立 recipient/一订阅 | 当前有效贡献分别留证，不共享权限并集 |
| F05 catalog | 元数据按 key=a/b/c 升序、updated_at 为中/新/旧；未登记项、缺时间项、每项不同可读正文；目录 seq=10、更新 seq=11 | 真 SQLite/FTS，至少两主体授权范围；旧快照与新写入并行 |
| F06 text | 中文、emoji、组合字符、"Aa/aA"、引号/SQL/FTS 字符、1/2/3 字符、跨读取块的字面串、截断正文、伪造 role/JSON/围栏 | 字节偏移以原始 UTF-8 编码验证，不用 UTF-16 索引 |
| F07 lifecycle | managed profile p/revision1、existing 实例 b；启动 token n1、slot starting/ready/stopping/unknown；同名无归属外部进程；已证退出观察 | 只有本次 owned 子进程可停止；manual 决定不生成 absence 观察 |
| F08 faults | test-plan 的全部 fault point；提交前/后两侧可控屏障；真实 SQLite WAL/锁/满盘错误注入 | 不靠 sleep 随机碰竞态；生产请求不能触发 fault hook |
| F09 frames | 关联响应/事件交错、1 MiB+1 字节帧、LF 延迟/永久缺失、写出后断开、明确未送失败 | 有界缓冲；只隔离本次协议通道，真实活跃工具不可为收尾强杀 |
| F10 transport | 同编译目录的 API/CLI/MCP、另一个不同 catalog_digest 的客户端、合法协议壳内业务错参、非法 JSON-RPC 壳 | 一个常驻服务/状态库；代理结束不删除台账/订阅 |
| F11 budgets | 目标队列 1000/全局10000、1000 记录/4 MiB 扫描预算、10k结果/32快照、100k元数据/512MiB正文索引 | 流式生成到本地隔离目录；容量拒绝不清未结算证据，不在内存物化全部正文 |
| F12 real | 两 IM × 两 Agent 的当前授权测试 profile；原生身份/开始观察、实际 reply 调用和原生回复 ID；新会话独立 recipient 接线 | DJ_TEST_REAL 与 profile 只选择范围，不自动授予外发/启动/费用；缺输入标 blocked/not_run |

## 2. 72 个父场景的主用例卡

主文件用 test-plan 约定的短名，均是未来 `.test.eli`，不是已存在文件。一个卡可由不同层补独立子例，但 real/native 断言必须由真正对应层证明；下表不把协议替身当真实 Agent 唤醒。

| case_id | P/R | fixture / 未来主文件 | 给定与操作/故障 | 机械断言 / A 入口 |
| --- | --- | --- | --- | --- |
| T01.fanout.system | P | F01–F04；system/flows | 两来源、两 route 建四订阅，各注入一个匹配 created | 每源对应两独立 delivery_id；每 route 收两源，来源/话题不串；真实补 T42；A12/A20 |
| T02.same-title.integration | P | F02；integration/agent | 同标题两候选，discover 后用精确 candidate_ref 登记 s1 | 绑定 key=s1，另一候选无 submit；缺精确选择时不自动写入；A06 |
| T03.history-offline.system | P | F02；system/flows | 只留历史、撤真实 receiver，再向原目标提交 | 同 key 保持 offline hold/明确限制，spawn/create 计数为0；A06/A14 |
| T04.tristate.unit | P | F03/F06；unit/rules | 缺 sender 字段、否定谓词、主流/精确话题/include_threads 边界 | not(indeterminate) 不变 true，只有确定 match 生成决定；A03/A11 |
| T05.contributions.sqlite | P | F04；integration/delivery | 一个 e1 同目标命中两订阅、另目标一订阅 | 第一 route+e1 只有一 Delivery/两贡献，第二 route 独立；A12/A13 |
| T06.idle-wakeup.real | P | F12；e2e/relay | 参数 tool=opencode/pi；idle 后从授权源发匹配消息，不建 Agent timer | 原 session 出现输入及原生开始观察，可显式回复原话题；缺 start 证据不算全链；A16/A20 |
| T07.busy-queue.integration | P | F02/F04；integration/agent | busy/permission 时排队，再给可靠 idle | busy/permission 阶段无绕过写出，idle 才按序 submit；A14/A16 |
| T08.commit-ack.system | P | F03/F08；system/recovery | event.after_commit_before_ack 中断后重投 | 同 source_key 一事件，已持久工作恢复；提前 ACK 接入另给 gap 限制；A05/A15 |
| T09.lost-receipt.system | P | F08；system/recovery | delivery.after_native_accept_before_receipt 后重启 | 原 attempt 为 unknown，后续同 route 无写出，原键不新增投递；A13/A18 |
| T10.no-native-dedup.integration | R | F02/F09；integration/agent | 能力 native_idempotency/lookup 未证，丢失发送响应 | 不将 dispatch_key 当厂商去重保证、不自动重发；A16 |
| T11.stable-recovery.system | P | F02/F03/F08；system/recovery | 短期来源 ref 过期、Binding epoch 变更、DJ 重启 | 订阅用稳定 resolved_sources/current grants，旧 Binding 不重用，不换 native ID；A06/A18 |
| T12.pause-race.sqlite | P | F04/F08；integration/delivery | pause/update/delete 与 match/submit 两侧屏障交叉 | cutover/revision/贡献撤销符合事务先后；提交后事实不擦；A11/A13 |
| T13.echo-id.system | P | F03；system/flows | Outbound 已有 native_message_id；以及提交中/unknown 时源先回流、后存回执；另一个相同文本 ID | 自己 ID 被抑制；未结算出站期间目的地路由 hold，回执后复核；不按正文或 sender=self 抹掉用户输入；A15/A17 |
| T14.queue-limit.sqlite | P | F06/F11；integration/delivery | 填到目标/全局预算，再加入新事件与超长原文 | 可见 blocked/容量诊断、truncated/引用；无静默丢待匹配工作；A03/A13 |
| T15.source-gap.integration | P | F03/F09；integration/im | 来源断线且重放窗口缺失 | gap 及未知范围可见，不宣称已恢复未曾收到的数据；A15/A18 |
| T16.receipt-layers.unit | P | F02；unit/state | 分别输入 accepted/started/ended/settled/agent_report | 每类独立 Receipt，自报不变 native、handled 不变 completed；A14/A16 |
| T17.revocation.system | P | F01；system/ownership | 读/排队/提交前撤权，X 自报 O 或 A 的 agent_id | 读取/新副作用拒绝，不泄露无权 ID/计数/秘密；A04 |
| T18.cross-entry-idem.integration | P | F10；integration/interfaces | S 通过 CLI/MCP 同 operation/key/输入请求 | operation_id/资源相同，一次受理；不同输入同键 conflict；A19 |
| T19.proxy-eof.system | P | F10；system/ownership | MCP EOF/服务不可用/未验证旧宿主版本 | 台账/订阅保留，无影子服务；协议不兼容明确拒绝，断线不假取消；A19 |
| T20.reply-expiry.integration | P | F03；integration/im | reply_context 固定 t1 后过期/撤权，试图另给目的地 | reply 拒绝，不能降级发 c1 主流，原键重放仍核对原记录；A17 |
| T21.owner-webhook.system | P | F03/F07；system/ownership | 两 DJ owner/worker 竞争，Telegram 已有 webhook | 本次唯一 owner/claim；不删除 webhook、不杀共享服务；A15/A18 |
| T22.native-failure.integration | P | F02/F09；integration/agent | 协议版本不符、hold/refuse、模型配置/余额失败观察 | incompatible/held/运行错误分层，不用别的模型/工具掩盖；A16 |
| T23.skill-adoption.real | P | F12；e2e/skill | OpenCode/Pi 发现并读 Skill/参考，执行订阅和 unknown 处理 | 文件可读/发现/正文读入/实际正确调用分别留证，不用 exit0 代替采用；A20 |
| T24.local-created.integration | P | F03/F06；integration/im | created 入库后 local list/search/get、主动 send、UTF-8 分页 | 版本/权限/偏移正确，出站同键一次；未启用类型另拒绝；A03/A17 |
| T25.no-ai.system | P | F10；system/ownership | 装配全部功能，只允许已配 IM/Agent 端口，观察 DJ 自有调用/依赖 | 无推理/embedding/语义兜底客户端；外部 Agent 模型执行单列；A03/A20 |
| T26.strict-input.integration | P | F10；integration/interfaces | 合法协议壳内给错字段/类型/互斥/超限，参数化61操作 | 共享业务 code/field_errors/effect_state=none，无受理/外部写；A03/A04/A19 |
| T27.route-load.performance | P | F03/F04/F11；performance/router | 既定100事件每秒/4KiB/≤64候选、再加大扇出/慢目标 | 路由CPU/积压/公平/内存真实记录，预算耗尽可续、其他route不饿死；A20 |
| T28.fixed-preview.sqlite | P | F04；integration/delivery | preview 后换 spec/版本/目标/权限，或重复提交票据 | create 不收 spec，漂移拒绝；同键原结果，异键同票据不新建；A11 |
| T29.accept-response-loss.system | P | F08/F10；system/recovery | 原请求延迟提交，客户端超时后 get 暂 not_found，再原键重放 | 唯一操作/对象，not_found 不被当未执行证据；A05/A19 |
| T30.ttl-merge.sqlite | P | F04；integration/delivery | 两 current/queue 贡献 TTL60/120，时间推进61秒且收窄权限 | 短贡献失效而长贡献仍可投，预算不扩权、旧版本不复活；A13 |
| T31.submit-cutover.sqlite | P | F08；integration/delivery | submitting 事务前/后 cancel/pause，并中断重启 | 前可撤、后可能送；恢复 unknown，不将实际未写的某次观察变通用可重试；A13/A18 |
| T32.truncated-not.unit | P | F06；unit/rules | 截断正文未见词时 not contains/eq；另测空 all | 未见词 indeterminate，否定不触发；all[] 按既定 true 但仍受来源/权限；A03 |
| T33.recipient-boundary.system | P | F01/F04；system/ownership | 无 target_constraint/无 reply grant，或离线排队24h后才提交 | 不靠自报绑定；无权限不发reply引用，引用在提交前签发且有期限；A04/A06/A17 |
| T34.multipart-disabled.integration | R | F03；integration/im | 单个合法 TextContent 超平台单条预算、需要多片 | 受理前 unsupported/limit_exceeded，零出站写，不截短/摘要；A17 |
| T35.manual-resolve.sqlite | P | F01/F02；integration/delivery | Agent/O 分别 resolve unknown，原生仍 busy | Agent forbidden；O仅 manual不重发，后续仍等idle；A04/A14 |
| T36.external-data.unit | P | F06；unit/contract | 正文带 role/JSON/围栏，编码再解码信封 | 正文仍为 content.text 原文，可信头/规则/工具参数未被替换；A03/A13 |
| T37.native-im-disabled.integration | R | F03；integration/im | corpus=native 的 IM list/search 请求 | 明确 unsupported，无 Event/ingress_seq/实时去重键占用；A17 |
| T38.eli-interop.integration | P | F06/F10；integration/interfaces | S3 编译全部入口，传false/null/缺失/空数组/Unicode/大Seq、调用Bun/Ajv/SDK | 每值类型/字节/序号保真，导入无副作用，包无运行编译器；A01 |
| T39.single-core.system | P | F01/F10；system/ownership | standalone/嵌入竞争同状态、两个代理访问，普通主体试管理面 | 一个 owner/调度者；代理不打开业务库、不获O权限；A04/A18/A19 |
| T40.wal-fault.sqlite | P | F08；integration/storage | 读回version/mode、真实提交两侧中断/锁/磁盘/备份恢复 | WAL/FULL/FK合规，不提前ACK/删墓碑，停顿与资源如实记录；A05/A20 |
| T41.im-ingress.integration | P | F03/F09；integration/im | Lark user重叠窗口/同message_id/分页失效/授权过期/身份变化；Telegram提交与offset间中断 | Lark每原消息一created、窗口只持久后推进，无bot回退/历史触发；Telegram持久后offset；A15 |
| T42.matrix.real | P | F12；e2e/relay | 按第3节八个明确组合，实际source→DJ→目标→reply | 每项独立原生关联链；此行是组定义，不能作为八项之外额外“通过”；A20 |
| T43.pi-same-session.real | P | F07/F12；e2e/control | Pi 初始profile启动/登记/退出，显式获准恢复；existing OpenCode离线 | Pi恢复身份必须同session，OpenCode不被新server顶替；A06/A16/A18 |
| T44.skill-reply.real | P | F10/F12；e2e/skill | 模型按Skill发reply并模拟API响应丢失；另轮只结束不reply | 原键查回同outbound；缺实际reply调用/原生回复ID的链不可判完整；A20 |
| T45.service-boot.system | P | F07/F08；system/recovery | 首次/重复、新于程序schema、存储失败、停止/重启未知恢复 | 拒新schema/影子库，未恢复前无intake，未启用能力拒绝；A18 |
| T46.scope-query.sqlite | P | F01/F02/F05；integration/query | 单/多工具、实例、workspace、agent、未登记、状态/时间范围交叉 | 不同维度AND/数组OR，agent_id非父节点、同名不合并、分页稳定；A07 |
| T47.literal-query.sqlite | P | F05/F06；integration/query | 单双字/中文/emoji/SQL/FTS字符/大小写、多字段与正文搜索 | 精确原文匹配/字节偏移，安全参数绑定，无语义扩展；A08 |
| T48.coverage-query.sqlite | P | F05/F08；integration/query | 源离线/索引缺页/撤权/删除、刷新中断 | complete与coverage/as_of分开，无越权片段/计数，查询不启动工具；A08/A09 |
| T49.direct-no-sub.sqlite | P | F01/F02；integration/delivery | 只有session目录，无IM/AgentTarget/订阅，S直发；再同route建订阅 | 仅direct Delivery/route/Operation；同屏障/队列，不造Event/贡献；真实补control；A13/A20 |
| T50.exact-resolve.integration | P | F02；integration/agent | instance+native ID resolve后epoch改变/离线/ref失效 | 失败/hold原目标，spawn/create计数0，旧epoch不可提交；A07/A14 |
| T51.empty-create.real | P | F07/F12；e2e/control | ready OpenCode实例create空session；Pi同RPC收到create | OpenCode原实例新key可核验、未自动prompt；Pi unsupported且旧绑定不切换；A10/A16 |
| T52.start-race.system | P | F07/F08；system/recovery | 并发start同profile、spawn后响应丢失/重启 | 一个slot/token/实例，按已记账归属核对，无同名进程冒领；A10/A18 |
| T53.create-unknown.sqlite | P | F07/F08；integration/lifecycle | 原生已create/start但响应丢失，重放原键/reconcile | 同action保持unknown直至明确关联，无按标题猜/换键再建；A10 |
| T54.action-grants.integration | P | F01/F10；integration/interfaces | 分别只授list/read/send/create/start，输入自由argv/路径/凭据 | 各能力独立、越权拒绝、不复制权限或回显秘密；A04/A19 |
| T55.entry-equivalence.integration | P | F10；integration/interfaces | 同主体对61操作分别走API/CLI/MCP；合法壳内业务错参/超时 | schema/错误/权限/幂等相同；protocol壳错误独立，不能提前丢业务envelope；A19 |
| T56.no-im-control.system | P | F03/F05；system/flows | IM正文为“启动/搜索/找最合适会话”，另API字面搜索同文本 | IM只按订阅投递、API只字面检索；无管理命令解释/AI选择；A03/A19 |
| T57.catalog-load.performance | P | F05/F09/F11；performance/catalog | 增长目录/索引、并发刷新/短串/巨帧且活跃转发 | 查询/版本/存储预算和事件循环停顿可查，未饿死转发、报告实际总资源；A09/A20 |
| T58.owned-stop.real | P | F07/F12；e2e/control | 自有managed忙碌/排队时stop；对existing请求stop | 自有drain/期限状态可见、queued留原route；existing拒绝、不强杀；A10/A18 |
| T59.empty-page.sqlite | P | F05/F06；integration/query | 更新时间与key乱序，短串/FTS预算页无命中但后页有词 | 空items+cursor且complete=false，续扫无漏重；search时间sort拒绝；A08 |
| T60.snapshot-revision.sqlite | P | F05/F08；integration/query | seq10开快照，seq11更新正文/checkpoint/撤权/版本驱逐 | 无跨请求读事务，版本不混；撤权/删除/驱逐cursor明确失效；A07/A09 |
| T61.partial-not-delete.sqlite | P | F05/F08；integration/query | 原生只返回一页/断线/预算尽；再给明确删除或可证完整缺失 | partial未见项不tombstone；已证删除同时屏蔽正文/FTS/片段/旧cursor；A09 |
| T62.direct-owner.sqlite | P | F01/F04；integration/delivery | S向未登记s1直发后A登记/注销；X查同route，撤S授权 | 旧origin/owner不变、route屏障保留；X不可读，S仅最小自有状态；A04/A13 |
| T63.precise-probe.sqlite | P | F02/F05；integration/query | session_keys=[s1,s2]定点刷新/检索；get key、probe ref | 仅选中范围、ref可重取，未创建登记/Delivery/Event，无测试输入；A07 |
| T64.stable-key.sqlite | P | F07；integration/lifecycle | Pi start/OpenCode create就绪后过期ref/原键重放，实例现已stop | initial_session_key/session_key不变；get当前ref/状态，历史ready不当当前ready；A10 |
| T65.instance-gate.sqlite | P | F07/F08；integration/lifecycle | stop与send/create/订阅启用分别在提交点前后交叉，queue非空 | stop先则新动作none且零写；在途先则drain，queued hold不要求清空；A10/A14 |
| T66.slot-absence.sqlite | P | F07；integration/lifecycle | starting/stopping/unknown收新键start，manual结案但旧进程存活 | starting引用同action；stopping/unknown拒新起；已证退出后才新ID/epoch；A10 |
| T67.recipient-wiring.real | P | F01/F12；e2e/skill | 已绑定创建者建新session；分别未接线/操作员接独立recipient后登记 | 创建者whoami不变；未接线不报reply可用，接线后主体/目标/工具可证；A06/A20 |
| T68.safe-drain.real | P | F07/F12；e2e/control | DJ正常stop时原生活跃/unknown，推进到截止；另隔离强制中断 | 正常仍draining且管道不提前关；强制中断只记风险/unknown，不伪无损停止；A18 |
| T69.frame-resync.integration | P | F09；integration/agent | 超帧有LF、永无LF、帧关联不明、同时已有在途输入 | 缓冲有界、5s截止隔离，无新写；可能写出项unknown、不杀工具；A09/A16 |
| T70.catalog-digest.integration | P | F10；integration/interfaces | 目录digest匹配/不匹配客户端、service_id/instance_id错用、未启用能力 | 匹配三入口一致；不匹配incompatible，无静默降级；父T保留deferred；A19/A20 |
| T71.observation-ttl.unit | P | F02；unit/state | idle/busy/live观察过期；已证offline/incompatible后再推进时钟 | 仅依赖新鲜度的状态降unknown，明确离线不反转，旧desktop-open不匹配；A07 |
| T72.direct-bytes.sqlite | P | F01/F02/F06；integration/delivery | 传context/current/额外policy，TTL59/604801、超字节正文，入队后native限制变小 | 错参/超限拒绝或后变小blocked；无原生截短写出、无附IM历史；A03/A13 |

## 3. 四组合与未启用分支

T42 的每个组合都记录 setup/test/teardown、原生身份/源消息/投递/开始/reply调用/outbound/原话题回复ID。idle/busy 各独立；busy 先确认排队，原生可靠 idle 后继续，不能把两条相同文本当同一输入。

| case_id | P/R | fixture / 文件 | 输入与预期 |
| --- | --- | --- | --- |
| T42.feishu-opencode-idle.real | P | F12；e2e/relay | Lark→OpenCode idle→Lark原话题；完整关联链 |
| T42.feishu-opencode-busy.real | P | F12；e2e/relay | Lark→OpenCode busy排队→idle→原话题回复 |
| T42.feishu-pi-idle.real | P | F12；e2e/relay | Lark→Pi初始session idle→Lark原话题；身份不变 |
| T42.feishu-pi-busy.real | P | F12；e2e/relay | Lark→Pi busy排队→idle→原话题回复 |
| T42.telegram-opencode-idle.real | P | F12；e2e/relay | Telegram→OpenCode idle→原chat/topic回复 |
| T42.telegram-opencode-busy.real | P | F12；e2e/relay | Telegram→OpenCode busy排队→idle→原chat/topic回复 |
| T42.telegram-pi-idle.real | P | F12；e2e/relay | Telegram→Pi idle→原chat/topic回复 |
| T42.telegram-pi-busy.real | P | F12；e2e/relay | Telegram→Pi busy排队→idle→原chat/topic回复 |

下列额外卡保留首期拒绝或远期正向的准确位置；D 没有实现/执行授权，不能计为运行通过。主卡与额外卡共享父 T，不重复产生同一 case_id。

| case_id | P/R/D | fixture / 文件 | 输入与预期 |
| --- | --- | --- | --- |
| T07.steer-disabled.integration | R | F02；integration/agent | 明确steer请求，首期unsupported，不换queue后假接受 |
| T07.steer-native.future | D | integration/agent | 扩展启用后才测原生steer/expectedTurnId；当前不执行 |
| T10.native-dedup.future | D | integration/agent | 只有厂商稳定dispatch key合同被证后，才测真正原生去重 |
| T22.other-tools.future | D | integration/agent | Codex/Claude/Cursor/agy/Antigravity等非首期适配，不能借两工具结果宣称通过 |
| T23.other-clients.future | D | e2e/skill | 其他客户端的Skill采用须单独实测；首期不安装 |
| T24.events-disabled.integration | R | F03；integration/im | edited/deleted或native IM corpus，preview/查询明确unsupported |
| T24.events-native.future | D | integration/im | 编辑/删除及native历史正向，待扩展启用与原生证据 |
| T30.recent-disabled.sqlite | R | F04；integration/delivery | recent/steer合法已知分支unsupported，不静默改current/queue |
| T30.mixed-policy.future | D | integration/delivery | 扩展启用后再测queue/steer、current/recent策略合并 |
| T32.deleted-selector.future | D | unit/rules | 源适配扩展后再验证edited/deleted的正向事件版本触发 |
| T34.multipart-recovery.future | D | integration/im | 多片前片已接受、后片unknown/失败的恢复/后缀retry；首期只测拒绝 |
| T36.im-tombstone.future | D | integration/delivery | 接到原生删除通知后的旧正文/未提交输入tombstone；目录明确删除另由T61验证 |
| T37.native-live.future | D | integration/im | native只读快照与同消息live去重分离；首期不冒充已启用 |
| T44.pi-mcp-host.future | D | e2e/skill | Pi原生MCP宿主兼容没有首期保证，CLI采用不证明此分支 |

## 4. 参数矩阵和生成约束

operation-catalog 的每行在 B 阶段生成适用的 T26/T55 子例，后缀为实际 operation 和变体键。例如 T26.session-send.xor-both.integration 对 session_ref+agent_id 同传，断言 invalid_argument/effect_state=none、无 Operation/Delivery/外部输入；T55.session-send.invalid-content.integration 分别从三入口提交同错内容，比较共享业务错误字段，而非比较终端自然语言文案。

必需变体包括：最小合法输入、每个必填缺失、未知字段、错误类型、互斥全无/同时、K/R缺失或错revision、数组空/上限/上限+1、字节上限/上限+1、UTF-8中间偏移、当前授权撤销、短期引用过期、受理响应丢失后原键查回。并非每个操作都适用所有变体；不存在的字段不得人为生成“必需”校验。首期合法已知但未启用能力与完全未知字段分别断言 unsupported/invalid_argument。

T38 互操作矩阵至少包含 false、null、missing、空数组、空对象、数值0、空字符串、非BMP字符、大于2^53的Seq以及安全整数revision上限；验证跨 `.eli`→JSON→SQLite/SDK/Bun 的真实值，不只比较函数名。T47/T59 检索矩阵同时覆盖有/无FTS候选路径，后页才有命中、跨读取块子串、多字段OR和不同维度AND；不能只用单页ASCII语料。

fixtures 与fault point装配完成后，manifest 将稳定case_id与parent/file/suite/level/e2e/parameters/applicability/resource_group/timeout/A/Q对应起来；父T42.matrix.real仅作为展开组，不产生额外通过计数。每个case及参数实际记录自己的结果，deferred/not_run/blocked与pass分开。当前本文只有用例设计，I02/I04–I08 与 A01–A20 不能因此勾选。


Lark user 变体沿用稳定父 T/子 ID，不另复制一套清单：T41.im-ingress.integration 的 parameters 必须展开 initial-cutoff、same-timestamp-two-pages、empty-page-with-more、overlap-replay、crash-before/after-page-commit、expired/repeated-token、partial-budget、thread-new-reply-old-root、malformed/oversized-output、identity-revision-change、missing-oauth/scope、clock-regressed、rate-limit-backoff、non-text/deleted/updated-first-seen；逐例断言按 IM 接入。T39/T38 补默认 ~/.dj 与隔离测试根、home 解析/显式 config、owner/权限/symlink/缺 client profile 拒绝。T13 补未知出站回流 hold，T42 四个 feishu-* 稳定 ID 只为历史命名，实际测试输入统一 Lark 国际版 user，原生证据必须证明 user；不删除旧 ID 伪造通过沿用。无新版 consumer 测试通过可替代上述 user 分支。

S2 必要接口变体继续使用原父场景，不另立验收清单：T16.pi-end-is-not-settled.unit（Pi retry gap 不等于 idle）、T24.address-proof.integration（精确地址原生证据与迟到撤权）、T38.directory-runtime.system（目录包复制出仓库后实际 standalone+MCP 运行）、T63.pi-native-entry-id.integration（get_entries 原生稳定消息 ID）、T67.recipient-reload.system（新 session 独立 recipient 原子接线、ID 不复用）。各输入/断言、层次和超时在 tests/cases.json，执行范围见 test-plan；当前全为 written-not-run。

S3回归：T38.native-access.unit 在unit/contract核验nativeGet对missing、显式null、false、0、空串及缺receiver的结果；T40.repository-revision.sqlite 在integration/storage通过实际SQLite核验可选内部revision与显式陈旧revision回滚；T02.same-title.integration补适配器数组在发现/登记后仍保留原有两会话的断言。它们归原T38/T40/T02和A01/A05/A06，不另起验收清单。运行事实以status及私有逐例证据为准。

T40.metadata-quota-rollback.sqlite使用真实SQLite的99999→100000→越界/整批回滚边界，另验更新既有live记录不增加计数、新事务不复用回滚缓存。归原T40/A05/A09；不是通过降低十万目录负载替代性能验收。

S3补充回归沿用原父场景：T40.pending-work-indexes.sqlite检验selectHead五状态队首deliveries_route_head（排除accepted历史且保留unknown/submitting屏障且导出selectHead仍返回完整解析对象）、claimRoute窄队首SELECT delivery_id,state...INDEXED BY deliveries_route_head计划与0次SELECT payload队首查询（覆盖空队列/仅accepted/submitting队首/unknown队首/ready队首）、beginSubmission窄队首SELECT delivery_id...INDEXED BY deliveries_route_head计划与精确队首ID、queueCapacity单route五状态COUNT固定INDEXED BY deliveries_route_head计划与真实表混合状态计数一致性、queueWriteJobs的routes候选EXISTS+INDEXED BY deliveries_route_head查询计划（走sqlite_autoindex_routes_1与deliveries_route_head，无TEMP B-TREE与deliveries_state扫描）与runRouteJob续派窄投影预检SELECT state...INDEXED BY deliveries_route_head计划及在accepted历史/重复ready/deferred/blocked、仅accepted/submitting/unknown、unknown_delivery_id非空含ready、unknown/submitting队首后含ready/deferred/blocked下跨空/中间/末尾after与limit同原JOIN+DISTINCT结果等价与队首状态判定、attempts_delivery/attempts_outbound与receipts_attempt两种回执JOIN计划及多delivery/outbound回执隔离、仅取key的固定keyset队列部分索引、schema-1删除后两次migrate幂等恢复及标志更新，以及K3新库不建冗余deliveries_route_pending、模拟旧schema-1空库与含26条deliveries非空库经两次migrate先确保deliveries_route_head再幂等DROP INDEX IF EXISTS deliveries_route_pending（保留user_version=1、全部数据、UNIQUE(route_id,delivery_seq)重复序号拒绝与delivery.list分页计划，且只读EXPLAIN证实deliveries插入与replaceProgress窄更新的IdxInsert/IdxDelete减少）；T16.observation-checkpoint.sqlite检验空观察零写、cursor变化一次写、原binding引用、reconcile单批回调内回执失败不清标志/清标志失败回滚回执、projectDelivery在无context.principal后台调用时0次repository.get读取且精确返回minimalDelivery（有权限主体完整投影、无权限及tombstone退回minimalDelivery）、observeDelivery非accepted状态0次读取attempts/bindings/instances早退、observationAttempt元数据SQL在空页/未变游标（含0/false）下0次repository.get("attempts")且游标变化时重读完整attempt保留envelope_snapshot、claimRoute窄队首查询（1次SELECT delivery_id,state...INDEXED BY deliveries_route_head、0次SELECT payload）与单SQL更新claim_epoch/claim_owner/payload（CAST(claim_epoch+1 AS TEXT)保真、0次repository.replace("routes")、64位溢出保护）与recordReceipt精确owner_token+claim_epoch匹配删除claim、仅在unknown_delivery_id或claim_owner实际变化时写1次routes（无变化0次写、外国owner或新epoch保留不动），以及attachBinding/releaseClaim/holdDelivery/beginSubmission/recordReceipt/reconcileDelivery/observeDelivery全部经repository.replaceProgress窄更新（0次全列replace）、L3下beginSubmission对subscription_event投递检查routing_work时执行1次SELECT state FROM routing_work WHERE event_id=?与0次repository.get("routing_work")（缺失或非done置blocked/routing_incomplete并释放claim，done正常推进）和K2b下beginSubmission单次withContributionReads(...,true)作用域+effectiveContributions流式LEFT JOIN subscriptions（:iterate/:next/:return与行局部item-read，使sessions/agents/connections各读1次而subscriptions的get/getSubscriptionState/getSubscriptionStates调用均为0次，frozen/attempt不挂载reader，单delivery跨页135条贡献在matched-bytes超限时第6步提前停止并调用rows.return()置blocked/limit_exceeded，正常预算下流式产出全部131条有效matched不受128截断并回写4条expired/revoked）；T47.metadata-index-boundary.sqlite检验FTS只存正文同时保留元数据/正文检索；T38.envelope-snapshot.unit检验有界压缩、旧值、Unicode/空值、损坏/解压上限；T40.write-batch-{commit,isolation,failure,bound}.sqlite检验64项有界写合批、每项SAVEPOINT隔离（含已写入后must(failure revision_conflict)单项回滚且同批邻项成功）、常规同步回调及withContributionReads（含带subscriptionIds预加载）/withEventPlans（含bufferDeliveries=true）返回Future时回滚外层事务、COMMIT后才完成Future、withContributionReads四表256项只读缓存/冻结/禁止routes/finally撤销/跨事务新值与第三可选布尔subscriptionStateOnly（默认false走全列get，非布尔抛TypeError，true对subscriptions走repository.getSubscriptionState仅取subscription_id/owner_principal_id/state/revision四列且0次全列get，getSubscriptionState对缺失返回nil、空串或非字符串抛TypeError）及第四可选参数subscriptionIds（非空时要求subscriptionStateOnly===true否则SQL前抛TypeError，进入work前调用1次repository.getSubscriptionStates预填冻结四列对象并将缺失键负缓存为nil使work内已预加载键0次getSubscriptionState/get，未预加载键回退单键getSubscriptionState）、repository.getSubscriptionStates仅允许同步事务内传入0..128稠密非空字符串数组（事务外/非数组/超128/稀疏空洞/坏元素在SQL前抛TypeError且0条SQL，空数组返回[]且0条SQL，按首次出现顺序Set去重后以1..16预计算IN SQL分块执行覆盖0/1/16/17/128与重复/缺失键归并、仅返回存在四列对象且实时反映变更）与repository预计算SQL复合键/乐观锁、repository.replaceProgress仅允许同步事务内deliveries(state/revision)/attempts(state/definite_not_sent)/routes(binding_id/claim_owner/unknown_delivery_id)加完整payload（非支持表或无revision表传expectedRevision在SQL前抛TypeError，缺失主键或篡改任意未更新typed列均由WHERE column IS ?守卫拦截返回revision_conflict且0变更，兼容NULL/布尔/64位文本整型，支持expectedRevision、外层回滚与SAVEPOINT隔离，只读EXPLAIN验证attempts/routes零IdxInsert/IdxDelete且deliveries字节码减少）、repository.insertIfAbsent仅允许同步事务内match_decisions/contributions两表且按精确复合主键ON CONFLICT DO NOTHING去重不覆盖（不吞CHECK/NOT NULL/FK违例）、repository.insertManyIfAbsent仅允许同步事务内match_decisions/contributions两表且在执行SQL前校验0..128稠密对象数组（非支持表/缺事务/非数组/超128/稀疏空洞/坏元素在SQL前抛错且0变更，按<=16行预计算ON CONFLICT DO NOTHING分块执行覆盖0/1/16/17/128边界并返回新增条数，同块/跨块/既有重复主键不覆盖现有payload与typed列，保留CHECK/NOT NULL/FK抛错且第2块违例时通过外层事务回滚第1块已插入行）、L1下repository.insertMany仅允许同步事务内deliveries表且在SQL前校验0..128稠密对象数组（非deliveries/缺事务/非数组/超128/稀疏空洞/坏元素在SQL前抛错且0变更，按<=16行严格INSERT分块执行覆盖0/1/16/17/128边界并返回插入条数，不吞主键/UNIQUE(route_id,delivery_seq)/CHECK/NOT NULL/FK违例且第2块违例回滚第1块）、planContribution第7可选参数pendingContributions（省略/nil立即insertIfAbsent，非数组或length>=128在写delivery与分配序号前抛TypeError，事务外即使传入合法数组也抛错拒绝且0变更，合法数组收集ready/deferred/blocked贡献且0次insertIfAbsent，无效贡献与accepted终态不入队，planning.defer_insert=true时强制要求pendingContributions并将新建delivery经planning.created暂存、同route后续贡献复用同一缓冲delivery而不重复分配序号、跨页既有持久delivery不被finish内存重写）、allocateSequence单SQL同步next_delivery_seq列与payload文本（0次replace routes、>2^53保真、回滚与溢出边界）、withEventPlans单事件同步事务128项routes/deliveries上限与超限回退/惰性全局计数与created递增/第四可选参数complete-in-one-turn与第五可选参数buffer-deliveries（bufferDeliveries=true时defer_insert=true暂存新建delivery并在finish按state统一规范化为ready/revision=2或blocked/revision=1后经insertMany一次落库、0次单行insert("deliveries")、不改既有持久行、未持久化created实时计入全局10000与单route 1000容量、128上限与单次finish守卫、未finish成功返回抛TypeError而失败Result允许回滚退出、9999→10000容量阻塞与多轮续页及既有blocked+新建缓冲共存解锁）/跨事件隔离与退出撤销，以及matchBatch/matchTurn准备期connection复用、K2a下matchWithWriter提取plan.answer==="true"的subscriptionIds传入withContributionReads(...,true,subscriptionIds)使subscriptions全列get与单键getSubscriptionState均为0次而getSubscriptionStates按<=16分块批读（覆盖2候选1块、18候选16+2分块与全no_match传入[]零订阅SQL）、L2下matchWithWriter开启bufferDeliveries=true先执行finish批量insertMany("deliveries")再执行insertManyIfAbsent合批写入match_decisions与contributions（0次单行insert("deliveries")与0次insertIfAbsent，覆盖2候选单块、9999→10000容量阻塞首轮blocked/revision=1批量落库并在释放1容量重试后解锁至ready/revision=2、既有持久blocked与新建缓冲投递共存解锁、以及18路16+2分块批量创建与领域失败SAVEPOINT回滚/第2块外键异常整批ROLLBACK边界）、matchTurn参数/16项边界、准备抛错解除等待且整组零写、准备乱序仍按ingress_seq顺序提交、not_found/done/sender_not_allowed并存、单项revision_conflict回滚隔离与成功样本发布、未知写异常整批回滚且零样本；T31.submit-cutover.sqlite补独立只读SQLite连接核验外部submit必在submitting持久提交之后、draining下在途回执落盘与未提交route延期、以及同route第1条原生submit在途期间draining时第1条回执落盘而同岗位不开始第2条头项（保持ready且仅1次probe，且draining阻断同tick第2轮queueWriteJobs候选查询）；T31.cancel-before-submitting.sqlite补queueWriteJobs单轮routes<=32、outbound<=16、总jobs<=64上限、routes/outbound每tick优先级轮换及0余量不丢游标，以及同route预置6条ready下单岗位单轮最多连续消费4条、后续tick继续消费剩余2条（严格序号/无重复）、第2条probe忙（deferred）或submit抛错（unknown队首屏障）立即停止连续提交且屏障解除前后续tick不越过、派发后routes表列与JSON序号/epoch一致、runCapacitySchedule在真实SQLite Core上的独立producer+非重入consumer排空，以及J1–J3 tick内有界第二轮派发（64条ready route×4项=256条投递+32条ready outbound在单次tick两轮内全部完成为accepted且两轮间经0ms宏任务让出、无第3轮，同tick两轮间反转routeFirst/!routeFirst且连续两轮tick间write_route_first每tick翻转一次，空游标起扫<budget行时scan.from_start=true不跑额外空SQL且不进第2轮，32条route满页触发第2轮从空游标回绕扫出6项余2项ready及第2次probe忙余1项deferred的同route时按本tick seen集合去重不二次启动岗位/不增probe与claim_epoch，34条route下第1轮1条unknown+31条deferred零进展不进第2轮，以及两轮间0ms让出期间进入draining/owner_conflict或第1轮前/两轮间触发source_progress故障置storage_blocked=true时均阻断第2轮）；T70.resources.unit.physical-total补runCapacitySchedule在consumer频繁完成时不提前唤醒producer摄取、落后追赶每16条宏任务让出、单tick非重入跳过计数、consumer异常传播阻断producer、内部截止取消与finally等待在途tick并清除定时器后零残留触发；T12.update-cutover.sqlite补同route多订阅/多事件乱序准备仍按ingress_seq单调递增分配delivery_seq、单轮完成投递初始ready/revision=2（队首busy探测deferred/revision=3）且提交accepted后revision=4/5、beginSubmission单次窄reader复用agent/connection保留完整信封（含reply_context_id与allowed_actions且不挂载read）并保持routes列与payload JSON一致、routeEvents准备抛错还原routing_after并在下轮重试、跨事务或准备后提交前暂停/撤权实时生效与单事件合批落库match_decisions/contributions计数（含after-revoke与after-prepare-pause各落库1条match决策与0条delivery/contribution），以及L2/L3下单事件命中多路route时多行INSERT INTO deliveries先于match_decisions/contributions执行、同route双订阅（准备后暂停A的订阅但保留O的订阅）各自独立重检owner/revision/expires_at不串用有效性结论、派发阶段claimRoute窄队首SQL与beginSubmission窄SELECT state FROM routing_work查询（0次SELECT payload FROM routing_work）；T41.im-ingress.integration补readSource末尾健康更新合批下单来源identity_revision失配隔离与事件持久提交早于ack；T10.no-native-dedup.integration补reconcile单批回调内仅在recordReceipt成功时才清除reconcile_requested；T38.entity-ids.unit检验entityUuidV7固定向量（0/281474976710655/1792851600000及8/9/a/b四种variant）、同毫秒相近键前缀区间74位随机尾部原样保留与无内部counter状态（同输入幂等，不承诺同一4KiB页或消除吞吐推断）、跨毫秒字典序与时钟回拨保留实际时间戳（不夹紧或取整）、时间RangeError优先于UUIDv4格式TypeError校验，以及nextHostId与createHostPorts().ids.next严格仅对九个实体主键前缀（event/delivery/attempt/receipt/binding/reply_context_record/route/agent/subscription）使用宿主Date.now()+randomUUID生成v7（异常时钟直接传播）而其余控制/幂等/受限句柄/未知前缀保持v4且不读取时间、createHandleAuthority各合法handleKinds继续签发v4并照常校验主体与TTL；T40.mixed-entity-ids.sqlite检验真实SQLite下既有v4与新v7主键混存的agent.list/subscription.list/delivery.list静态全序分页、delivery.list打开游标后并发插入<=当前cursor的较小键不要求进入已打开旧游标续扫而新查询完整包含、同route混合v4高/v7/v4低投递严格按delivery_seq顺序派发且attempt/receipt/reply_context_record为v7而dispatch_key与信封reply_context_id保持v4、无权主体读取与裸reply_context_record回复拒绝、通过公开reconcile/tick/get验证后台pendingRows推进至高键遇到空页后从空键回绕处理较小v7键（不导出pendingRows、不宣称持续外部写入下的绝对等待上界），以及重复delivery_id触发PRIMARY KEY唯一约束返回storage_unavailable并回滚操作台账。T27路由采用独立10ms绝对日程producer（等待唤醒后重验目标时刻、落后追赶每16条让出宏任务）+与main一致的20ms非重入consumer（70秒有界内部截止，finally停表并等待在途tick后closeFixture），在6000事件/60000次实际输入与持久deliveries/claims/routing_work全部排空成立后、service.status前冻结耗时，先落盘区分schedule_completed与全部门槛status（低吞吐如实记failed）的报告再显式断言actual_events_per_second>=100（未完成时记录schedule_completed=false、失败原因与积压并抛错失败，本地四项performance通过--case逐例独立受控进程串行执行），容量拒绝不能冒充负载完成。源码存在与运行结果分别记录，实际通过以status和逐例报告为准。


N1–N2 第二组匹配准备沿用 `T31.cancel-before-submitting.sqlite`，以本 case 受控嵌套 fixture 覆盖 N-A1..N-A6，不新增 `tests/cases.json` ID：routing 探针精确匹配 `SELECT payload FROM routing_work ... AND ingress_seq`，排除 `runtime.eli:264` 背压 COUNT。N-A1 两组各 16、无第三组/轮、首 submit 前独立只读核验 submitting；N-A2 同 route 本 tick 4 accepted/28 待处理、下一 tick 8/24 且 claim_epoch +8；N-A3 覆盖全 busy（probe=16）、首组 submit 抛错 unknown（结束后逐个 resolve）、首组 probe 挂起（零 accepted 不进第二组，release 后 drain）、单事件短页；N-A4 覆盖 0ms 与第二组 await 期间的 drain/异主/storage 阻断，租约绑定本 fixture 原 owner 并在 finally 恢复，恢复循环至多 16 次；N-A5 覆盖首组 Result 失败、第二组 Result 失败、第二组 payload 扫描真实抛错（query wrapper，非 fault hook）、以及组内单项 revision_conflict 仍允许第二组（独立连接暂改 `payload.last_subscription_id` 后恢复），容量沿用既有 L/T40 10000/1000 证据；N-A6 覆盖空尾回绕 + seen 阻止第二次 match（访问计数=1，下一 tick 完成）与反序低键 route 最终无重复排空。`T31.submit-cutover.sqlite` 保留既有 J/L-A7 切点断言不改；`T40.write-batch-isolation.sqlite` 的既有空组/>16/`success(results)` revision_conflict 作为匹配层证据。

V1–V2 安全停止沿用 `T31.cancel-before-submitting.sqlite`，不新增 ID：N-A4 两处 future-deadline 并发 stop 断言返回 draining、DB 可读、后续有界 stopped；N-A5 throw/Result/组内冲突恢复后补 `nStopToStopped`；新增 ingest fault barrier、execute agent.probe barrier、reloadConfig `host.files.mkdir` barrier 三入口在途场景；新增 port.close barrier 下四入口（tick/ingest/execute/reloadConfig）均返回 unavailable 且无副作用；新增 port.close 首次 draining 与首次抛错两种失败解封场景（原 Result/throw 保持、draining 下 tick/connection.list 仍可读、后续 stop 成功）。所有 barrier/fault/端口/files 原型 finally 恢复，循环有界；V-A6 仅 D 待跑。

N-A4第二组失主断言按真实事务owner守卫对齐：准备hook变更owner后，原owner不得提交第二组；应为16项done、第二组2项保持待处理，且第二组delivery与match_decision均为0。post-await仍返回owner_conflict并阻断第二轮；不能要求失主后先落盘18项再报错。此为D待复验断言，非预先通过声明。

V-A1两处drain期间tick现显式断言Result.ok=true；V-A4最终封闭窗口额外对比fault visits与native inputs无增长，保持mkdir=0。此为独立D覆盖发现的补强，待当前冻结定向复验，不改变生产或性能目标。


Y1–Y2 临时子日志策略沿用既有 Case：`T40.wal-fault.sqlite` 补 openStore `temp_store=2`、独立 raw 连接 FILE、重开仍 2、WAL/FULL/FK/user_version/counters 不变，以及注入 MEMORY 设置抛错/readback 不符均 `storage_unavailable` 并在 finally 恢复原型后正常打开；`T40.wal-fault.sqlite.backup-wal` 补恢复连接 `temp_store=2`；`T40.write-batch-commit.sqlite` 补独立表 64×4KiB 已有行在单项 UPDATE 后领域失败，仅本 SAVEPOINT 回滚且成功邻项提交、事务计数=1、COMMIT 后 Promise 可见；`T40.write-batch-failure.sqlite` 补单条多行 UPDATE 末行 CHECK 失败整批回滚、64 行旧值保留且邻项零残留。Y-A4 由既有 WAL/backup/future-schema 与 system 恢复/安全停止用例承担；Y-A5 仅 D 待跑，不把短窗或组件证据当完整性能/资源通过。


EG1–EG2 提交期 EchoGate 再检沿用 `T40.write-batch-isolation.sqlite` 的独立 eg 命名空间：EG-A1 hook 内 echo_gate → matchBatch 成功但 routing_work held/echo_gate、cursor 不动、无新投递/决策/贡献；EG-A2 hook 内 echo_index → matchTurn 的 no_match 邻项与目标同批均 ok，目标 done/own_echo 且无投递/决策/贡献，覆盖空 planning finish；EG-A3 预置 blocked/routing_incomplete/rev1 与非空 cursor 的 held 竞态，旧行与 cursor 逐字段不变且无 ready 解锁；EG-A4 echo 分支 replace 注入 revision_conflict，目标单项回滚/邻项提交/原错误码保留，hook 独立写入的 gate 仍存在。所有故障/spy finally 恢复，不新增 Case ID；EG-A5 仅 D 待跑。

EG D整合：独立eg夹具放在旧T40断言之后，使用独立EG-R recipient；no_match邻事件在chat-2且保留两订阅候选，晚到gate仅作用chat-1，避免把邻项一起held。每个向量finally删除本夹具echo事实并恢复fault/spy，hook标志逐次重置且安装前断言事实为空；SQL spy保留原db receiver，既有9003号投递由route序号9003覆盖。恢复原case括号并修正新hook声明作用域。仅测试夹具修正，EG-A仍待新冻结执行。

EG-A4 D断言对齐：初始routing_work未持久化reason键，回滚后缺失仍应缺失；改为对比before-4完整记录，而不是将undefined误断言成null。state/cursor/原领域码与邻项提交等原断言保留，业务源码不变。


同组匹配容量计数复用回归（G1–G2）：原固定搭档写入G-A1/A3/A6后两次正式交回仍缺A2/A4/A5，root接回同一三文件所有权，现已一次补齐整个B源码，未编译、测试或静态预检。全部复用T40.write-batch-isolation.sqlite的独立g块，不改cases.json/旧断言/helpers。G-A1两组16事件各一次global COUNT、单route逐事件COUNT、matchBatch真读、空/no_match不读；同一route的两订阅合并，33事件为33 deliveries、66 decisions/66 contributions。G-A2真实五状态9998→10000以及同route999→1000，后续事件阻塞且不超限；临时填充行finally清理。G-A3中间/首/末项revision_conflict及新组重读，失败项原序号/投递/决策/贡献回滚，邻项提交。G-A4真实17条contributions第二块FK异常整批回滚、原COMMIT注入失败后新组真读，echo/no_match零COUNT。G-A5暂收本测试queueMicrotask flush，60+16仅前4接纳、64+16全拒绝，原64上限和全部Future终态可观测，finally恢复并执行尚挂起的自有回调。G-A6在真实打开事务中检查非法state的TypeError、work/SQL零调用，成功发布实际数值、关闭planning/共享state、failure/domain异常/thenable/漏finish均失效。G-A7待全部C后集中D，源码写齐不表示已通过。


M1–M3 物理捕获新增两 Case（不新增其他入口）：`T70.resources.unit.capture-controller` 验证 native usage 解码 64 位出生与 RSS/physical 分离、request/binding 全非法拒绝、601 点 fake sampler、驱动 stdout 8MiB/1MiB 分流；`T70.resources.integration.native-reader` 验证自身 process.pid 真实只读 libproc 两次出生一致、保护 binding 文件全部拒绝路径、stream 请求与 fake handle 关联。两者都不代表真实四角色 60 秒、256MiB 或完整物理验收。

M B由root在原Go168明确部分交回且进程清理后接回补齐：request/binding/stream全边界、601点模拟与早timer/迟到/缺口/回退、后代/孤儿/退出/复用/嵌套外部根独立分类、33进程/截断/UID权限失败，以及真实CLI失败的安全输出/自有child收尾。所有测试先写未运行；模拟数据和自身libproc均不构成真实部署256MiB证明。原B部分字节副本与交回说明保留。

O1–O3 新增两 Case：`T38.opencode-observer.unit` 用注入 transport 证明请求/绑定先校验、三操作白名单、分页与消息/assistant 证明、empty 空会话和所有上限/失败，不把 fake 当真实原生证据；`T38.opencode-observer.integration` 用自有 loopback HTTP/真实 fetch/编译 CLI/私有绑定证明关联、Basic、路径、保护文件、stdio 边界和固定失败，不接触真实 OpenCode/模型。T51 仅补 session.get→native_session_id 映射与 session_key 回归；真实 endpoint/凭据/专用资源授权、Pi/native-start 跨工具装配、真实 E2E 和 M 短进程拓扑仍开放。

O D证据对齐：build106 unit43的77项与integration62新O项通过，174/175独立审核已采用root补齐B及五组必需断言。新增断言精确覆盖错instance/未授权native ID前置零HTTP、两反向origin/错assistant session、完整元数据与正文不回显、CLI exit1/固定stderr/null关联字段、1024成功与第17页的1025组合拒绝，并覆盖第二页parent/不透明cursor/超限reader取消。949为既有字节不变范围的组合覆盖；真实endpoint/凭据/资源验收仍未运行，不能由本地fixture替代。

`T38.lark-acceptance.unit`：LI-A1..A3，固定 CLI 响应替身验证纯组件范围/身份、持久单次刺激与原生原始回复证明；8 页/400 行、50 个目标、分页重复/错误 schema/字节/期限全部保守失败。`T38.lark-acceptance.integration`：LI-A4..A5，独立受保护 SQLite、已提交 unknown 的第二连接读取、重开与 typed/JSON 守卫、实际自有 child/stdio 限额、取消和固定错误出口；fixture 无外发且不用于真实账号证据。LI-A6 的构建/范围/独立审核在全部 C 后执行；LI-A7 真实资源未获批准，仍 not_run。

LI本地证据：build109 unit45完整78/78（1023断言）及integration65新增1/1（87断言）；固定独立178确认177规定的范围修复和四组必需向量。真实Lark与总体交付未通过，组合覆盖951不表示单次全量或真实平台通过。

T38.pi-observer.unit（PO-A1/2/4）：正反origin、严格header/唯一entry与最近user祖先、错误/环/缺失/未来链、8192/8193与1MiB完整行、无正文输出、精确tool分流/无跨平台fallback、direct前拒绝缺权限与地址漂移。T38.pi-observer.integration（PO-A3/5）：常规0644原生日志只读、0700/0600绑定、LF精确8MiB边界、Unicode前片/未完成尾片、已完成坏UTF8拒绝、读中append/truncate/replace/期限与handle回收、真CLI固定错误/正确关联及原O本地HTTP接线。T49.direct-control.pi.real（PO-A6/7）：新增Pi无IM直发→原会话started→原生日志输入证明，复用两工具共享步骤；待真实授权资源，未运行。全部本地/真实类型分清，不以fixture证明平台接入。

PO D必需补强：多个合法assistant按原追加位置选最早；不变文件的正数短读失败并关闭句柄；行中截断明确检查前字节非LF及截断后目标尾部；native/pi保护绑定各超64KiB拒绝。仅本地边界，不增加真实授权。

PO build115本地D及180独立增量审核通过，unit48完整79/79、integration68 PO 1/1（98断言）；Pi companion真实用例仍not_run，不将本地fixture记为平台通过。

T63.opencode-native-read.integration 补充当前 OpenCode 消息分页与有界缩页；T38.native-access.unit 补充原生游标的会话绑定/格式拒绝。两者不替代独立 recipient 订阅回复的真实证据，也不扩大为全工具/性能矩阵。
