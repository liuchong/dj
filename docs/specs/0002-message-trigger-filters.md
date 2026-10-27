# 0002 — 可组合的消息过滤策略与触发黑名单

## 用户要求与本次边界

人员黑名单与字符黑名单统一设计。消息继续接收、记录、去重和按原权限查询；禁止的是命中消息直接触发订阅投递，不是消息可见度。其他消息触发 AI 后，AI 仍能在授权来源的查询/上下文中看到这些消息。

本次实现服务级共享策略，默认空规则。未来可扩展条件、作用域和 effect；本次只支持 `suppress_trigger`，未知行为明确拒绝，不能提前执行隐藏、删除、脱敏等未实现功能。显式 session.send、message.send/reply 与正常历史查询不受此触发黑名单拦截。

## 统一模型

策略为 `{policy_id:"service",schema_version:1,scope:"service",revision,rules,updated_at?}`。每条规则固定为 `{id,enabled,effect,predicate}`：

- `id`：唯一非空标识，最长128字符，用于审计和修改。
- `enabled`：显式布尔值，停用规则仍保留定义。
- `effect`：当前只能为 `suppress_trigger`；条件与行为分离，未来行为通过明确的新版本能力扩展。
- `predicate`：复用统一的有界 typed all/any/not DSL，不另写人员或字符串专属判断引擎。

多条启用规则按 OR 合并，任一命中即禁止触发。单条规则内可任意组合 all/any/not。人员默认按全局 `sender.person_id` 匹配，原生 `sender.id` 保留兼容；只有明确要求单连接例外时才加 `connection_id`。不同应用身份通过下文的统一人员表关联，不按显示名猜人。字符/词组按 `text contains` 字面子串匹配，区分大小写，保留 Unicode、emoji 和空白，不按正则或语义理解。空 contains/prefix 模式拒绝，防止误屏蔽全部消息；空规则列表用于清空策略。

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

人员规则（仅用于全局过滤策略，不作为订阅授权或跨平台发送凭据）使用 `{"field":"sender.person_id","op":"eq","value":"person-example"}`，可与字符规则及 all/any/not 组合。Core 每次匹配及 push/pull 提交复核都用同一份全局人员表，将当前消息的任何已核实别名映射为 DJ 人员 ID；所有连接使用相同实现，不为 user/bot 或机器人名称设置例外。未知身份不冒充已确认人员；冲突证据按 indeterminate 阻止本次触发。

`message.filter.update` 可同时携带 `people` 与 `rules`，同事务、同 revision、同幂等台账更新；省略 people 时保留现有人员表，显式 `[]` 清空。引用不存在人员的规则拒绝。两部分合计不得超过65536 UTF-8字节。旧 sender.id 规则继续兼容，只有刻意限定某连接的特殊规则才应带 connection_id；人员黑名单默认不限定连接。

接入保留官方事件中的应用级 OpenID、可用的租户级 UserID 及真实作用域。旧事件可从原连接的应用身份恢复 OpenID 作用域，不能用显示名补全。人员映射所缺的应用/租户身份须用官方可读数据或操作员明确映射补充；单个应用查到身份，不得报告其他未映射应用也已覆盖。
