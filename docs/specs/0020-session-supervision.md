# 0020 对话督工

## 行为与边界

对话主动登记后，DJ 持久督工，直到对话或获准控制者明确取消。不从最终回复、native accepted 或 Goal 状态猜测任务已经完成。默认每 30 秒检查、连续空闲 120 秒后续接；可配置 check_seconds（10–3600）和 idle_seconds（30–86400）。网络中断、模型暂时不可用或接收进程重启后继续检查；失败指数退避，最长 900 秒，无自动放弃次数。忙时重置空闲计时；等待人工许可只观察，不替人批准。

只续接原 tool / native_namespace / native_session_id 的现有实例会话，使用目录中当前 epoch 并再次核验原生接收端。无接收实例时保持督工并等待恢复，不启动替代 Agent CLI，不新建对话，不靠标题猜目标。原生端一直报告 busy 的卡死无法仅靠状态可靠判断，DJ 不擅自强杀或中断。

Goal 中断后可向原对话发送续接指令，由该对话沿宿主支持的接口恢复原任务。发送成功不代表原生 Goal 已恢复；不直接写 Goal 数据库，不更改预算，不绕过用户主动暂停。任务完成或用户要求暂停时，调用方应先取消督工。普通任务输出不自动发送到 IM。

## 接口与权限

统一 CLI / MCP / GEPO 从操作目录生成：

| 操作 | 输入 | 结果 |
| --- | --- | --- |
| session.supervision.start | session_key / session_ref / agent_id 三选一；prompt；可选 idle_seconds、check_seconds；idempotency_key | 持久 active 登记、准确会话、状态与下次检查时间 |
| session.supervision.get | 同一目标三选一 | 登记；不存在为 inactive / not_registered |
| session.supervision.cancel | 同一目标三选一；idempotency_key | 持久 cancelled；不停止正在执行的任务 |

权限为 session.supervise。可信主体配置已精确绑定 tool / native_namespace / native_session_id 时，可督工自身目标，无需增加发送到其他对话的权限。其他控制者需要显式该权限或 operator 授权。登记归属一名主体，其他普通主体不能读取、替换或取消其登记。每次检查和原生提交前重新核对当前授权；授权改变不静默扩大权限，原登记保留并显示 forbidden，需原主体重新登记。操作幂等、审计和资源投影沿用统一台账。

同会话重新 start 是明确替换：生成新栅栏，取消旧登记尚未提交的督工输入；cancel 即使未登记也持久记为取消。最多 1000 条 active 登记；不是额外 AI 业务任务队列。

## 调度与可靠性

- src/sessions/supervision.eli：操作、权限、持久状态、空闲检测、退避；每批最多检查 4 条，到期索引保证其他登记不会因离线项独占。
- session_supervisions：session_key 主键，主体、state、next_check_at、revision 与完整 payload 同步存储。Core 重启后从 SQLite 继续，不依赖内存定时器。
- Runtime 仅在 ready、持有 owner 且存储可写时启动一个有界后台检查岗位，沿原 tick 和 drain 生命周期管理。
- 每次督工唤醒用持久 generation + wake_sequence 构造固定幂等键。创建通知前先持久 pending_key；重启后只重查/重放同一台账操作，绝不因回执丢失另发一条。成功后跟踪 delivery_id，ready/deferred/blocked/submitting/unknown 都只等待原投递；unknown 沿既有原生核实，不猜测未发送。
- 其他未完成投递存在时先让原消息恢复；不额外堆积督工输入。督工强制使用 queue 忙时策略，即使全局消息默认为 steer，也不打断正在运行或等待许可的对话。
- cancel 与最终 submitting 切点在同一同步写事务重新检查登记栅栏；尚未提交的通知取消。已经提交到原生进程的输入无法撤回，cancel 只保证不再新建后续督工输入。
- 每条已接受督工通知重新开始空闲宽限；若对话持续空闲，后续唤醒继续退避。观察到 busy 才清除连续失败计数，避免离线/过载恢复时刷屏。

## 施工与验收

基线：无督工表/接口；已有跨进程 probe、session.send、持久投递和 unknown 核实。新增会话督工模块，接入操作目录、Core、Runtime、资源投影；复用 direct outbox，仅增加私有登记来源和提交栅栏。原生协议与 IM 接线不变。

- [x] 完成持久接口、后台调度、防重与取消切点，更新 Skill 和能力说明。
- [x] 集成验收：主动登记、运行中不干预、空闲续接、反复中断、离线恢复、服务重启、unknown 防重、授权隔离和取消竞态。
- [x] 关键保护性单测：退避有界与自督工精确身份约束。
- [x] 安装服务与 Skill 并读回接口；不向真实业务对话自动登记或发送测试消息。

本次集中验收：8 项督工 Core/SQLite 集成、3 项保护性单测，以及 4 项受影响的会话规则回归，共 15 项通过。测试使用独立数据库、可控时钟和原生端口替身，覆盖公开操作至持久投递；没有向真实业务对话发送督工消息，不宣称逐工具真机恢复通过。unknown 场景验证等待核实、不重发及取消后保留原不确定记录；服务重启覆盖 active/cancelled 登记与台账提交后未关联登记的崩溃窗口，不把 unknown 的优雅排空说成已完成。

可复验命令（先按项目构建生成 dist-tests）：

```sh
bun test --timeout 15000 dist-tests/tests/integration/supervision.test.mjs dist-tests/tests/unit/supervision.test.mjs dist-tests/tests/integration/session-rules.test.mjs dist-tests/tests/unit/session-rules.test.mjs
```

本机安装核验：目录包完整性校验后更新常驻服务，service.status 返回 ready，原有 IM 连接仍在线；真实 stdio MCP 初始化和 tools/list 读回 dj_session_supervision_get/start/cancel。现有 Skill 链接与独立副本均核对到本次安装内容；文件安装不等于所有运行中 AI 已重读。已有 MCP 代理需在自然边界重新连接以加载新操作目录；期间可直接使用当前 DJ CLI。没有替任何真实对话登记督工，需调用方主动 start。
