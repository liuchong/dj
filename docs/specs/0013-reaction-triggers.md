# 0013 — 可配置的消息表情触发

与原生提及、私聊并列支持“添加指定表情”触发。采用现有订阅 selector/predicate，不增加另一套路由、队列或身份体系。按平台原生 emoji_type 精确匹配，大小写敏感，可用 in 配置一个或多个。Lark 图钉表情为 Pin，不是中文名称、Unicode 图钉或群消息置顶接口。

## 当前规范与实现

- 官方 im.message.reaction.created_v1 → message.reaction.added。保留原 native_message_id、chat/thread、消息作者和正文；reaction 独立记录原生事件 ID、添加时间、emoji_type、operator.id/kind/is_self。source_key 使用同一消息、表情、原生添加者及 action_time 的稳定摘要；WebSocket 与 HTTP 对同一次动作共用该键。删除表情不触发，也不撤销已受理输入；移除后重新添加是新动作。
- 原消息的 mentions 仅是上下文，不伪造新提及，addressed_self/addressed_bot=false。回复不套用原消息其他人的提及；已确认回应目标的作者可按0015及同一reply_routes固定出口，未命中保持来源身份和原消息位置。
- 先读当前身份的本地消息缓存；缺失时只按事件给出的准确消息 ID 直接读取官方 HTTPS API，不搜索、不改写原文。缺权限、消息已删或不可读时不凭空补正文，保留原生未确认重试和源错误。持久入 inbox 后才 ACK。
- selector.event_kinds 显式加入 message.reaction.added；predicate 支持 reaction.emoji_type、reaction.operator.id/kind/is_self。没有 reaction 的普通消息对应空字符串/false。默认订阅仍只有原生 @，不会自动扩大全部用户的触发范围。
- 原消息作者与表情添加者均经过同一服务级人员黑名单；字符黑名单使用原正文。消息仍记录、可读，只限制触发。提交时继续重检授权、身份、订阅和过滤规则。
- 人工对 DJ 已发消息加表情可触发，不误判为原消息回声。DJ 自动 Typing/Get 按 work_marks 的身份、请求时间及原生 action_time 判别回声；结果未明确先 hold，防止自触发循环，不按表情名称一律屏蔽人工动作。
- 保留现有多订阅 contribution 合并与独立授权重检。AI 接收原正文、原作者、表情及添加者，仍由 AI 决定是否执行、回复或无需回复。

## 平台边界

应用需订阅 im.message.reaction.created_v1（后台名称“消息被reaction”），具备 im:message.reactions:read 或 im:message:readonly 之一。读取原正文还受消息读取权限约束。机器人只能收到其所在会话中的表情事件。用户 HTTP 可读/可加表情不证明应用 WebSocket 已收件；应用未在群中时以本人 HTTPS 表情列表补收，明确标记 poll；connection.probe.last_reaction_at 仅记录真实接收，不由配置推定。

