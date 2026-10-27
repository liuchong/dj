# 统一 Agent 会话查询与消息控制面

日期：2026-10-23；追加设计基线 f8297b8，整体复审基线 bd6b8e2。全部仍为设计，未启动工具、创建会话或发送消息。DJ 同时支持“IM 事件按订阅转发”和“调用者经统一接口直接操作 Agent 会话”；后者不依赖订阅、IM 连接或模型推理。

## 产品职责与对象

DJ 是无 AI 的跨进程消息组件。它机械列举、索引、过滤、读取、发送，并按显式请求启动预配实例或创建原生会话；不判断任务应该在哪、不规划任务、不选择合适模型、不解析 IM 管理命令。首期入口是 CLI、MCP、本地 API，无 IM 操作界面、Web/桌面管理台或 TUI。

| 对象 | 意义与身份 | 与已有对象的关系 |
| --- | --- | --- |
| ToolDescriptor | tool_id，如 opencode/pi；描述适配器、安装/配置与能力 | “某种 Agent 工具”按 tools 过滤，不等同 agent_id |
| LaunchProfile | profile_id/revision；操作员批准的 executable/argv/工作区/资源/权限与凭据引用 | 模型只选已授予 profile，不传任意 shell/路径/模型配置 |
| ToolInstance | instance_id、tool_id、namespace、instance_epoch、ownership(existing/managed)、profile_id?、state、revision | 一个运行实例可有多个会话，历史来源也可离线 |
| SessionRecord | session_key、instance/namespace、native_session_id、标题、workspace_ref、created_by?、时间、原生状态、来源/覆盖/观测时间 | 未登记、未订阅也能出现在目录；标题不是身份 |
| SessionHandle | session_ref、principal_id、session_key、instance_epoch?、expires_at | 机器可复用的 Agent 会话引用，默认 10 分钟；不与 IM conversation_ref 混用 |
| TargetRoute | route_id、canonical_target_key、session_key、临时 binding | 同一原生会话共享调度/unknown 屏障；不等于授予权限或注册 Agent |
| AgentTarget | 既有 agent_id 与 recipient/owner 绑定 | 专用于长期订阅/主体接线，指向 TargetRoute；agent.list 仍只列已登记目标 |
| CatalogRun | catalog_run_id、选择范围、扫描 checkpoint、状态/预算/覆盖 | 有界目录刷新工作，不启动或唤醒 Agent |
| LifecycleAction | lifecycle_id、start/create/stop、请求摘要、资源引用、state、revision、原生观察 | 启动/创建/停止单独核对，不冒充消息 Delivery |

同一原生会话的多个视图用适配器已证明的 canonical key 合并，保留 observations；相同标题或不同 namespace 中相同原生 ID 不能合并。多个历史来源未证同一身份则分列并显示关联不明，不靠正文相似度猜。AgentTarget 不自动变成工具进程，多会话目录也不自动注册为订阅目标。

稳定 session_key 来自 tool/native_namespace/native_session_id，instance_epoch 不进入稳定身份；epoch 只限制临时接收 Binding。SessionRecord 的来源观察可有多个实例视图，只有已证明后端相同才合并，不能仅凭同一存储目录或标题推断。

## 范围与确定性查询

所有范围可省略为“当前主体获准的全部配置来源”，不是整个机器、任意账号或所有厂商全量数据。已获准范围的未装配、离线或能力缺口必须给覆盖状态，不能静默跳过后报全量无结果；显式越权范围返回 forbidden 且不泄露资源是否存在。公开工具描述符的 unsupported 不包含其私有实例信息。

scope 固定字段如下，未知字段拒绝；多个维度 AND，同一数组内 OR，显式空数组拒绝：

- tools：tool_id 数组，最多 32；支持只查一种或若干种工具。
- instance_ids、workspace_refs、agent_ids、session_keys：各最多 100。agent_ids 只筛选这些已登记目标对应的原生会话，不表示一个 agent_id 自带子会话；session_keys 可精确选择未登记会话，用于定点刷新/消息检索，不是授权凭据。
- visibility：history/live/desktop-open/managed 数组；按可证观察过滤。desktop-open 缺证据时不能拿 live 或 history 代替。
- runtime_states：既定 unknown/idle/busy/waiting_permission/offline/incompatible；registered 为可选布尔值。
- updated_range：UTC RFC3339 的 from 包含、to 不包含；原生时间缺失不假造为 now，单独 unknown 计数。

