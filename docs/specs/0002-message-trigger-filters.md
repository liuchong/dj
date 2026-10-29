# 0002 — 可组合的消息过滤策略与触发黑名单

## 用户要求与本次边界

人员黑名单与字符黑名单统一设计。消息继续接收、记录、去重和按原权限查询；禁止的是命中消息直接触发订阅投递，不是消息可见度。其他消息触发 AI 后，AI 仍能在授权来源的查询/上下文中看到这些消息。

本次实现服务级共享策略，默认空规则。未来可扩展条件、作用域和 effect；本次只支持 `suppress_trigger`，未知行为明确拒绝，不能提前执行隐藏、删除、脱敏等未实现功能。显式 session.send、message.send/reply 与正常历史查询不受此触发黑名单拦截。

## 统一模型

策略为 `{policy_id:"service",schema_version:1,scope:"service",revision,rules,updated_at?}`。每条规则固定为 `{id,enabled,effect,predicate}`：

- `id`：唯一非空标识，最长128字符，用于审计和修改。
- `enabled`：显式布尔值，停用规则仍保留定义。
- `effect`：当前只能为 `suppress_trigger`；条件与行为分离，未来行为通过现行能力扩展。
- `predicate`：复用统一的有界 typed all/any/not DSL，不另写人员或字符串专属判断引擎。

多条启用规则按 OR 合并，任一命中即禁止触发。单条规则内可任意组合 all/any/not。人员默认按全局 `sender.person_id` 匹配，原生 `sender.id` 可用于准确的连接内身份；只有明确要求单连接例外时才加 `connection_id`。不同应用身份通过下文的统一人员表关联，不按显示名猜人。字符/词组按 `text contains` 字面子串匹配，区分大小写，保留 Unicode、emoji 和空白，不按正则或语义理解。空 contains/prefix 模式拒绝，防止误屏蔽全部消息；空规则列表用于清空策略。

规则最多64条，总定义最多65536 UTF-8字节；每个 predicate 沿用现有深度、叶数与集合值上限。不完整正文或缺失字段导致 indeterminate 时，保守禁止这一次触发并保留诊断，消息仍可见。

## 数据流与动作边界

1. 原接入和 Event 入库完全不变，黑名单不在 WebSocket 或入库前丢消息。
2. 单事件匹配的同步事务读取策略一次。订阅条件仍独立计算；命中黑名单时保留 match_decisions 与 trigger_suppressed 诊断，不创建该消息的 push delivery 或 pull inbox entry。
3. 规则更新前已排队、尚未提交的订阅投递，在 beginSubmission 同步事务按最新策略复核；命中后取消本次通知并释放 claim。提交点后的原生在途/已接受结果保持原义，不撤回已送消息。
4. pull 领取前也复核最新策略，命中的待领取项标记 suppressed；已领取并仍有效的信封不因黑名单更新而被隐藏或撤销可见度。
5. 清空/停用规则不会自动补发已阻止的历史动作；只影响此后的新触发及未提交复核。既有重试仍须通过最新复核。
6. 不缓存跨事件、跨事务的匹配结论。规则与事件正文均不授予额外权限。

## 公共接口与权限

- `message.filter.get {}`：读取当前策略。权限 `message.filter.inspect`，资源 `message-filter:service`。
- `message.filter.update {expected_revision,rules,idempotency_key}`：一次替换完整规则集，权限 `message.filter.manage`，同一资源。初始 revision=1；更新递增。版本冲突、重复ID、非法条件、未知 effect、超限均拒绝且不产生部分写入。
- 变更沿用操作台账、同键重放和当前权限重检。策略持久于 SQLite，重启后保留；CLI/MCP/GEPO 同用 Core。
- 默认仅已有全权操作员能修改服务级策略；普通订阅者不能通过创建订阅绕过共享触发限制，也不能自行授予全局管理权。委托 AI 管理需明确授予上述资源权限。

## 施工与必要验收

业务实现 → 集成功能验收 → 关键保护单测，每段一次完成。仅验证本批，不重跑全工具/性能矩阵。

- [x] 策略持久化、统一接口、权限/版本/幂等与清空。
- [x] 人员、字符、组合规则只屏蔽新自动动作，消息仍可读。
- [x] 排队 push 与待领取 pull 最新策略复核，已提交/已领取可见性不变。
- [x] 定向集成、保护回归、Skill/文档与运行服务更新；签名提交记录见 Git。

本批集中验证：3项隔离 SQLite/Core 集成与1项保护单测通过（52个断言），覆盖权限/幂等/版本、重启、清空、人员与字符组合、正文公开读取、排队取消、已提交/已领取边界、显式直发、输入上限和截断保守判断。未重跑全套、性能或其他 AI 工具验收。

运行服务已更新，service.status=ready、官方 WebSocket=connected；新增 message.filter.get 返回初始 revision=1、rules=[]。未加入任何实际人员或字符，原配置与数据库保留。

## 全局人员身份（补充约束）

黑名单属于 DJ 服务，不属于某条连接或某个机器人。连接 ID 仅表示接入实例，不代表人员身份；机器人显示名不得成为产品逻辑分支。部署可使用不同平台、应用与授权身份，但不得要求使用者按连接重复维护同一个人的黑名单。