依据：[官方新增表情事件](https://open.larksuite.com/document/server-docs/im-v1/message-reaction/event/created)、[官方表情标识](https://open.feishu.cn/document/uAjLw4CM/ukTMukTMukTM/reference/im-v1/message-reaction/emojis-introduce)。

## 本批施工与验收

基线 88bf7d2。lark-events 帧分派调用 lark-reactions.resolveLarkReaction/normalizeLarkReaction，复用缓存和 history；ingestion 保存 reaction；operations/rules/results 同步事件和字段；filtering、echo、working、reply route 保持统一语义；envelope/message/context 保留元数据。SQLite schema 不变，扩展现行 payload，不加兼容入口。

- [x] 一次完成业务、公开 schema、Skill 和说明。
- [x] 集成：原生帧→持久 inbox→规则→准确 Agent 输入；单/多表情、作者与添加者黑名单、thread、去重及自动表情回声。
- [x] 关键保护性测试：原生标识、身份/事件校验、非表情规则及回复路由边界。
- [x] 本机常驻服务已更新为 ready，经公开 preview/update 接口配置 Pin，并读回确认原提及/私聊规则、提示词、目标及投递策略保留；没有加群或改变用户凭据。
- [ ] 用户指定但接收应用未在其中的群，平台新增事件与原对话实时读回尚未验证；遵守不加群要求，不把旧记录、重放或 HTTP 补收冒充 WebSocket 实时通过。

首次表情接入定向检查：6 项通过、138 条断言；WebSocket 帧接收器和 HTTP 响应为明确测试替身，验证持久 inbox 和真实 Core 投递，不冒充平台实时验收。真实平台覆盖需另有新增事件及准确接收对话读回证据。

同一应用可以使用用户与应用 token 调用各自支持的 HTTP API。官方允许同一应用多个 WebSocket，但消息是集群随机分发，不能把两个客户端命名 user/bot 就当成独立用户收件流。多个逻辑身份应共用该应用的事件接入后分发；换 OAuth 身份不扩大 IM 事件的会话覆盖。同应用身份切换还需对应应用签发的用户授权，不能复用另一个应用的 token 或 OpenID。


## HTTP 表情变化补收与调度

WebSocket 新增事件仍优先直接接入。HTTP 用同一身份的官方表情列表弥补事件覆盖
缺口，不模拟推送，不改变订阅或消息可见度。只有连接存在有效
message.reaction.added 订阅时才读取本地仍保留、正文未过期且属于当前连接身份的消息。旧身份缓存仍保留供审计，但不参与当前身份的表情扫描，避免在身份栅栏上反复失败。

### 职责与共享边界

| 模块 | 唯一职责 | 共享范围 |
| --- | --- | --- |
| lark-events | 官方长连接、持久 inbox、事件确认 | 该来源连接 |
| lark-inbox | 普通消息、快速表情、历史表情三个异步岗位；持久断点、失败重试和公平调度 | user/bot 同一实现，连接间独立状态 |
| lark-reactions | 选择待检查消息、读取一页表情、规范化动作 | 四条扫描线共用；HTTP/WS 共用动作键 |
| lark-reaction-cache | 有界观察缓存、近期去重与活跃消息选择 | 同一连接的全部扫描线 |
| lark-reaction-policy | DJ 默认值、按应用共享的表情读取预算 | 同一服务内、同品牌和应用的全部连接 |
| lark-http | 在所有 GET 表情列表请求执行前取得预算；处理取消、超时、429退避 | 包括补收、上下文及工作表情读回，不给每个入口另算额度 |
| Core | 去重、黑名单、订阅匹配与原会话投递 | 沿用统一消息入口 |

普通消息轮询与表情检查不互相占用唯一串行岗位。它们仍共用原有凭据、
官方 HTTP 传输、持久 inbox、事务所有权与入库流程；不为每条订阅新建轮询器。
普通消息读取保留每连接2次/秒的 DJ 保守预算；表情 GET 有独立的应用级 DJ 预算。
预算等待按HTTP请求先后取得名额（最多1024个等待项，超出拒绝），取消/超时删除等待项，防止后台补扫抢占工作表情读回。它不是业务任务队列，不等待 AI 完成任务。

### 四条扫描线与有界观察缓存

| 扫描线 | 选择范围与顺序 | 空闲/扫完后的 DJ 默认等待 |
| --- | --- | --- |
| new | 从已检查的 ingress_seq 水位向后取新入库消息，先立即检查一次 | 200毫秒后再检查是否有新消息 |
| recent | 最近10分钟入库、最新64条保留消息，从新到旧循环 | 扫完后2秒 |
| engaged | 已观察到表情的消息，按最后活动选择最多16条 | 每条通常10秒；活动后60秒内按近期2秒目标；该线最多每秒2个页面机会 |
| archive | 全部仍保留消息，从新到旧循环，兜底旧消息上的后加表情 | 目标整轮60秒；只等待本轮剩余时间，不再额外停30秒 |

每次最多一个表情列表页（50项），分页完成后推进当前扫描线。按实际到期时间轮换：
本进程优先采用内存截止时间，重启后采用持久next_due_at，避免空闲线的旧数据库
时间反复抢先；历史岗位独立运行，持续新消息不占用它的唯一岗位。
快速表情岗位在new/recent/engaged之间按到期时间轮换，历史表情岗位独立推进，
普通消息可同时工作；实际表情HTTP请求仍受同一个应用级预算约束。recent查询仅在最多128条的
有界候选集上筛选；archive 用 events_reaction_scan 索引及 keyset，不全表物化。

新消息检查从消息已由 Core 入库开始，不从平台发送时刻开始。new 首次初始化
记录当前入库水位，重启保留水位；启动前已缓存消息由 recent/archive 兜底。
四条线复用原观察器 activation_at，不因升级重置观察边界或重放已有动作。
缓存外、正文已过期的历史消息不在补扫覆盖内。

200毫秒、2秒、10秒与60秒均为DJ调度目标，不是逐条送达保证。尤其recent/ archive
必须计算整轮消息数、分页数、同应用其他连接/调用、网络延迟与限流；不能将
“扫完等2秒”写成“所有消息每2秒查一次”。新消息的第一次查询可能尚无表情，
之后的添加仍靠实时事件或recent/archive发现。

观察缓存最多512条小型元数据（摘要、最近检查/活动时间、是否有表情），不保存正文或
完整表情列表。消息两秒内已被其他扫描线成功检查时跳过重复HTTP；同一消息在途
检查互斥，其他线稍后重试而不抢先确认。缓存只能在对应inbox与断点持久提交成功后
更新；失败/取消释放占用，不将未提交页面误当作已检查。

完整单页快照摘要不变时，不再重复规范化、计算动作键及写入相同inbox；多页仍逐页
流式处理，不用最后一页冒充完整快照。表情移除后保留60秒兴趣窗口，避免撤下重加
恰好落在一次空列表检查之间后又掉回慢扫。

缓存是可丢弃的调度提示，重启后从最近32条当前身份的已持久表情事件初始化兴趣，
其余由正常查询重新学习；缓存丢失/淘汰只增加查询，不删除历史或跳过触发。
空闲new/engaged检查只更新内存截止时间，不每200毫秒提交一次FULL事务。
last_scan_at只表示本地检查，last_success_at只在真的成功读取HTTP页面时更新；
observations报告缓存条目、节省的读取和未变页面数，不能将缓存命中称作平台增量。

archive_cycle_seconds是整轮目标，不是每条消息时限。轮巡已耗时超过目标时不再
追加等待，也不突破共享预算追赶；消息量增长、网络或其他调用占用预算时会变慢。
对未知旧消息，缺少平台推送/增量接口时，N条候选在R次/秒的可用预算下完整检查
至少需要N/R秒。不能承诺任意旧消息都秒级，同时还不增加资源。

### 平台约束和 DJ 选择必须分开

2026-10-29 查阅官方 IM v1 文档：GET /im/v1/messages/{message_id}/reactions
支持 tenant_access_token 或 user_access_token；公开限额为1000次/分钟、50次/秒。
通常按API、应用、租户计算，不是每个连接、token或订阅各有一份。
新增/删除事件为 im.message.reaction.created_v1 / im.message.reaction.deleted_v1，
事件会话覆盖受平台规则限制；HTTP可读取不等于长连接覆盖。

DJ 当前默认表情读取10次/秒、并发2、突发1，低于上述公开限额；全部GET表情
请求在传输层统一约束。服务内同一应用连接共享，保守地连不同租户也合并预算；
不同进程不能据此宣称共享了额度。多个连接配置不同时采用已登记的最小预算，
提高已收紧的共享预算需要重启服务。其他应用或程序的调用仍可能消耗平台额度，
因此必须遵守实际429及 x-ogw-ratelimit-reset / Retry-After 返回的退避时间。

表情列表只有 reaction_type、page_token、page_size、user_id_type 查询参数，
action_time为输出字段，未公开按since拉取新增动作或批量查询多消息表情的机制。
page_token只是本次列表分页，不是变化同步水位。消息update_time不保证随表情改变，
不得用消息编辑时间替代表情同步。

依据：[新增事件](https://open.larksuite.com/document/server-docs/im-v1/message-reaction/event/created.md)、
[删除事件](https://open.larksuite.com/document/server-docs/im-v1/message-reaction/event/deleted.md)、
[表情查询](https://open.larksuite.com/document/server-docs/im-v1/message-reaction/list.md)、
[频控规则](https://open.larksuite.com/document/ukTMukTMukTM/uUzN04SN3QjL1cDN.md)。
API路径中的v1是平台协议标识，不是DJ自建多版本接口。

### 配置与运行状态

连接上的可选 reaction_poll 字段如下；省略时全部采用 DJ 默认值。

```json
{
  "reaction_poll": {
    "requests_per_second": 10,
    "max_concurrency": 2,
    "new_poll_ms": 200,
    "recent_seconds": 600,
    "recent_messages": 64,
    "recent_poll_seconds": 2,
    "engaged_messages": 16,
    "engaged_poll_seconds": 10,
    "archive_cycle_seconds": 60
  }
}
```

requests_per_second范围1..10，max_concurrency为1..2；new_poll_ms为100..2000，
recent_seconds为60..3600，recent_messages为1..128，recent_poll_seconds为1..60，
engaged_messages为1..64，engaged_poll_seconds为2..60，archive_cycle_seconds为10..300。inbox_poll_seconds只控制普通消息补收，不再代指
表情扫描间隔。connection.probe 的 poll_fallback.reaction_poll 报告 limits_owner=dj、
budget_scope=application_across_connections、policy及new/recent/engaged/archive各自最近成功时间、
扫完与错误状态；policy是本连接配置目标，不是平台配额读回，多连接共享时实际执行较小预算。不得从配置推定实时覆盖或承诺检测时限。

新增观察断点的 activation_at 取首次启用时刻；早于该时刻的既有表情不生成任务。
正常重启保存扫描与分页断点，失败页不推进；失败仅退避自己的扫描线，其他线及
普通收件继续。移除后重加以新action_time区别，统一source_key防止跨线/跨通道重复。
HTTP保留native_reaction_id，native_event_id为空字符串；receive_transport=poll。
Pin不绕过原作者、添加者及字符黑名单，自动Typing/Get继续遵守原回声过滤。

## 历次验收事实

补收定向验收：6项集成、254条断言通过；23项保护性用例、141条断言通过，另1项
原有未来用例保持未实施。集成覆盖真实SQLite与Core、明确替换的官方HTTP和WS边界，
验证上线前图钉不重放、新动作入库和派发、跨通道去重、重启断点与撤下后重加。
保护覆盖分页重复令牌拒绝且不推进断点、原生身份与时间校验。真实平台读取与本机
服务补收进度另外核验，不将替身测试冒充原生推送验收。

真实 HTTP 补收验证：服务更新后，用户在应用未加入的群给两条消息添加新 Pin，
均由持久轮巡自动接入，订阅匹配并由准确原会话返回 accepted；没有手工补投、
重放或修改接收者规则。其中一条从原生 action_time 到入库约264秒，延迟发生在
轮巡表情列表阶段，事件入库后正常派发，不是模型任务排队；accepted不代表任务完成。
此证据只确认 HTTP 补收链路，不作为即时触发或 WebSocket 覆盖证明。

调度优化定向验收：6项集成、854条断言通过；32项保护性检查通过。真实SQLite/Core
接入80条缓存消息，验证新消息优先检查、后加表情近期发现、普通HTTP请求挂起时
表情仍派发、旧消息后加图钉仍由archive发现、旧身份记录不阻塞扫描、分页/重启/跨通道去重及黑名单保持。
共享预算检查覆盖同应用多连接、不同应用隔离、并发/速率/突发、有序等待与取消、
官方429等待头传播、配置边界；原生HTTP/WS在这些测试中使用明确替身，不作为
真实平台延迟保证。本机服务接线与运行进度另行核对。

本机常驻服务已更新，公开connection.probe读回两条连接的new/recent/archive均为ready，
持久断点持续推进且无原生错误；订阅、持久规则、全局过滤配置摘要保持一致。此项
确认新调度已部署并运行，不将其冒充升级后新图钉的真实端到端延迟测量。

自适应观察定向验收：6项集成组合通过；33项保护性检查、314条断言通过。
80条保留消息的真实SQLite/Core夹具覆盖旧消息首次发现、活动后撤下重加、
新消息优先、普通HTTP挂起隔离、跨线/通道去重和空闲new断点不产生额外写入。
保护覆盖512条缓存上限、两秒复用、在途互斥、兴趣窗口到期、时钟回退和活动集上限；
原有应用共享预算与官方429退避检查继续通过。HTTP/WS仍为明确替身，不据此
承诺真实平台检测时限或零限流；不进行手工补投或重放。

本机常驻服务采用本批实现，两条连接四条扫描线均为ready，无原生错误，观察缓存
复用与未变页面计数已由connection.probe读回。配置、订阅、持久规则和全局过滤
摘要不变；各工具Skill入口已同步。未以升级后的新动作测量真实端到端时延。
