# 可靠投递与持久存储

## 保证与原子边界

DJ 以事件、规则、状态与原生证据确定性工作，不调用模型判断是否投递。只保证自身已入库事件在保留期内可追踪。源平台保留/重放、外部 Agent 幂等和可查询能力各自限制保证；不能承诺任意目标的模型输入或业务效果恰好一次。

| 逻辑表 | 主键/唯一约束 | 原子边界 |
| --- | --- | --- |
| connections / agents / bindings | 各 ID；目标 canonical key 唯一 | 目标、主体绑定与 revision |
| tools / profiles / instances / sessions | tool/profile/instance/session key；原生 namespace+session 唯一 | 能力、归属、epoch、目录版本与允许范围 |
| catalog_runs / session_messages / text_index / query_snapshots | run ID、原生消息/修订、索引文档 ID、snapshot ID | 授权范围、扫描 checkpoint、catalog_seq 版本、正文和索引一起推进；分页不持有长读事务 |
| routes / lifecycle_actions | canonical key 唯一；lifecycle ID、launch token | 统一调度身份；启动/创建意图和核对事实 |
| conversation_handles / previews | 句柄 ID；主体和类型约束 | 精确地址/规范化 spec 快照与过期 |
| operations / idempotency | operation_id；principal+operation+key | 受理台账、业务对象与幂等结果同事务 |
| events / ingress_cursor | event_id；connection+source_key | 事件、ingress_seq、源游标 |
| subscription_versions | subscription_id+revision | 起止序号与编译规则索引 |
| routing_work / match_decisions | event+订阅版本；处理游标 | 决定、贡献、Delivery 与匹配进度 |
| deliveries / contributions | 订阅类 route_id+event_id 唯一；直发由受理台账唯一；贡献版本唯一 | IM 多贡献或 direct 授权快照、过期和同一队列 |
| attempts / receipts / claims | attempt/receipt ID；原生回执去重 | submitting 意图、观察追加与租约 |
| reply_contexts / outbound / parts | 各 ID；每 Outbound 有序 part_id | 固定目的地、出站意图与子消息结算 |
| service_lease / echo_index | 服务 owner；connection+native_message_id | 唯一自身调度者与可证回声归属 |

SQLite（bun:sqlite、WAL/FULL）为单机存储，schema与事务已有实现，当前验证状态见 [status](status.md)；版本/同步读回与单进程边界见 [技术选型](technical-stack.md)。源 ACK 可控时，事件/游标持久后才确认；协议决定提前 ACK 时声明 ack_control=false，DJ 保证从自身入库开始。无可靠重放时崩溃窗口可能丢源消息，报告 gap（范围可能未知），不以服务重启成功掩盖。

免订阅 session.send 的原子边界为 Operation/幂等键、内部 TargetRoute 和 origin=direct 的 Delivery；不需要 Event、Subscription 或 AgentTarget。所有发往同一 canonical key 的输入共用 Binding、claim 和 unknown 屏障；origin 的权限/取消规则不能互相借用。启动/创建使用独立 LifecycleAction 和原生关联键，不能把网络超时视作“未创建”重新执行，详见 Agent 控制面。

异步匹配有持久 routing_work，每个分批游标的推进与决定/贡献/队列一起提交，不能先保存 checkpoint 再排队。预算耗尽续算，不认定剩余候选不匹配。控制面的 Preview 和 Operation 不触发事件路由。

外部网络调用在事务之外：先原子校验目标/权限/贡献并把状态改为 submitting，保存 attempt/dispatch_key；然后写出；最后追加回执。**状态进入 submitting 的事务是提交点**。pause/delete 与该事务按数据库串行顺序决定先后，不能保证提交点之后仍可撤回。

## 状态与证据

| 状态 | 意义 | 可推进方向 |
| --- | --- | --- |
| ready | 已入库且有有效订阅贡献或 direct 发送授权 | submitting 或撤销/到期 |
| deferred | busy/offline/退避中 | 条件满足 ready；或过期/撤销 |
| blocked | 能力、容量、权限或版本需要改变 | 条件消除后重评 |
| submitting | 意图落盘，外部副作用可能发生 | accepted、明确 failed、unknown |
| accepted | 原生确认接受 | 追加观察；不再提交相同输入 |
| unknown | 可能已送，证据不足 | reconcile；不能按 TTL 自动当作未发送 |
| failed | 明确失败，保留阶段、部分结果与 retryable | 仅未送达单位安全重试 |
| expired / cancelled | 未提交订阅贡献全部到期/撤销，或 direct 请求到期/被取消 | 保留元数据，不自动恢复 |
| resolved | 操作员明确不重发的人工结案 | manual 证据；不冒充 accepted |

