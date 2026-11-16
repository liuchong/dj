# 0030 原生会话创建与标题控制

DJ 独立提供会话发现、创建、读取、定位及投递。它直接调用已有实例的原生接口，不依赖其他 Agent 控制工具，不替 AI 选择任务或协作对象。调用方来自哪个工具，不限制目标工具；不建立工具两两配对的实现。

以本机安装版与官方最新版为接口依据；旧安装可更新，不保留旧版兼容路径。Cursor 原生作用域按构造器能力形状定位，不绑定某个安装版或压缩变量名；进程身份和协议核验继续保留。

## 请求与权限

`session.create` 需要 `instance_id`、`expected_instance_epoch`、`workspace_ref`、独立 `idempotency_key`，可提供 `title`、绝对 `directory`、目标支持的 `model_selection` 及首条 `content`。创建与输入分别记账，不自动登记 Agent、订阅、复制权限或选择模型。

`session.create`、`instance.inspect`、`lifecycle.inspect`、`lifecycle.reconcile` 分别授权。正式创建 profile 应具备所需查询与恢复动作；create 不隐含管理权限。`existing` 实例可以创建，`managed_profiles` 继续必须为空。

实例查询公开 `workspace_scope`、`workspace_ref`、`directory`、`workspace_refs`：

- `directory`：仅允许配置目录。发现其他目录不扩大创建范围。
- `instance`：OpenCode、Codex、Antigravity 可使用同实例其他绝对目录及其确定性 `<tool>-workspace-<hashValue(directory)>` 引用。配置基准目录保留原 `workspace_ref`。调用方可显式提供目录，未提供时只从同实例、同 epoch、同 workspace_ref 的已发现会话解析唯一目录。
- 不从标题或其他工具的目录推断路径。相对路径、不规范路径、引用与目录不一致均拒绝；无权的请求不查询其他会话来扩大可见性。

受理事务及原生请求前重检权限、scope 与实例 gate；结果核对实际工作区和原生身份。工作区错误公开 `creation_workspace_unresolved` 或 `creation_workspace_out_of_scope`，不混称缺受管档案。

## 各目标的真实范围

| 目标 | DJ 原生创建路径 | 边界 |
| --- | --- | --- |
| OpenCode | 已有 `/api/session` 或 Desktop `/control` | 原生模型目录核对；Desktop 需原生登记读回；同实例支持跨目录 |
| Cursor | native_api 的 LocalAgentRepository.createAgent，skipInitialSubmit | 既有原生 Inspector 通道，require-trusted，不修改信任、不提交 prompt；普通 Bridge 不支持创建 |
| Antigravity | 已有 language_server 的 StartCascade、UpdateConversationAnnotations | 同 UID、进程出生身份、证书指纹、CSRF 及 epoch 校验不变；确定性原生 ID、原工作区读回 |
| Kimi / DSH | 已有 Desktop / Web 的独立原生协议 | 保留配置工作区与原生形态约束，不宣称离线端点实测通过 |
| Codex | 已有签名原生 Node 工具宿主内的 DJ 接收端 | 官方 App Tools 原生管道，create_thread / set_thread_title；仍由平台鉴权，不启动 App Server、不伪装 peer |
| Claude Desktop | 已有 LocalSessions.start / updateSession | 原生 IPC 创建、改名及收发；现有 Claude Code inbox 仍只支持已有会话 |
| Pi | 已有 Pi Extension 宿主的 createAgentSession / setSessionName | 同进程独立会话，保留原交互会话；历史持久化遵循 Pi 首条 assistant 后写盘 |

不支持的创建在持久动作受理前返回 `unsupported`，带原因 `native_session_create_unavailable`。不支持的模型覆盖同样在受理前拒绝，原因 `creation_model_selection_unsupported`，不悄悄使用其他模型。Antigravity 模型使用明确的原生 enum，不按展示名称猜测；显式初始模型只用于首次输入，不冒充之后的实时模型选择。

## 不确定结果与验收

持久 lifecycle 绑定精确目标与创建键。原生调用前失败为明确未创建；请求可能已写出后失败为 unknown，保留原生 ID。Antigravity、Cursor 的创建键派生确定性原生 ID，恢复只查原 ID，不因查不到再创建；OpenCode 原生结果缺 ID 时保持 unknown，不按标题猜测。

`lifecycle.get` 返回创建工作区、原生引用及可见会话引用；恢复仍受原身份和当前权限约束。ready 是原生创建受理及目标核对的证据，不等于模型运行、桌面当前 Tab 或业务任务完成。随后单独 `session.send`，沿投递台账观察。

验收聚焦创建与工作区组合：已有实例跨目录、目录范围拒绝、缺查询权限、准确 epoch、空对话无 prompt、模型显式覆盖、原 ID 不重复创建及不确定恢复。复用既有收件/订阅证据，不重跑 IM、性能或全工具矩阵。

此前空创建阶段验收：4 项创建集成、1 项既有桌面系统接线回归、2 项关键边界单测通过（合计 7 项）。已有 OpenCode Desktop、Antigravity Desktop、Cursor Desktop 均经本机原生接口创建空对话读回；Cursor 再次使用同一创建键读回同一 ID，Inspector 已关闭。该证据不包含模型执行、IM 外发或 Codex 空对话创建。


## 首条消息与标题控制

