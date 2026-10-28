# Lark 收件验证记录：2026-10-28

这是实际账号验证的脱敏记录，**不是 Lark 全平台能力声明，也不是 DJ 修复完成证明**。观察对象是已运行的 DJ 服务，两条接收连接对应不同应用；未启动第二个 WebSocket 消费者抢占事件。“本人连接”是 DJ 的授权／路由身份标签；当前观察的握手仍使用对应应用 key/secret，不能据这个标签宣称已建立独立的用户 token WebSocket 通道。

## 代号

| 对象 | 代号与关系 |
| --- | --- |
| 应用 A、机器人 A | `cli_demo_app_a`；机器人连接 `lark-bot-a` |
| 应用 B、机器人 B | `cli_demo_app_b`；本人 OAuth 连接 `lark-user-b` 使用应用 B 的授权 |
| 本人在两个应用下的 open_id | `ou_demo_self_app_a`、`ou_demo_self_app_b`；同一个人，应用作用域不同 |
| 测试群 | `oc_demo_debug_group`；两个应用机器人都在群内 |
| 工作群 A | `oc_demo_work_group_a`；两个应用机器人均不在群内 |
| 工作群 B | `oc_demo_work_group_b`；记录到其他真人消息进入机器人 A 连接 |
| 通知群 | `oc_demo_notification_group`；应用 A 的机器人在群内，应用 B 的机器人不在群内 |
| 消息 | `om_demo_message_001` 等；同一代号在全部观测中代表同一原生消息 |

代号保留原生 ID 的类型前缀和作用域关系，均为假值。人名、群名、应用显示名、原生 ID、消息正文、凭据、本机绝对路径和完整 WebSocket 票据没有进入此目录。原始资料和代号映射只在本机私有区保留。

## 结果矩阵

“未观察到”只描述所列账号、配置和观察窗口，不等于证明官方不支持。HTTP“读到”与 WebSocket 推送是两种不同证据。

| 发送者 → 接收连接 | WebSocket | HTTP | 对应记录 |
| --- | --- | --- | --- |
| 本人 → 机器人 A，私聊 | 约 1 秒收到 | 读到 | C01 |
| 机器人 A → 本人，私聊 | 125 秒窗口未观察到；后续补测也未观察到 | 读到 | C01、C11 |
| 机器人 B → 本人，私聊 | 补测未观察到 | 读到 | C11 |
| 其他真人 → 本人，私聊 | 未观察到 | 两条新消息均读到，约 12～13 秒 | C10 |
| 其他真人 → 机器人 A，群聊 | 工作群 B 三条记录约 1～2 秒入库；前两条位于当时监听窗口内 | 对应样本已明确读回 | C03 |
| 其他真人 → 本人，群聊 | 工作群 A 的七条消息均未观察到 | 七条均读到，约 12～17 秒 | C09 |
| 本人 → 本人，群消息回声 | 测试群能收到；工作群 A 的五条未观察到 | 五条均读到 | C02、C09 |
| 机器人 → 本人，群普通消息或 @本人 | 当前样本均未观察到 | 通知群自然消息、测试群主动测试均读到 | C06、C11、持续观测 |
| 机器人 B → 群里 @机器人 A | 两次均收到，约 0.99／0.87 秒 | 也读到 | C04、C12 |
| 机器人 A → 群里 @机器人 B | 65 秒窗口未观察到 | 读到 | C05 |
| 机器人 → 机器人，普通群消息、不 @ | 65 秒窗口未观察到 | 读到 | C06 |
| 机器人 → 机器人，私聊 | 未建立成功的发送样本 | 首先因跨应用 open_id 被拒；改用实际接收事件中的作用域正确 ID 后仍被拒 | C07、C08 |
| 其他真人 → 机器人 A，私聊 | 未验证 | 未验证 | C13；不能拿本人或机器人冒充其他真人 |

机器人 B 缺少 `im:message.group_at_msg.include_bot:readonly`，机器人 A 有该权限。反向 @未收到的样本不是权限对称的对照，不能据此得出平台不支持的结论。完整权限核对见 [scope-check.json](scope-check.json)。

## 持续对照快照

此次固定快照截止 **北京时间 20:59:28**，从 **20:23:39** 开始。归档时监控仍运行；后续新增结果不自动改写本快照。

| 连接 | HTTP 与 WebSocket 都看到 | 当时仅 HTTP 看到 | 合计不同消息 |
| --- | --- | --- | --- |
| 本人连接 `lark-user-b` | 0 | 25 | 25 |
| 机器人连接 `lark-bot-a` | 1 | 9 | 10 |

两条连接共有部分相同消息：跨连接合计 **25 条不同消息、36 条“连接 × 通道 × 消息”观测**。不能将 25 + 10 当作 35 条不同消息。

HTTP 对照范围：本人身份分群聊／私聊做全局增量查询；机器人 A 查询其会话列表中的群、一个已知本人私聊，以及 WebSocket 新发现的会话。这没有证明机器人 A 的所有未知私聊都已被 HTTP 扫描。

- [observations.json](observations.json)：逐条代号、来源时间、第一次观察时间、身份类别和接收通道；无正文。
- [snapshot.json](snapshot.json)：固定截点的计数、HTTP 查询窗口数量和限制。
- [cases.json](cases.json)：持续监控前后的主动发送、旁路自然消息、反例与未验证项。

