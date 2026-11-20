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
| subscriptions / subscription_versions | target_key；target_key + revision | 每个目标的唯一有效订阅和切流记录 |
| routing_work / match_decisions | event_id；event_id + target_key + revision | 匹配决定、命中分支与路由进度 |
| deliveries / inbox_entries / dispatch_notifications | 投递或收件项 ID；事件与会话唯一通知键 | 匹配规则、上下文、投递策略、过期和跨推送及拉取的去重 |
| attempts / receipts / claims | attempt/receipt ID；原生回执去重 | submitting 意图、观察追加与租约 |
| reply_contexts / outbound / parts | 各 ID；每 Outbound 有序 part_id | 固定目的地、出站意图与子消息结算 |
| service_lease / echo_index | 服务 owner；connection+native_message_id | 唯一自身调度者与可证回声归属 |

SQLite（bun:sqlite、WAL/FULL）为单机存储，schema与事务已有实现，当前验证状态见 [status](status.md)；版本/同步读回与单进程边界见 [技术选型](technical-stack.md)。源 ACK 可控时，事件/游标持久后才确认；协议决定提前 ACK 时声明 ack_control=false，DJ 保证从自身入库开始。无可靠重放时崩溃窗口可能丢源消息，报告 gap（范围可能未知），不以服务重启成功掩盖。

免订阅 session.send 的原子边界为 Operation/幂等键、内部 TargetRoute 和 origin=direct 的 Delivery；不需要 Event、Subscription 或 AgentTarget。所有发往同一 canonical key 的输入共用 Binding、claim 和 unknown 屏障；origin 的权限/取消规则不能互相借用。启动/创建使用独立 LifecycleAction 和原生关联键，不能把网络超时视作“未创建”重新执行，详见 Agent 控制面。

异步匹配有持久 routing_work，每个分批游标的推进与决定和队列一起提交，不能先保存 checkpoint 再排队。预算耗尽续算，不认定剩余候选不匹配。控制面的 Preview 和 Operation 不触发事件路由。

外部网络调用在事务之外：先原子校验目标、权限和订阅修订并把状态改为 submitting，保存 attempt/dispatch_key；然后写出；最后追加回执。**状态进入 submitting 的事务是提交点**。pause/delete 与该事务按数据库串行顺序决定先后，不能保证提交点之后仍可撤回。

## 状态与证据

| 状态 | 意义 | 可推进方向 |
| --- | --- | --- |
| ready | 已入库且有有效订阅匹配或 direct 发送授权 | submitting 或撤销/到期 |
| deferred | busy/offline/退避中 | 条件满足 ready；或过期/撤销 |
| blocked | 能力、容量、权限或版本需要改变 | 条件消除后重评 |
| submitting | 意图落盘，外部副作用可能发生 | accepted、明确 failed、unknown |
| accepted | 原生确认接受 | 追加观察；不再提交相同输入 |
| unknown | 可能已送，证据不足 | reconcile；不能按 TTL 自动当作未发送 |
| failed | 明确失败，保留阶段、部分结果与 retryable | 仅未送达单位安全重试 |
| expired / cancelled | 待投订阅到期或撤销，或 direct 请求到期/被取消 | 保留元数据，不自动恢复 |
| resolved | 操作员明确不重发的人工结案 | manual 证据；不冒充 accepted |

started/turn_finished/agent_settled/held/rejected 是独立 Receipt，不凭标题、正文或模型推测。agent_report 不升级为 native_protocol。Operation.done 只代表 API 受理结果已结算；不是 Delivery accepted，更不是 Agent 完成任务。

accepted 仍可对应原生 busy/held/waiting_permission，默认 queue 要等可靠 idle。一个目标 unknown 形成顺序屏障，其他目标继续；操作员 resolve 后也不能越过原生 busy/未知状态直接发下一条。

## 同一事件的通知合并

按规范事件与原生会话分配唯一通知。直订命中后保留该订阅自己的推送或拉取模式。组订阅优先选择合格且尚未通知的成员。每条通知直接保存命中规则、订阅修订、上下文和忙时策略。权限始终按实际接收者核验。详见 [单线订阅](specs/0035-single-line-subscriptions.md)。

提交事务冻结信封并再次核对目标、修订、来源权限和到期时间。暂停、更新或删除会取消尚未提交的旧订阅投递。直发使用独立的授权和到期时间。

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