- 创建请求可带 `content={type:"text",text:...}` 与 `delivery_policy`，另需 `session.send` 权限。未带 content 保持空创建；不把空对话作为平台准入条件。
- 创建 ready 后以稳定的 `creation-input:<lifecycle_id>` 操作键向准确的新 `session_key` 受理首条消息；不靠原始短期 handle 续期重发。创建与输入两个结果分别投影：`initial_input_state`、`initial_delivery_id`、`initial_input_error`，送达仍看 delivery.get。
- 崩溃发生在首条消息持久受理与关联字段更新之间时，原键查回同一投递；创建 unknown 时不发送首条消息。权限撤销、实例变化或目标失效不能绕过，首条输入被拒绝需明确投影。
- `session.rename(session_ref,title,idempotency_key)` 复用生命周期动作与 submitting 切点，独立权限，先持久记录再写原生接口，读回准确 ID、实例 epoch 与标题后完成。unknown 只观察标题，不重写；不直接改第三方历史数据库。
- OpenCode 走原生 session PATCH；Antigravity 走 UpdateConversationAnnotations；Cursor native_api 走既有本地 repository 的 composerDataService，再读原生 header。其他端点以实际能力声明为准。
- Codex follower IPC 继续用于原会话通知；创建/改名走现有原生 Node 工具宿主接收端。Claude Desktop 走 LocalSessions，Pi 走宿主 SDK，均不启动替代 Agent。Claude Code inbox 不具备创建接口时明确 unsupported，调用方可选择已有 Claude Desktop 实例。
- DJ 未接通或达不到效果时，调用方 AI 可选择自身原生能力、其他可用接口或已安装 Skill 完成；不依赖特定第三方工具，已受理或 unknown 操作须先查证，避免重复效果。

此前首条输入与改名批次：干净候选源码树重建后，4 项创建/改名集成与 2 项保护性单测通过（134 条断言）。OpenCode、Cursor、Antigravity 的专用测试对话均完成真实原生改名并读回同 ID、同 epoch；Cursor Inspector 已关闭。额外运行的历史 lifecycle 套件中，9 项依赖已禁用且当前 fixture 未提供的 oc-profile，返回 not_found；未恢复进程托管或将其记为通过。

## 现有宿主控制与边界

- Cursor、Claude Desktop 共用同 UID、PID 出生身份、进程 origin、准确 window 与 loopback Inspector 传输；只开放固定机械操作，不提供任意脚本执行接口。Inspector 调用按端点串行，限制队列及截止时间，仅关闭本次打开的 Inspector；已有调试器占用时拒绝，失败、取消也执行清理。
- `dj native configure` 支持 `tool=claude,surface=desktop`：先检查已有进程，再只读获取原生窗口和 origin，写私有端点；多窗口必须指定 window_id。不会修改第三方签名、关闭 App Tools 认证或冒充受信调用方。Claude 业务请求调用 renderer 已持有的 LocalSessions；Codex 接收端加载及鉴权边界见 [原生工具宿主](../../connectors/codex/README.md)。
- Codex 的创建键保留在接收端本次生命周期内；宿主或接收端重启后无法查证的创建保持 unknown，不按同名会话猜测或自动重建。Claude Desktop 同理。
- Claude Desktop 和 Claude Code inbox 是不同原生接收形态；不以 Desktop 创建结果冒充 CLI inbox 的创建能力。Pi 扩展生成入口从宿主导入 SDK，业务实现仍为 Eliscript；SDK 会话复用原生资源加载与权限，不修改当前交互会话。
- 当前能力交付和真实客户端证据分开记录在状态页；没有运行实例的工具继续完成代码、包与说明，留待实例启动后核验，不为验证新启替代 CLI。

### 原生一次创建与首条输入

Codex 当前原生 create_thread 需要非空首条消息；DJ 在动作受理前检查 content，原因 native_creation_requires_content。该明确文本作为创建请求的一部分持久保存，再交原生接口一次受理。确认后 initial_input_state=native_queued 并返回 initial_input_receipt_key，不再走第二次 session.send，不制造 initial_delivery_id。原生 API 受理、输入可读、模型执行及业务完成分别核对。原生创建未知时只查同一创建键；缺失结果不会触发重建。新创建标题及改名都从活会话读回，不把可能滞后的历史 SQLite 标题当作当前标题。

本批补齐经干净候选树构建、9项定向集成与34项保护/契约回归通过（631条断言）；包含原生首条输入不重复投递、Pi多会话隔离/分页、创建键不确定防重及Claude原生协议调用。真实Codex已完成创建、改名、同ID读回与固定标记响应；Cursor新进程上的原测试会话读回通过且Inspector关闭。当前无Claude Desktop/Pi活实例，协议替身不冒充这两项真实客户端验收。

| 用例 | 保护点 |
| --- | --- |
| T53.desktop-host-control.integration | Claude Desktop 原生创建、改名、原ID发送 |
| T53.codex-host-control.integration | 私有接收端、原生管道、工作区和首条文本、同键防重 |
| T53.pi-host-control.integration | 原交互会话保留、独立子会话发现/改名/输入/读取与分页 |
| T53.native-initial-input.sqlite | 原生同时受理首条输入后不重复投递 |
| T38.pi-native-creation-unknown.unit | 可能已创建的SDK请求不按同键重建 |
| T38.native-host-result-boundaries.unit | 原生结果、未知信息与创建工作区边界 |