策略新增 `people`（最多64人），每项为 `{id,identities}`。`id` 是 DJ 内稳定人员标识；`identities` 是该人的已核实原生身份别名（1..128项），每项为 `{platform,scope,id}`。Lark OpenID 的 scope 为 `app:<app_id>:open_id`，租户内 UserID 为 `tenant:<tenant_key>:user_id`；Lark 与飞书品牌分开。相同别名不能登记给不同人员，不以显示名自动合并，不跨租户猜测，不将 OpenID 当全局人员 ID。

人员规则（用于全局触发过滤与订阅条件，不作为授权或跨平台发送凭据）使用 `{"field":"sender.person_id","op":"eq","value":"person-example"}`，可与字符规则及 all/any/not 组合。Core 每次匹配及 push/pull 提交复核都用同一份全局人员表，将当前消息的任何已核实别名映射为 DJ 人员 ID；所有连接使用相同实现，不为 user/bot 或机器人名称设置例外。未知身份不冒充已确认人员；冲突证据按 indeterminate 阻止本次触发。

`message.filter.update` 可同时携带 `people` 与 `rules`，同事务、同 revision、同幂等台账更新；省略 people 时保留现有人员表，显式 `[]` 清空。引用不存在人员的规则拒绝。两部分合计不得超过65536 UTF-8字节。sender.id 规则用于准确原生 ID，只有刻意限定某连接的特殊规则才应带 connection_id；人员黑名单默认不限定连接。

接入保留官方事件中的应用级 OpenID、可用的租户级 UserID 及真实作用域。旧事件可从原连接的应用身份恢复 OpenID 作用域，不能用显示名补全。人员映射所缺的应用/租户身份须用官方可读数据或操作员明确映射补充；单个应用查到身份，不得报告其他未映射应用也已覆盖。


## 可组合订阅分发（当前规范）

同一消息独立匹配所有有效订阅，不存在“前一条订阅消费后，后一条看不到”的
抢占机制。不同目标各自投递；同一目标沿用单 delivery 合并贡献，保留每条命中
订阅的 ID、提示词和生命周期。暂停一条线不撤销另一条仍有效的贡献。

连接只接入与持久化平台可访问的事件，不再用 allowed_sender_kinds 在候选匹配
前封死作者类型。该旧配置字段从现行配置删除。机器人、Agent、真人和 unknown
仍保留原始 sender.kind，是否触发由以下两层同一个谓词实现决定：

1. 服务级 message.filter 规则：任何启用的 suppress_trigger 命中即禁止自动
   触发；管理员可屏蔽指定机器人 ID，或显式屏蔽全部 bot/agent。
2. 每条订阅自己的 predicate：由订阅者配置 all/any/not，独立表达包含和排除。
   订阅不能绕过服务级禁止；显式包含机器人也不会伪装成人类或绕过自身回声防重。

默认来源仍为获准的全部群、私聊和 thread；默认触发仍为 addressed_self。
不偷偷给已有订阅加“排除所有机器人”，也不替订阅者重写其业务提示词。

新增 predicate 字段为 mentions.any（存在任意原生提及）、
conversation.native_chat_id（准确来源会话）和 native_message_id（准确原生消息）。
原有 addressed_self/addressed_bot、chat_type、sender.id/kind、mentions.id、
thread.id、topic.key、reply_to.id、text 可以任意组合。sender.person_id 现在也可
用于订阅，使用与全局过滤相同的已核实人员表；未知人员引用在预览阶段拒绝，
身份映射矛盾仍为 indeterminate，不按名称猜测。人员谓词不复用跨路由轮次的
旧映射 memo，写事务创建贡献前重新核对。

“没有 thread / 引用 / topic”用空字符串表示已知不存在，使排除某个 thread
在其他会话消息上得到 true；缺失发送者、缺失提及证据、截断正文等仍保留
三值判定，not(indeterminate) 不会变成 true。

预览样例的 result 表示本订阅条件的匹配结果；reason_codes 中的
trigger_suppressed 明示全局策略阻止动作，不能把条件命中误当成将会投递。
屏蔽均不影响持久化、历史、上下文读取或显式回复。共享黑名单对 push、pull
和显式 replay 的自动贡献采用相同路径，移除屏蔽不自动补发历史。

### 本批施工与验收

- [x] 扩展统一字段、人员条件、否定的已知空值语义；复用预览/匹配/重放。
- [x] 移除连接级作者闸门，保留防回声、全局屏蔽及各订阅的独立贡献。
- [x] 同步操作 schema、帮助与 Skill 的可组合示例。
- [x] 集成验证并集/交集/排除、跨线重合、机器人、全局屏蔽但可读。
- [x] 关键保护性回归，更新服务与 Skill。
- [x] 签名提交并推送。

本地集成证据：`T38.composable-subscriptions.integration` 验证两目标、同目标
两贡献、指定机器人选择、全局抑制仍可读及单线暂停；
`T38.person-subscriptions.integration` 验证私聊人员交集、未知人员拒绝和身份
别名更新。原有过滤 push/pull、来源范围、资源与混合收件用例共同验证共享接线。
`T38.composable-subscriptions.unit` 保护字段类型、未知/否定和人员 memo 边界。
这些本地隔离验收不冒充真实平台机器人身份已配置或外部消息实发。
