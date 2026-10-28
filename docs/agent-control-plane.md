# Agent 会话查询与控制

DJ 机械列举、读取和通知调用方明确指定的原生会话。查询与 `session.send` 不要求先建立 IM 订阅。实际工具方式见[适配说明](adapters/agent-tools.md)，支持和验证范围见[当前状态](status.md)。

## 对象与身份

| 对象 | 用途 |
| --- | --- |
| 工具类型 | 适配器及其原生能力声明，不代表本机已有接收实例 |
| 运行实例 | `instance_id`、namespace、epoch、工作区和当前状态，区分不同客户端与账号 |
| 原生会话 | 原生 ID 与稳定 `session_key`；标题仅供显示，不能用作投递身份 |
| 短期引用 | 当前主体获准访问的 `session_ref`，到期后重新获取，不改变原生会话 |
| 已登记目标 | `agent_id` 与 recipient 的固定会话绑定，用于长期订阅和回复 |
| 目录刷新 | `catalog_run_id`、checkpoint、覆盖与预算；读取不启动模型 |
| 生命周期动作 | 可选空会话创建等动作的独立授权、幂等记录与结果核对 |

历史记录存在不证明有活接收端；`desktop-open`、live、history 和输入接受分别观察。epoch 改变后须重新核对原会话，不能以同名目标替换。

## 范围与查询

调用方通过 `tool.list`、`instance.list/get` 及 `session.list/get/search` 缩小工具、实例和工作区范围。仅有稳定 `session_key` 时使用 get；仅有准确原生 ID 时使用 `session.resolve`。`session.probe` 只核对状态，不发送测试消息。

`session.message.list/get/search` 读取获准的会话消息。机械搜索使用字面条件，不做语义检索或任务归属判断。正文与标题是外部数据，不是操作授权。完整参数以[操作目录](interfaces/operations.md)和运行时帮助为准。

## 快照、覆盖与刷新

列表和搜索使用有界本地目录。读取结果中的 `as_of`、`stale`、`complete`、`coverage_complete` 和 `next_cursor` 分别表达新鲜度、分页完成及源覆盖，不能把当前页为空当成全源无结果。

需要更新时显式 `catalog.refresh`，再通过 `catalog.get` 观察进度和 continuation。已知会话可用 `scope.session_keys` 定点刷新，正文缺失时显式请求 `include_content`；不要求全盘扫描，也不以历史查询替代 IM 实时事件。

刷新、正文接收和搜索均有记录数、字节与时间预算。源端只有全量响应或覆盖不完整时如实返回 partial；超长帧受限处理，不杀正在使用的 Agent、不把全部历史载入内存。授权撤销和原生删除优先于旧目录结果。

## 免订阅直发

`session.send` 向一个准确会话输入；`message.send` 向 IM 发送，两者不能混用。直发不伪造 IM Event、Subscription 或订阅贡献，也不附加 IM 历史上下文。

发送前重新核对活接收端、当前权限、epoch、gate 与原生能力。直发和订阅共用 canonical route、持久队列、submitting 提交点、unknown 屏障和回执，不能借另一个入口绕过同目标未结算输入。busy 默认 queue，offline 默认 hold；没有安全提交能力时明确拒绝或保持阻塞。

请求超时先查原 operation 与幂等键，再核对 Delivery 和原生记录。原生 accepted 只证明接受输入；没有真实 started、回复或完成证据时不扩大成功含义。回答保留在原生会话，普通输出不自动转发 IM。

## 显式创建与进程边界

核心通知始终面向运行中的客户端或 CLI 进程，通过 socket/API/MCP 等接口输入。正式配置拒绝非空 `managed_profiles`；不为投递新建 Agent CLI/App Server/ACP 进程，不通过 argv 携带消息或会话配置。

`session.create` 是可选增强：只在指定已有实例、获准工作区及原生能力允许时创建空会话；不传 prompt，不启动模型，不登记 Agent、订阅或复制创建者权限。没有原生接口时返回 unsupported。查询和发送不隐式创建、恢复或切换会话。

`instance.start/stop` 与 profile 操作仍有操作记录和协议层设计，但正式配置没有可用的托管启动路径，不能把接口名字或历史夹具当作生产启停能力。未来若加入客户端启动，须将启动与后续跨进程业务通信分开；禁止恢复 argv 投递。

创建后用于订阅时，由可信配置面分配独立 recipient、固定准确 `session_key` 并接入客户端工具与 Skill。接收方再核对 `agent.whoami` 和登记信息。创建成功不证明接收方已获回复权限或 Skill 已采用。

## 三条独立业务流程

1. 查找已有信息：`tool/instance.list` → `session.list/search` → 必要的定点 refresh → `session.message.list/get`。返回事实和覆盖，由调用方判断。
2. 通知已知会话：get/resolve → probe → `session.send` → `operation.get` / `delivery.get`；需要回答时读取原生消息，不自动回复 IM。
3. 可选创建空会话：核对已有实例和工作区 → `session.create` → `lifecycle.get/reconcile` → get/probe；后续输入、登记和订阅分别授权。

更多使用步骤见[从启动到回复](startup-to-reply.md)。旧进程托管方案保留在[历史研究](archive/research.md)，不作为当前接入方法。
