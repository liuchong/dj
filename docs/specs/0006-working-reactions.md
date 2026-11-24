# 0006 — 处理中的表情与可靠撤销

DJ将Lark `Typing`（敲键盘）作为已交给接收会话处理的标记，不代表任务已完成或必须回复。只有IM来源投递获得原生accepted、有固定回复上下文、出口支持reaction时登记标记；direct输入不加，接收方仍自行决定是否处理及何时回复。

## 状态与接口

- 每条delivery持久保存独立处理租约，同一出口身份、版本和原消息共享一个原生reaction，多个接收方均结束才撤销。
- `delivery.working(delivery_id)`查询处理状态及cleanup_state；`delivery.complete(delivery_id,reason,idempotency_key)`显式报告completed/no_reply/failed/cancelled，必须保留仅原接收主体（`actor.principal_id === delivery.recipient_principal_id`）或获准operator的主体相等门禁（加`delivery.inspect`权限），不放宽门禁，不为该需求给共享MCP新造每对话独立认证或独立进程，也不信任通知原文、自报`thread_id`、`reply_context_id`或通用`delivery.inspect: ["*"]`读权限作为调用身份。
- 区分正常同身份入口与身份/权限不匹配：当调用方已直接认证为该投递的接收主体且`delivery.working`返回`ok=true`时，可经同身份MCP或CLI直接完成；当全局/共享MCP（如`local-ai`）等调用方返回`forbidden`（`effect_state=none`）时，**仅表明当前认证主体未被授权操作该`delivery_id`**（主体、投递ID或授权本身均可引起不匹配，不得仅据此反推原对话必定绑定了独立受限主体）。即使`delivery.get`可通过共享读权限读出投递详情，`delivery.working`与`delivery.complete`仍会严格按主体相等门禁拒绝越权调用。
- 显式`delivery.complete(...,reason="no_reply")`只结束本条`Working`并撤销`Typing`，**不添加`Get`**、不发送IM文字；无需IM文字回复且按规则决定显式点`Get`时，`message.acknowledge`在同一事务以`no_reply`自动收尾，不必再调`delivery.complete`。
- 原消息回复通过DJ获得原生accepted时自动结束对应处理租约，不必再补调`delivery.complete`或补点`Get`。已绑定的原生ended/settled/turn_finished等结束观察亦可结束；不会将这些观察作为自动IM回复指令。
- 30分钟处理租约到期触发回收（`reason="lease_expired"`），避免客户端退出、异常、模型未调用complete等情况永久遗留`Typing`。它是防止挂标的兜底清理，**不等同于AI业务完成或显式收尾**；到期后仍可补调`delivery.complete`显式记录`completed`/`no_reply`/`failed`/`cancelled`。服务停止持久登记撤销意图，重启继续清理，不依赖对话上下文。长时间业务可继续推进，但过期后不再显示working。

## 可信身份、专用 Profile 与调用方收尾边界