session.list/get 从目录快照读取；get 接收 session_ref 或稳定 session_key 二选一，成功时可重新签发当前主体的短期引用。session.resolve 以 instance_id + 精确 native_session_id 核对并找回引用，不按名称选目标。session.probe 对一个 session_ref 执行只读原生身份/receiver/状态探测，返回 checked_at、有效期、能力与安全摘要；不启动、不发送测试输入、不注册目标。不能核实时保留 unknown/offline，不把目录存在当 live 证明。session.search 返回会话级命中，session.message.search 返回消息级命中，二者复用同一检索引擎。查询数据不生成 Event、不推进 ingress_seq、不创建 Subscription 或 Delivery。

live/desktop-open 只依据新鲜原生观察，缺省 30 秒未续证就不再以该标志匹配，依赖该观察的 idle/busy/waiting_permission 降为 unknown、来源标 stale/partial。原生进程退出等已证 offline/incompatible 事实不因计时过期反变 unknown，直至新的相反证据；历史存在事实也不受此超时抹除。会话运行状态与目录观察时间分开，不能把旧缓存标题当作此刻运行证明。

query 固定为 {text,fields,mode}：text 非空且最多 1024 UTF-8 字节，mode 首期仅 literal、区分大小写、不做 Unicode/同义词/分词/正则转换。session.search 的 fields 为 title/native_session_id/workspace_label/message.text 的非空集合；message 搜索只允许 message.text。原始机器路径不进入 workspace_label，使用获准工作区的安全标签。多字段按 OR，返回 matched_fields、原文片段/偏移与内容覆盖；没有相关度、置信分或“最可能属于任务”评价。

片段 offset_bytes/length_bytes 按原始 UTF-8 正文计数，绑定正文修订；不拿宿主字符数替代字节偏移。片段和计数同样按授权过滤，正文未授权不退回泄露命中片段。

session.list 默认 sort=session_key_asc，也允许 updated_at_desc（时间降序、session_key 升序，缺失时间排末），后者必须使用有序目录索引。session.search 仅允许 sort=session_key_asc；session.message.list/search 固定按 session_key、原生顺序键、消息稳定键升序，不接受 sort。适配器无 native_message_seq 时必须保留确定的顺序键及其来源，不伪造原生时间顺序。文本命中不支持全局时间/相关度排序；预算内未扫描的数据不能与已返回结果竞争排名。未知排序值拒绝，不接受 SQL/FTS 语法或任意表达式。

## 快照、覆盖与刷新

分页复用 limit=50、上限 200。会话/消息目录查询额外返回 snapshot_id、as_of、coverage_complete、sources、stale。complete 只表示快照分页是否读完；coverage_complete 才表示选择范围内所需元数据/正文都具备覆盖。sources 按可见来源列出 covered/partial/offline/unsupported、最后观测时间、字段/内容范围、缺口原因和原生限制；未授权对象连计数也不可泄露。

默认查本地索引，列表不触发慢速全平台扫描。调用者需要新数据时显式 catalog.refresh：可选 include_content=false（默认）或 true、scope 与预算。服务返回 operation_id/catalog_run_id，自行按受限批次读取适配器并更新目录；catalog.get 看状态。没有相关来源也保留可解释空范围；未完成或离线不能等价为“不存在”。

刷新每轮最多 100 条元数据或 32 条消息/1 MiB 正文，来源并发最多 4；每轮让出执行，扫描与索引 checkpoint 原子提交。一次 refresh 最多读取 10000 条元数据、1000 条消息/16 MiB 正文或运行 60 秒，先达上限即 partial；记录剩余范围与 continuation。后续显式 refresh 可提交该 continuation，仅在同主体/范围/授权下续扫。预算是上限，不承诺厂商一定可遍历全量。服务可对已配置来源做有界增量刷新，但不能让调用方 Agent 设置拉取定时器。

原生只有全量响应时，不能把 DJ 的 limit 冒充源分页。适配器限制接收大小，超过单帧/正文预算标 partial/oversized；Pi get_messages 等超长 JSONL 响应以有界缓冲排空至帧尾，不杀正在使用的工具、不把整个历史载入内存。每连接同时最多一项此类目录请求，响应关联与事件流仍由同一解码器管理；溢出帧的请求若无法可靠关联，相关在途请求一律保留不确定状态。排空期限默认 5 秒：见到帧尾才可恢复边界；期限耗尽或持续无边界则隔离协议通道、停止新请求/输入，不强停进程，将可能已写出的输入标 unknown、目录标 partial。不得凭截断 JSON 猜成功；后续只在边界/身份重新核实后恢复。不能证明索引候选覆盖所需字面字符时改用受限精确扫描，不丢可能命中项。