started/turn_finished/agent_settled/held/rejected 是独立 Receipt，不凭标题、正文或模型推测。agent_report 不升级为 native_protocol。Operation.done 只代表 API 受理结果已结算；不是 Delivery accepted，更不是 Agent 完成任务。

accepted 仍可对应原生 busy/held/waiting_permission，默认 queue 要等可靠 idle。一个目标 unknown 形成顺序屏障，其他目标继续；操作员 resolve 后也不能越过原生 busy/未知状态直接发下一条。

## 多贡献的确定性合并

同 route_id+event_id 一项订阅 Delivery；agent_id 为已登记别名，不能因后续登记或注销改变去重身份。每 Contribution 保留订阅版本、策略、授权引用和自身 expires_at，不能只保存一个 matched 列表。

本节只适用于 subscription_event。direct 使用自己的 TTL、发送授权和取消状态，不参与订阅贡献合并；pause/delete 不取消独立直发。直接输入的授权撤销仍阻止尚未提交项，提交点后保留可能已送达事实。

- 只考虑当前仍有效、未过期且来源/目标都获授权的贡献；暂停/更新/删除撤销旧贡献，resume 不复活。
- busy 只要有一条 queue 就采用 queue；全部明确 steer 且原生能力满足才 steer。缺能力不自动换策略，返回 blocked/unsupported。
- context 只要有一条 current 就 current；否则 recent，max_events/max_bytes 取各贡献与目标主体预算的最小值。始终使用 recipient 的可见范围，不取多 owner 权限并集。
- 下一次到期检查取有效贡献 expires_at 的最小值。某条过期只移除该贡献并重新计算，不使仍有长 TTL 的贡献提前失效；全部到期才 expired。
- 原文正文与同来源上下文在提交点投影并冻结信封；已经 submitting 不再重写输入。一个贡献要求更少上下文不会导致另外一条被授权内容偷偷扩大预算。

不同事件默认不合并为一个模型输入。delivery_seq 在首次入队事务分配；同批 IM 事件按 ingress_seq 排序，直发与订阅按已经入队的序号共同调度，不承诺尚未完成匹配的旧事件优先于新直发，也不声称源时间的全局顺序。同一原生目标的不同客户端视图统一到 canonical_target_key/TargetRoute。

## 租约、并发与重启

每目标 claim 带 epoch，服务只协调自身 worker；其他客户端可同时操作原生工具，不提供全工具独占保证。expectedTurnId 等原生前置条件变化则停止本次尝试并重新观察。

实例 gate、epoch、Delivery/create 的 submitting 与 stop 受理按同一事务顺序校验。stop 先关闭 gate 后仅 drain 已提交动作/原生工作，未提交队列 hold；没有空队列要求。注册/注销不会另建 canonical route、删除 claim/unknown 或改变旧直发所有者。完整状态与返回规则见 [Agent 控制面](agent-control-plane.md)。

旧 worker/租约失效不证明没写出。所有未结算 submitting 恢复为 unknown，先 lookup；ready/deferred/blocked 恢复其持久条件；accepted/resolved 不重新提交。只有明确未送达或厂商稳定 dispatch_key 的原生去重合同可以允许安全重试，不能根据最后日志或模型答案判断。

## 幂等、台账与人工解除

幂等作用域 principal_id+operation，canonical request_hash 覆盖业务参数而不含 request_id；同键不同请求拒绝。受理台账与对象原子写入。operation.get 可按原键找回 resource_refs；未查到记录仍可能有正在提交的原请求，再调用必须复用原键和原输入。

完整响应至少保留 7 天且不早于未结算对象；主体有效期间保留键/请求摘要与 operation_id 墓碑。响应过期只返回原对象引用，不再次执行；容量不足停止新变更并诊断，不删去重事实。主体 ID 不复用，关闭后凭据失效。

自动重试只用于可证 definite_not_sent 的尝试，最多 5 次、退避 1/2/4/8/16 秒加抖动，服从 Retry-After/TTL/授权。retryable 字段不能单独授予重发。unknown 仅 reconcile；人工只可由 operator 使用 resolve 的不重发选项，保存 reason/resolution/manual 并永久阻止同投递再送，不伪造原生观察。

## 出站分片与回复期限

下列分片为完整能力合同；首期只允许平台限制内的单条纯文本，多片请求受理前拒绝，不能将此设计当作已发布功能。

message.send/reply 原子保存 Outbound、固定目的地和计划子消息。按 Unicode 边界与平台明确限制做确定性拆分；若厂商限制/幂等能力不足以安全支持，则在受理前返回 unsupported/limit_exceeded，不调用模型改写或摘要。