- **安装方配置与专用 Profile 交付**：需为受限接收会话单独隔离主体时，管理员在`service.json`的`principals`配置`kind="agent"`、`target_constraint`（精确固定`tool`、`native_namespace`、`native_session_id`）以及最小授权集合：`delivery.inspect: ["self"]`、`operation.inspect: ["self"]`和仅绑定同一`{tool, native_namespace, native_session_id}`的`session.rules.read`/`session.rules.manage`（无需依赖`agent.get`/`agent.bind`历史单ID grant）。在`0700`私有目录下建立独立的`0600`token文件与`0600`专用client profile JSON（指向服务私有UDS），并将绑定该原对话的这一行专用profile路径记入该对话的私有持久`session.rules`并读回确认：**可由原对话使用自身专用profile保存，或由经用户明确授权（如安装/重装任务）且具备该准确目标`session.rules.manage`权限的安装调用方以自身真实主体仅追加保存该profile接线说明并读回（严格保留对方原有正文与`reply_routes`，仅写路径不写token，不代改其他业务规则）**；私密路径、真实会话绑定与token绝不提交公开Git仓库。两类权限严格分离：安装期写规则的`session.rules.manage`权限不赋予运行时完结投递资格，**运行时`delivery.complete`仍只能由原接收主体（或服务规定的获准`operator`）执行**。
- **OS 文件权限与实际隔离边界**：同OS UID下把专用profile和token设为`0600`（置于`0700`目录）可防止其他OS用户读取、并将专用凭据从默认共享`client.json`分离，**但不对同OS UID下的其他进程构成操作系统级权限隔离**；跨会话授权边界由DJ服务端的凭据认证、`target_constraint`与`delivery.working`/`delivery.complete`主体相等门禁保证。
- **AI 可执行身份核验与收尾序列**：
  1. 入口判定：**若本对话的私有`session.rules`（或通知`conversation_rules`）已记录了专用CLI `--client-profile`路径，应主动直接使用该专用CLI入口执行核验与收尾，不必先用共享MCP撞一次`forbidden`**。若尚未配置已知专用profile，则使用当前入口的`agent.whoami`与`delivery.working(delivery_id)`；一致且成功即可直接完成，若返回`forbidden`（`effect_state=none`）且无已知专用profile配置，立刻停止并准确报告未获准原因（不凭`forbidden`猜测存在其他受限profile、不遍历目录猜测文件、不借用`operator`）。
  2. 以专用profile向DJ Core执行三点交叉核对：
     - `agent.whoami`：核对`kind="agent"`、`principal_id`、`binding_state="bound"`与非空`bound_agent_ids`（有`reply_authority.recipient_principal_id`时须匹配）。
     - `session.rules.get`（传准确`session_key`）：经服务端授权读回`session_key`、`tool`、`native_namespace`、`native_session_id`及私有持久规则记录的专用profile路径行，确认与当前原生对话一致。
     - `delivery.working`（传准确`delivery_id`；若当前身份可见也可结合`delivery.get`核对`agent_id`与`session_key`）：由服务直接确认该主体确为本投递受理接收方。
  3. 执行完成与读回：凭准确`delivery_id`、明确`reason`与本次逻辑动作的稳定`idempotency_key`调用`delivery.complete`；完成后调用`delivery.working`读回，**同时核对`state`、实际`reason`与`cleanup_state`**：
     - 仅当原消息确实跟踪过工作表情（`state != "not_marked"`）且`cleanup_state="done"`时，才能确认该投递关联的`Typing`已撤销；
     - `state="not_marked"`时的`cleanup_state="done"`仅表示本投递本无待清理的工作表情，**不能宣称确实删除过`Typing`**；
     - 同一原消息存在多个接收方共享同一个`Typing`标记时，本接收方完成后`state="completed"`（`reason`为对应明确值）即可成立，而在其余接收方完成或租约到期前，`cleanup_state`可暂时保持未到`done`。
     遇传输超时或`unknown`时保留原键查`operation.get(operation="delivery.complete", idempotency_key=...)`。
  4. 失败准确停止：若`agent.whoami`、`session.rules.get`、`delivery.working`、`delivery.complete`返回`forbidden`/`unauthenticated`，或出现`idempotency_conflict`（同键改参数），必须立刻停止并如实报告；严禁借用`operator`、换新键掩盖冲突，或为清除`Typing`强发多余IM消息或补点`Get`。

## 外部副作用与清理保证

首次创建前持久登记意图并查询当前身份的原生Typing；已存在的人工表情不归DJ接管或删除。POST之前持久登记attempted_create；POST结果丢失后按相同身份和原消息查询找回，不盲目重复添加。分页有界，游标持久保存并续扫。

需要撤销时先持久保存removing，再按精确reaction_id执行官方DELETE；下次查询确认该ID不存在才记done。DELETE失败、网络中断、进程崩溃均保留清理记录并重试，记录不因租约、回复引用或AI上下文过期而消失。身份版本变化时不借新身份删除其他人的表情，保留具体待处理故障。外部API、凭据持续不可用时不能承诺即时删除，必须如实显示cleanup pending，恢复后继续直到确认撤销。

只调用官方HTTPS的message-reaction create/list/delete；不使用SDK、外部IM CLI或桌面。Typed路径与原消息引用不能被AI覆写，权限和原生身份沿0005固定路径核对。没有必要IM内容回复时仅撤销，不强行发“已处理”。

## 有界历史恢复

`subscription.replay(subscription_id,event_ids,expected_revision,idempotency_key)`仅显式恢复最多16条已入库且匹配已完成的原事件。使用当前active版本的准确来源、谓词、内容权限、目标授权、黑名单、回声栅栏、TTL及容量，并复用原event和原生message ID；不改历史消息、start水位、已完成路由checkpoint或原始决策。唯一约束阻止同event/route重复输入。默认订阅更新仍只从now生效，不静默回补历史。它用于修复明确遗漏，不替代长连接实时收件。

## 显式漏收补处理