施工默认目录单帧上限 1 MiB，受适配器更低限制约束；这是服务接收预算，不宣称原生支持分页。完整输入信封还须按编码后帧大小检查原生能力，正文 16 KiB 不代表任意协议都能接收相同长度的编码帧。

索引只保存授权范围和允许保留的字段；正文索引必须有单独 session.read/search 权限及显式配置，不默认抓取所有磁盘历史。源撤销/删除已知时同时屏蔽目录、正文、片段与索引；源不可见期间标 stale，不谎称掌握最新删除。游标默认 10 分钟，绑定主体、范围、排序、目录快照与授权修订；权限变化拒绝旧 cursor。历史/索引读取和 live probe 的观测时间分别保留。

## 机械搜索的实现选择

复用 SQLite：工具/实例/namespace/会话 ID/工作区/时间/状态走 B-tree；字面文本候选走 FTS5 trigram，随后以原文精确复核。用户输入先安全绑定并编码为字面内容，不直接当 FTS 表达式执行。索引同步与正文版本同事务；版本不一致时拒绝拼接片段。[SQLite FTS5](https://sqlite.org/fts5.html#the_trigram_tokenizer)

少于三个 Unicode 字符、无法用索引的条件或缺少 FTS5 时用有界精确扫描；每请求最多检查 1000 条记录或 4 MiB 正文，达到上限保存 next_cursor，complete=false，不能把剩余当无匹配。FTS5 是否可用启动实测，首期文本搜索发布要求通过索引与短串路径验收，不以回退扫描冒充已达性能。无 LLM、embedding、向量库或外部搜索服务。

每个查询快照最多保存 10000 个结果引用，同时最多 32 个快照；超过则 limit_exceeded，要求收窄范围，不暗截断报完整。默认最多 100000 条会话元数据，正文/索引合计 512 MiB；超限停止增量并显示 capacity_exceeded/partial，不淘汰条目后冒充全量。正文保留默认获取后 7 天，目录刷新与过期清理不能删除未结算动作/投递证据。查询/刷新配额独立且不能挤占事件投递；目录规模、索引大小、扫描量、延迟和事件循环停顿纳入 T57。性能基于实际数据规模分别报告，不把缓存命中当新鲜全量发现。

短串回退按上述稳定顺序读有界记录页再在应用层匹配，剩余扫描位置写入 next_cursor；不能用一个无索引 LIKE 加结果 LIMIT 冒充扫描预算。FTS 候选也按相同稳定键分批获取、精确复核和推进快照，不先物化/排序所有命中。预算到而尚无命中可返回 items=[]、complete=false 与非空 next_cursor；调用者须续查，不能解释为无匹配。会话级检索的组内扫描进度与命中字段一并保留，完成该组后才输出，跨页不重复/漏会话。查询 cursor 与刷新 continuation 为两种互斥引用，不得混用。

快照是带 catalog_seq 水位的逻辑版本视图，不持有跨请求 SQLite 读事务。元数据/正文/索引保存可见版本区间，cursor 固定水位与最后扫描键；写入、刷新和 WAL checkpoint 不等待客户端翻页。正文删除、权限撤销优先于旧快照，相关 cursor 立即失效；版本保留超预算时显式失效受影响快照，返回 cursor_expired/reason=snapshot_evicted，不能改读新版本后继续伪称原快照。版本也计入存储配额。

刷新只追加已证观察：预算耗尽、过滤结果为空、断线或单页成功都不能推断来源会话已删除。仅原生明确删除，或同一稳定范围的完整枚举且协议保证可判缺失时，才产生 tombstone；无法证明则保留 stale/partial。本地已索引正文的字段/时间覆盖与原生仍保留的全历史分别说明，coverage_complete 不因分页读完而变真。

## 统一操作目录

下表补充统一业务契约，公共幂等/鉴权/分页/envelope 规则仍见 interfaces/operations.md。get/list/search 无模型和发送副作用；refresh 有持久台账但只读外部数据。

| 操作 | 输入（公共字段另附） | 主要输出 / 权限 |
| --- | --- | --- |
| tool.list/get | filters? / tool_id | 描述符、配置/安装观察和能力；tool.inspect |
| profile.list | tools? | 获准 profile_id/revision、workspace_refs、动作范围；profile.inspect，不输出 argv/秘密 |
| instance.list/get | tools?、ownership? / instance_id | 已知实例、epoch、归属、状态与会话覆盖；instance.inspect |
| catalog.refresh | scope?、include_content?、continuation?、budget? | operation_id/catalog_run_id；catalog.refresh + 必要 read |
| catalog.get | catalog_run_id | queued/running/partial/done/failed、覆盖与 continuation；自有/授权 run |
| session.list | scope?、sort? | SessionRecord、session_ref、覆盖与下一页；session.list |
| session.get | session_ref 或 session_key（二选一） | 会话安全元数据、当前 session_ref、索引/原生状态及能力；session.inspect |
| session.resolve | instance_id、native_session_id | 精确 session_ref 和摘要；session.inspect |
| session.probe | session_ref | 精确原生身份/receiver/状态观察与能力；session.inspect，不唤醒 |
| session.search | scope?、query、sort? | 会话级命中及可读引用；session.search，正文另需 read |
| session.message.list | session_ref、time_range?、corpus? | 消息摘要、session_message_ref；session.read |
| session.message.get | session_message_ref、offset_bytes?、max_bytes? | 元数据、正文分页与版本；session.read |
| session.message.search | scope?、query、time_range? | 消息级命中、原会话/消息引用及片段；session.search/read |
| session.send | session_ref 或 agent_id（二选一）、content、delivery_policy? | operation_id/delivery_id/route_id；session.send，免订阅 |
| instance.start | profile_id、expected_profile_revision | operation_id/lifecycle_id/instance_id；对 profile 的 instance.start |
| session.create | instance_id、expected_instance_epoch、workspace_ref、title? | operation_id/lifecycle_id，核验后给 session_key/session_ref；session.create |
| instance.stop | instance_id、expected_revision | operation_id/lifecycle_id；仅自有 managed 的 instance.stop，优雅 drain |
| lifecycle.get/reconcile | lifecycle_id | 启动/创建/停止的状态与证据；自有/授权 action，reconcile 带幂等键 |
| lifecycle.resolve | lifecycle_id、resolution=abandon_no_retry、reason | resolved/manual，不重发/不伪造 ready；仅操作员 |

filters 只接受 tool.list 的 tools/adapter_state，其他列表按表中字段；corpus 首期 indexed，native 是适配器显式扩展且不隐式回退。SessionHandle 与 session_message_ref 默认 10 分钟，后者绑定消息版本；get 分页沿用 IM message.get 的 UTF-8 预算。refresh budget 只允许低于上述上限的 max_records/max_messages/max_bytes/max_seconds，不能抬高服务预算。create 的 title 可省略，提供则非空、最多 256 UTF-8 字节，不作为关联键；workspace_ref 必须在指定 ready 实例的获准范围内，stopping/离线/epoch 漂移都不提交创建。

## 免订阅直发

目标已经明确时直接 resolve/get → session.send；不要求 IM 来源、Subscription 或 AgentTarget 登记。不允许“发给任意匹配会话”或向搜索结果隐式群发；一次请求只接一个精确目标。历史目录引用可以读取，发送必须重新核验真实 receiver/epoch；offline 按 hold 保持原目标，默认不启动、恢复或换目标。

session.send 与 message.send 不同：前者向 Agent 原生会话输入，后者向 IM 发送。content 为既定纯文本结构，非空且最多 16384 UTF-8 字节；delivery_policy 只允许 busy、offline、ttl_seconds，默认 queue/hold/86400，TTL 为 60–604800 秒。首期只接受 queue/hold，其他策略 unsupported；context_policy/current/selector 不属于直发输入。直发只注入本次内容，不附带 IM 历史；不得截短后冒充完整发送。原生限制在受理前可知时拒绝超限；排队后能力变小则 blocked/limit_exceeded，不写出。发送主体需要对该原生会话的 session.send grant，登记自己的 agent_id 不授予跨目标发送权。

受理事务建立 Operation、必要的内部 TargetRoute、origin=direct 的 Delivery 与请求授权快照，不注册 AgentTarget、不生成假的 IM Event/订阅/Contribution。信封 kind=external_message，source.kind=api、sender=认证主体，reply_context_id=null；对方原生回答仍留在其会话，通过 session.message 查询读取，不自动回任意 IM。

订阅投递与直发使用相同 canonical route、Binding 校验、持久队列、submitting 提交点、unknown 屏障、核对/重试/取消及回执。不能用直发绕过同目标未结算输入。delivery.get/list 可见 direct origin 和可空 agent_id/event_id；直发主体可查自己的受理记录，在当前授权下控制自己的未提交输入，不能据 route 读其他人的投递。登记、注销不创建第二条 route、不清屏障，也不取消其他 origin。agent_id 只作为受理时别名，后续登记不倒改旧 Delivery 的 origin/所有者/历史字段。同键同请求一次受理，相同正文不同逻辑请求不做语义去重。订阅事件去重与直发幂等分开。

## 显式启动与创建

instance.start 只能选择获准 LaunchProfile，不能把 cwd、argv、endpoint 或凭据作为自由输入。每 profile 首期一个活动 managed slot：已就绪且配置兼容则返回同一实例；正在启动则新 Operation 引用同一 action；stopping 返回 instance_not_ready，归属/存活未知或配置漂移则 profile_conflict。不会把外部同名工具进程当作该 slot，也不在 query/send 失败时自动调用 start。

不同获准主体复用同 slot 时，各自保留自己的 Operation，只取得当前权限允许的 action/实例安全投影，不暴露原请求主体/摘要/秘密；复用不复制 created_by、recipient 或新会话读取权限。action 的历史结果引用不改变实例当前状态。

启动先将 LifecycleAction、预分配 instance_id、profile 修订与 launch_token 原子记账，再以参数数组启动并等待可验证握手。握手成功与原生身份/epoch 对上才 ready；存活 PID 不等于 ready。重启时先核对该 token 的自有进程与注册事实，不能因响应丢失又启动一份。旧 slot 只有已证进程退出/不存在才能释放；lifecycle.resolve 只结案，不证明进程不存在、不释放启动栅栏。释放后再次 start 分配新的 instance_id/epoch/launch_token，并保留旧实例历史。是否随 DJ 自动恢复仍由显式 profile 策略决定；恢复同一原生 session 的身份必须另证，不保证新实例有旧会话。

expected_instance_epoch 是 DJ 的前置核对，不自动成为厂商原子的 fencing。外部实例在检查与写出间重启而原生不支持条件请求时，须在观察中再次核验 namespace/epoch；漂移则 incompatible/unknown 并保留可能已创建的事实，不能声称零外部副作用或跨进程绝对独占。

session.create 仅向指定运行实例、获准工作区发起一次空会话创建；不传 prompt，不调用原生 init/summary 自动启动模型，不复制调用者的 recipient 凭据/权限或偷偷注册订阅。返回的元数据不证明 Skill、回复工具或桌面当前 Tab 已接线。创建后调用者可按原 grant 单独 send；需要长期订阅时再核验候选、登记 recipient 并建订阅。

服务记录 created_by 供预配策略核验；若 profile/workspace 的授权模板原本允许调用者读取/发送自己创建的会话，就在该范围内使用新资源。没有对应 read/send grant 时，create 不额外授予它们，不复制调用者的其他会话权限。

ready 的 LifecycleAction 保存稳定 resource_refs：start/stop 的 instance_id/instance_epoch，create 的 session_key/instance_id，Pi start 另保存 initial_session_key。lifecycle.get 总是区分历史动作结果与当前实例状态，按当前授权重发可读会话的短期 session_ref；旧幂等响应中的过期引用不会自动执行动作或更换目标。也可 session.get(session_key) 重新取引用。未授予读取时保留允许的动作摘要，不因返回引用扩大权限。

“创建后用于 IM 订阅”必须走独立接线：可信宿主/操作员选择预先存在的独立 recipient，按已核验 session_key 固定其 target_constraint，把获准 client profile/Skill 接入该实际会话作用域，再 discover/register(recipient_principal_id)、核对 whoami 与 reply 工具，最后 preview/create。普通调用者不能修改自己的既有绑定、生成凭据或把自身权限复制给新会话。首期允许这段由部署操作员完成，不承诺 create 自动配好接收主体；只有直发需求则完全不需要这段。

对原生创建/启动调用，写出后无确定响应或恢复无法关联时为 unknown；重放原幂等键查同一 action，不能按标题猜新建结果或自动换键再建。reconcile 只按 launch token、原生关联键等明确证据找回。无法证明时操作员只能不重发结案，保留可能存在的孤立资源，不能标为原生 ready 或无资源。

LifecycleAction.state 为 pending/submitting/ready/unknown/failed/resolved；ready 意味相应动作被原生核验（stop 则核验 stopped），不是模型任务完成。instance.state 为 starting/ready/stopping/stopped/offline/unknown/incompatible，原生会话 runtime_state 独立。instance.stop 仅处理 DJ 所有 managed 进程：停止新提交并 drain，等待当前工作到安全边界再优雅结束；超过配置期限保留 stopping/限制，不杀借用进程、不强停原任务。原有订阅/直发保持原 route，之后 offline hold 或到期。

所有控制路径共用持久 instance gate/revision：stop 的受理事务先置 stopping 并关闭新原生提交；create 的 submitting 事务与 Delivery 的 submitting 事务都必须核验该 gate、epoch 和当前授权。先提交的在途动作保留事实并纳入 drain；stop 先提交则后续动作不得写出。stopping 时新 session.send 或订阅 create/update/resume 返回 instance_not_ready、effect_state=none；既有订阅可继续接收事件并 hold，已有 queued 不必清空才能停止。stop 只等待原生工作、已越提交点动作及 unknown 核清，不等待所有未提交队列；unknown 未解除就不杀进程。重放原键先返回原记录，不受新 gate 误判为新请求。并发 stop 新键引用同一活动 stop action，版本不符仍 revision_conflict。

正常停止 DJ 与 instance.stop 使用相同 drain 边界。进程外 managed Agent 的监督策略须保证 DJ 服务停止不会向活跃任务连带发送强杀；不可重连的 stdio 子进程只有达到安全边界才关闭管道并结束。期限届满保留服务 draining，状态读取、reconcile、获准 manual 结案和暂停/取消仍可用以核清在途；新 start/create/send/订阅启用拒绝并返回 unavailable、effect_state=none。外部 SIGKILL/系统崩溃只能记录中断风险并按 unknown 恢复，不能宣称保住原生工作。重启先恢复未知和 slot 栅栏，再执行明确 auto_start/resume_policy；自动策略也走同一生命周期台账、归属核验与 slot 约束，绝不无条件直接拉进程。

## 首批适配与能力差异

| 工具形态 | 首期查询与发送 | 创建/启动 |
| --- | --- | --- |
| OpenCode 本地 HTTP | 已配置 server/namespace 的会话与允许正文可刷新索引，向精确 session 投递 | 运行实例内创建空 session；新增获准 managed serve profile 启动方式，existing 仍不被接管/停止 |
| Pi managed RPC | 已配 profile/实例的当前会话与 get_messages 范围；历史只覆盖已采集目录，不声称全盘历史可查 | start profile 建立/恢复获准初始会话；首期对正在用的同一 RPC 实例 session.create 返回 unsupported，避免 new_session 切走原绑定 |
| 其他已列工具 | 统一 scope/字段/能力契约适用；未装配适配器返回 unsupported/unknown 覆盖 | 保留厂商专用设计；不假装任意 TUI/桌面均可接管或启动 |

OpenCode 的公开接口可列举/创建会话和读取消息，Pi 的 RPC new_session 会改变会话状态，因此不能把共同 create 名字解释为相同的无影响操作。[OpenCode Server](https://opencode.ai/docs/server/)、[CLI serve](https://opencode.ai/docs/cli/#serve)、[Pi RPC commands](https://raw.githubusercontent.com/earendil-works/pi/main/packages/coding-agent/docs/rpc-commands.md)。以上是协议依据，不是本轮实机支持声明。

## 三条独立业务流程

1. 找已有任务：tool/instance 列表 → 必要时 catalog.refresh → 按工具/工作区/时间等 session.list/search → get/read 消息 → 由人或调用方模型判断；DJ 不输出任务归属推断。
2. 已知会话直发：精确 session.resolve 或已有 agent_id → 核对摘要/能力 → session.send → delivery.get/reconcile；全程可以没有订阅或 IM。
3. 明确要新工作会话：profile.list → instance.start（需要启动时）→ lifecycle.get 到 ready → session.create（实例支持时）→ get 到 session_ref → 单独 send；Pi start 已产生初始会话就直接用该引用。任何一步 unknown 都先核对原动作，不自动换方式。

这些能力都是协议操作，不增加 DJ 的任务规划器。实现授权、消息授权与原生权限分别生效；本轮设计本身没有启动任何工具。
