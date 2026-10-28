# 总体架构与模块划分

## 运行结构

Eliscript 业务源码编译为 ESM，由 Bun 执行，Core 通过独立 Rack 包装配 IM、Agent 适配器和业务操作处理器。CLI 是短命客户端，MCP 是连接同一服务的 stdio 薄代理，GEPO 与 JSON API 共用私有 UDS。客户端退出不删除订阅，也不停止 Core。

```mermaid
flowchart LR
  CLI[CLI / MCP] --> API[本地 API / GEPO]
  API --> Core[身份、权限与业务操作]
  IM[官方 IM 长连接] --> Ingest[持久收件]
  Ingest --> Match[过滤与订阅匹配]
  Core --> Match
  Match --> Queue[持久队列与目标调度]
  Queue --> Port[已有 Agent 进程接口]
  Port --> Session[精确原生会话]
  Session --> API
  Core --> Out[固定回复路径与出站]
  Out --> IM
  DB[SQLite] --- Core
  DB --- Ingest
  DB --- Queue
```

Lark 使用官方 WebSocket 与 HTTPS；Agent 使用已有实例的 IPC/socket/loopback API。正式装配不接受非空 managed_profiles，不启动替代 Agent 子进程。具体模块与支持边界见[技术栈](technical-stack.md)和[适配说明](adapters/agent-tools.md)。

## 模块装配

[Rack](../packages/rack/README.md) 是独立的 Eliscript 包，提供上下文、服务依赖、
隔离作用域、插件生命周期、事件和资源回收，不依赖本应用。Core 完成数据库与
所有权准备后提供 application 服务，再等待适配器、连接和处理器激活。
`core.moduleStatus()` 返回不含配置秘密的模块状态，供嵌入宿主诊断。

连接仍由扁平注册表分发，不按账号昵称分叉；插件退出不会替代业务 drain。
Core 先排空原生在途工作，确认端口停止，再卸载注册、释放租约并关闭数据库。
精确接线见 [0014 服务模块装配](specs/0014-module-composition.md)。

## 确定性边界

整个核心、接口、适配器和恢复路径遵守 [组件契约](component-contract.md)。没有模型调用、智能路由、自动摘要或嵌入式 Agent。调用方模型理解自然语言并决定目标，DJ 使用 [类型化引用与预览句柄](model-facing.md)做机械校验。外部 Agent 收件后可以调用其模型，这不成为 DJ 的推理能力。

## 模块契约

下表对应当前 `src/` 下的模块职责；具体导出和调用签名以源码为准。

| 模块 | 拥有状态与主要操作 | 不承担 |
| --- | --- | --- |
| core | 对象、规则 AST、状态转换、错误类型 | 网络或数据库实现 |
| application | execute(principal, operation, request) → Result；业务事务编排 | 厂商帧格式 |
| policy | authorize(principal, action, resource, context) → Decision | 根据标题赋权 |
| registry | register、probe、rebind；稳定目标和临时 binding | 从历史猜活进程 |
| catalog | 工具/实例/会话索引、catalog_seq 逻辑版本、稳定键续扫、精确 probe、刷新/覆盖 | 推断任务归属、扫描任意目录、自动唤醒、持有跨请求长读事务 |
| lifecycle | 可选空 create、持久 gate 与动作核对；启动/停止取决于实际装配能力 | 任意 shell、改模型/权限、借创建自动发 prompt、把 manual 当退出证明 |
| ingestion | normalize(raw, connection)、accept(event)；事件去重和源游标 | 模型判断 |
| subscriptions | preview/commit；固定规范化规则、版本与 cutover_seq | 理解自然语言、修改来源权限 |
| routing | 用来源/事件索引取候选，执行编译谓词 → MatchDecision | 模型推理、全订阅扫描、执行 shell |
| delivery | plan、claim、dispatch、observe、reconcile；IM 订阅与直发共享 TargetRoute 队列 | Agent 任务调度与业务完成 |
| messaging | list/get/search/send/reply；回复引用和发送 outbox | 自动回传完整对话 |
| storage | 原子写入、索引、租约、游标、操作台账、outbox、幂等键 | 网络副作用 |
| adapters.im | receive、normalize、send、lookup；平台能力与源 ACK | 订阅业务判断 |
| adapters.agent | discover、list/read、probe、submit、observe、lookup、start/create；厂商能力分开 | 放大调用者授权 |
| interfaces.cli / interfaces.mcp / local API | 参数转换、结果投影、分页；同一 execute | 另建业务状态、IM 操作界面 |
| service | 启停、重连、调度、健康、优雅退出 | 隐式新建 Agent |
| skill | 教 Agent 使用接口与理解事件 | 常驻收件或权限授予 |