普通历史查询不启动Typing或任务。用户明确要求补处理漏收消息时，操作员可用message.recover给出同一连接下1..16个准确原生message_id、原因及固定幂等键，由DJ核验官方消息、当前身份和授权，再按原消息键去重进入原订阅/黑名单/投递路径。这里只登记explicit_native_recovery证据，不冒充WebSocket实时事件，不移动收件游标，不自动扩大订阅或重建已有任务。

恢复消息按当前原订阅通知原对话；原case和owner继续复用。正式投递accepted后复用同一Typing租约，回复、delivery.complete、失败/无需回复或租约到期均走既有撤销机制。此接口仅操作员可调用，不是每次主动查询的隐式动作。

## 收到确认与无需文字回复

Get表示内容已理解或已收录、暂时无需文字回复，不是普通收件回执，也不是Working之后的必经步骤。AI按原接收对话的持久规则明确选择message.acknowledge(reply_context_id,idempotency_key)，不因普通输出自动发送，不对所有关键词或私聊事件一律确认。DJ沿0005固定的原消息与user/bot身份执行，AI不选择chat、message_id或身份。此操作复用message.reply授权与受控回复引用，不适用于资源事件。

| AI对当前消息的决定 | 表情行为 |
| --- | --- |
| 正在处理本条要求或问题 | 只保留Working，不额外点Get |
| 已理解、知道了，暂时无需文字回复 | Get，并结束本条消息的Working |
| 补充已收录进正在处理的任务 | 补充消息Get；原任务的Working继续保留 |
| 完成并回复 | 撤销Working，不必再补Get |

确认意图与当前delivery处理租约在同一事务持久提交，结束原因为no_reply，不依赖AI再调一次delivery.complete。若确认发生于submitting、原生接收回执尚未落盘时，先登记并结束本条处理租约，后到的accepted不能重新点起Working；已登记租约先于回复引用与身份检查返回，不重新读取失效引用或创建表情。只结束回复引用所绑定的delivery，不按群、thread、会话或AI猜测的任务批量结束；补充消息不会结束原任务，其他接收方的处理租约仍独立存在。这里的结束仅表示本条输入已处理，不代表整个业务任务完成，也不禁止后续明确回复。

Get是持久内容确认，Typing是临时处理中。原生Get创建与Typing撤销仍异步执行，故可短暂共存；同一原消息存在其他接收方未完成的租约时，Working依原有共享规则保留。两者共用现有持久表情队列，按emoji区分；Get在官方GET核对存在后才native_acknowledged=true，可通过message.acknowledge.get查询。已存在的本人同类Get直接确认，不删除人工表情；网络未知或丢失POST响应时只重查，不盲目重发POST。执行前复核当前主体授权、账号栅栏、源读取有效期；失效则终止待发送确认并保留明确状态，不借新账号发送。Get发送失败不将已确认处理完的当前输入重新标记为处理中，保留真实确认/清理错误并重试。

## 当前策略验收

- 历史确认策略基线：定向集成 6 项通过，验证确认意图与 Working 结束原子提交、失败回滚、补充不结束原任务、多接收方共享标记、submitting 期确认不被后到 accepted 复活、丢失原生响应及重启后清理；保护检查 36 项、331 条断言通过。
- 本轮受限接收者 CLI 收尾与规范回归（隔离 SQLite / UDS API / `0600` 私有 profile / `runCli` / 受控模拟 Lark 表情端口，共 4 个测试文件 53 项通过、0 失败、556 条断言）：
  - `working.test.mjs` 集成 9 项（含新增 `T40.restricted-recipient-cli-complete.integration`：验证授权安装方保存专用 profile 路径并保留原文与 `reply_routes`、共享主体虽可 `delivery.get` 仍被 `delivery.working`/`delivery.complete` 返回 `forbidden`、`no_reply` 三点核对与 `agent.get` 无关完成、同键幂等/冲突、`operation.get`、`not_marked`、多接收方共享标记与同身份完成）；
  - `resources.test.mjs` 集成 7 项、`working.test.mjs` 单元 4 项（含新增 `T38.working-lease-vs-complete.unit`：验证 `lease_expired` 后显式完成可覆盖为 `no_reply` 且不被二次覆写、更新后的 `config/service.example.json` 通过 `validateStructure`）、`contract.test.mjs` 单元 33 项。
- 边界声明：以上全部为隔离夹具、真实 UDS 与受控替换端口的本地证据，**不冒充真实 Lark 平台收发、线上表情删除时延或常驻服务真机采用**；线上原生 `Get` 与 `Typing` 清理仍分别以官方读回及 `delivery.working` 的 `state`、`reason` 与 `cleanup_state` 确认为准。