WebSocket 一侧观察的是现有服务的事件入库结果，**没有保存原始 WebSocket 二进制帧**。当时部署的 IM 收件使用 WebSocket，尚未开启服务内 HTTP 补收；对照程序的 HTTP 结果只写独立观测库，不写服务事件表、不补投、不重放、不触发 AI。WebSocket 连接状态 `connected` 本身不证明任何一条消息已收到。

## 其他已执行核对

### 身份与握手

[handshake.json](handshake.json) 保留实际 HTTP 状态、业务码和参数组合：

- 用户 token 通过 `/open-apis/authen/v1/user_info` 核验。
- `/callback/ws/endpoint` 使用应用 key/secret 成功取得票据；没有再打开这些实验票据。
- 仅加用户 token、不提供应用 secret 的两种尝试返回 HTTP 400／`9499`。
- 应用 key/secret 加有效或无效 Bearer 均成功取得票据。因此，**取得票据成功不能证明这个入口按用户 token 提供全部本人消息**；这不排除其他官方入口或配置的可能性。

[application-b-state.json](application-b-state.json) 另行保存应用 B 中同名 `im:message`／`im:message:readonly` 的 user 与 tenant 授权、本人群聊／私聊读取授权，以及已发布的消息事件类型；不把权限存在等同于所有消息必然推送。

### HTTP 时间窗与分页

[http-window-checks.json](http-window-checks.json) 记录已执行的请求反例：

- 本人使用 `POST /open-apis/search/v2/message`，空 `query` 可以读取群聊与私聊消息 ID，随后通过 `GET /open-apis/im/v1/messages/{message_id}` 取详情。
- `page_size` 放 URL 查询参数；时间窗使用请求体 `start_time`、`end_time`。
- 错用 `from_time`、`to_time` 的未来时间窗仍返回历史消息；改为 `start_time`、`end_time` 后未来窗口为空。不能因接口返回成功就认定过滤参数生效。
- 机器人身份使用 `GET /open-apis/im/v1/messages` 按可访问会话和时间窗读取。本人查询覆盖不需要逐群预配置地址；机器人按其获准会话读取。
- 连续监控通过消息 ID 对照到达时间，HTTP 约 10～20 秒后读到的样本不能说成即时 WebSocket 推送。

### 机器人私聊拒绝

跨应用误用 open_id 返回 `99992361 / open_id cross app`。之后使用机器人 A 实际接收事件中机器人 B 的 sender open_id，再尝试 A → B 私聊，返回 `230013 / Bot has NO availability to this user.`。这些是具体账号的发送拒绝，不能改写成“机器人私聊消息已经发送、只是接收不到”。

## 验证程序

[programs/](programs/) 收集实际执行源程序的脱敏副本；[programs.json](programs.json) 记录原源文件摘要、归档副本摘要及修改边界。**这批副本未替换回真实账号重新执行，不冒充新增验收。**

| 程序 | 实际用途 |
| --- | --- |
| `handshake.eli` | 官方用户身份、握手、权限和已发布事件配置探测；不打开额外消费者 |
| `live-roundtrip.eli` | 经 DJ 发送私聊／群测试消息，观察现有服务收件和发送终态 |
| `probe.py` | 后续诊断共用的标准库 HTTP 请求、应用身份和权限查询 |
| `roundtrip.py` | 两个应用的真人／机器人私聊、普通群消息及 @消息对照 |
| `resolve.py` | 从群成员接口核对身份；该接口的结果不能当作群机器人完整列表 |
| `private-resolved.py` | 使用实际收件事件中的作用域正确 ID 再试机器人私聊 |
| `http-inventory.py` | 核对应用身份可列出的会话 |
| `fill-samples.py` | 两个机器人分别向本人私聊及群里 @本人，并发送一条机器人 @机器人阳性对照 |
| `monitor.py` | 现有服务 WebSocket 收件与两个身份的官方 HTTP 持续对照 |

程序只使用 DJ 接口、语言运行时／标准库和官方 HTTPS API；没有 IM SDK 或 Lark CLI 进程。Eliscript 保留编译前源文件，不归档生成的 JavaScript。Python 文件是实际用过的诊断辅助程序，不是产品运行实现。

重新使用前须在本机私有副本中替换代号，准备独立授权凭据、准确的会话与身份，并确认发送范围。发送脚本会产生真实外发，不得直接运行占位常量或把它们接入生产服务。HTTP／监控输出默认保存在用户私有状态目录；`live-roundtrip.eli` 与 `handshake.eli` 需要显式传入私有输出位置。不得把新运行的原始输出提交到此证据目录。

## 结论与后续边界

当前证据足以确认：两条应用事件连接的覆盖与本人 HTTP 可读范围并不相同；本人自发回声也因群而异；机器人明确 @另一个有对应权限的机器人可以实时收到。现有配置下需要补齐未覆盖的本人消息，同时保留可用 WebSocket、原生 ID 去重、订阅过滤和确定回复路由。

本归档只记录证据，不宣称服务内 HTTP 补收已经完成、部署或通过真实任务验收。对未观察到的方向，继续使用“未观察到／未验证”，不能推导成平台能力不存在。

官方接口参考：[接收消息事件](https://open.larksuite.com/document/server-docs/im-v1/message/events/receive)、[会话历史消息](https://open.larksuite.com/document/server-docs/im-v1/message/list)。原始运行结果优先于从其他工具实现推断的能力结论。