parts 顺序提交，已经接受的 part 不重发；某 part unknown 时停止后续 part。全部接受才 Outbound.accepted；存在 unknown 则整体 unknown；部分接受且后续明确失败则 failed 且 partial=true，retry 只处理可证未送达后缀，不重发整批。cancel 只能处理提交点前的单位，返回各部分事实，不能把部分接受擦成全部 cancelled。人工 resolve 保留每 part 证据。

ReplyContext 在实际提交输入前生成，目标离线排队不消耗其 24 小时有效期。它仍不能超过源内容保留/可见期；到期返回 reply_context_expired，不默默改用主动发送。首轮不提供自动刷新；有独立发送授权的调用者可显式 resolve 原地址并发起新的 message.send，不能因此扩大权限。

## 来源、删除与回声

源删除事件给相应原消息所有版本增加可见性 tombstone：历史事件 ID/决定保持稳定，正文读取和尚未提交的原文投递立即禁止；删除通知本身可按显式 deleted 订阅投递。提交点之后输入无法撤回，保留该边界。

自身回声根据出站原生 message ID 索引识别，不看文本相似度或文风。默认禁止自身出站再次触发。首轮不承诺跨 IM 传播可验证 hop_count：外部平台若丢失来源链，仅凭再次看到一段文字无法恢复它。显式开放机器人消息时仍抑制已知自身出站，并以每来源/目标速率预算限制风暴；跨 Agent 自动转发链留给后续带可验证 provenance 的设计。

Lark 官方 WebSocket 事件先持久提交到 im_event_inbox，再确认原生接收；Core 持续消费并执行业务去重和订阅路由。历史补取是显式读取或补偿，不充当正常实时入口。完整接线见[IM 适配](adapters/im.md)。

为处理 user 出站先回流、回执后到的竞态，Outbound 进入 submitting 的事务建立按规范化 ConversationAddress 的 EchoGate。入站可持久化，但待判定事件的 routing_work 保持 held，不生成 no_match。消息 ID/echo_index 落盘或确证未发送后释放该出站占用，再按原序号复核；多个在途占用必须全部结算。unknown/manual 但无原生 ID/未发送证据时继续 held，不能因人工关闭台账就自动重入循环。按现有队列容量/告警处理积压，不无限存入内存；不影响其他目的地。只凭 sender=self 无法区分用户自己发言与 DJ 代发，不能用于整类丢弃。

## 容量、保留与调度

设计默认每目标最多 1000 条、全服务最多 10000 条未结算投递；正文最多存 256 KiB（超出保存元数据/原始大小/可用源引用，明确 truncated 与 content_unavailable）；单次正文注入上限 16 KiB。计算分批、公平性、指标与无模型要求见 [组件契约](component-contract.md)。

超限保存事件与 routing blocked 状态并背压，不能静默丢候选；存储无法写入则不 ACK，无法控制 ACK 的接入公开风险。普通正文默认保留 7 天，审计/回执默认 30 天；未结算必要证据不得清理。权限/删除立即影响读取，保留审计不意味着继续允许看正文。

首期存储总量另以 SQLite 活页预算约束：数据库 max_page_count 对应 1 GiB，正常受理预留 64 MiB 给既有对象的核对/取消/排空；正文索引仍独立受 512 MiB 预算约束。达到受理阈值时拒绝新变更/入站且不 ACK，不删除幂等墓碑换容量；物理磁盘不足也以真实存储错误阻断。已释放页可复用，容量状态定期与每次新受理重检。该阈值是服务预算，不是空闲磁盘或性能保证，WAL 和备份另计实际磁盘。

过期完整响应分批移除，保留 operation/key/request_hash/resource_refs，未结算对象的必要响应继续保留；原键仍只能找回原动作，不能重新执行。审计按索引分批清理，不清未结算证据。关闭 SQLite 自动 checkpoint，由服务每分钟在低负载时执行 PASSIVE，繁忙最多延后至五分钟；记录原生 busy/帧数和实际停顿，不能改 NORMAL 或以计划间隔冒充实测性能。

退出时先关闭 intake/提交 gate、保存游标和尝试，再关闭 DJ 自有连接和工作资源；不停止非自身管理的既有工具。活跃/unknown 尚未 drain 时保留 draining，期限到不强杀已有 Agent，也不删除未知动作证据。监督器不应连带终止 Agent 任务；外部强制终止只能报告中断/未知风险。崩溃由上述事务和未知恢复合同处理，正确性不依赖退出钩子。