## 内部端口

类型定义参见 [领域模型](domain-model.md)。以下为设计签名；Result 包含 [统一错误](interfaces/operations.md)。

```text
ImPort.receive(connection, cursor, budget) -> EventBatch
ImPort.ack(source_receipt) -> AckResult
ImPort.send(outbound, idempotency_key) -> SendObservation
AgentPort.discover(scope, page) -> Page<Candidate>
AgentPort.probe(target, binding) -> ProbeResult
AgentPort.submit(binding, envelope, mode, delivery_key) -> SubmissionObservation
AgentPort.observe(binding, native_ref, cursor, budget) -> ObservationBatch
AgentPort.lookup(binding, delivery_key, native_ref) -> ReconciliationObservation
AgentCatalogPort.listSessions(scope, cursor, budget) -> SessionBatch
AgentCatalogPort.readMessages(session, cursor, budget) -> MessageBatch
AgentLifecyclePort.start(profile, launch_token) -> InstanceObservation
AgentLifecyclePort.create(instance, workspace, request_key) -> SessionObservation
AgentLifecyclePort.stop(owned_instance, drain_budget) -> StopObservation
Store.transaction(expected_revisions, mutations) -> CommitResult
```

接收可以是 push 回调或持续流；receive 是统一逻辑端口，不要求厂商都支持拉取。ack 仅在平台协议支持时调用。lookup 缺失则返回 unsupported，禁止用猜测替代。

目录/查询与生命周期的字段、预算和未知结果统一见 [Agent 控制面](agent-control-plane.md)。实例已运行、历史可查、可创建、可发送分别声明；只配置目录源不授权启动，搜索结果不自动进入投递队列。

catalog 的读取与 direct 的发送可以独立于 registry/subscriptions；TargetRoute 由规范身份唯一化，登记只是长期主体/订阅接线，不迁移旧输入。lifecycle 和 delivery 在 Store 事务中共用 instance gate/epoch，stop 先提交便禁止后续原生提交；不能各自维护一份“是否可发”。service 停机复用相同 drain 契约，核心、适配器与监督器的边界分别留证据。

## 进程与故障隔离

核心不直接启动任意用户 shell。托管 Agent 的 argv、工作区、权限与模型来自显式绑定配置；IM 消息内容只作为数据参数。插件若进程外运行，使用受控协议、身份凭证、握手、能力和大小限制；首轮不开放任意远程插件执行入口。

每个 IM 连接独立重连；每个目标按确定顺序调度，单个 offline/unknown 目标不阻塞其他目标。后台健康检查和重连由 DJ 执行，不转成 Agent 定时任务。CPU/扇出与公平调度按组件契约执行。所有队列、上下文、日志和请求有预算，具体参数见 [存储与投递](delivery-storage.md)。

## 存储与嵌入

单机持久事务存储采用 bun:sqlite、WAL/FULL 与一个受控写连接；生产依赖由工具链锁定。同步事务与 checkpoint 的阻塞边界必须测量，不能把 async 业务函数当成异步 SQLite。核心只依赖 Store 端口，可嵌入宿主；嵌入模式仍须有唯一调度所有者、持久状态和相同授权契约。多个 CLI/MCP 进程不是多个调度所有者。

## 目标目录职责

当前代码分为 `packages/rack/` 独立装配包、`src/` 业务与宿主、`tests/` 分层验收、
`tools/` 构建打包及 `skills/dj/` 使用接口。当前产品规格在 `docs/specs/`，历史
施工记录在 `docs/archive/`。完整启动接线见 [启动到回复](startup-to-reply.md)。
