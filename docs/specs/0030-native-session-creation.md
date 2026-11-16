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
| Codex | 当前创建尚未接通 | App Tools 支持带首条消息创建，但本轮直连管道被关闭；不捏造占位任务 |
| Claude / Pi | 已有实例上的创建尚未接通 | 不新建 CLI / RPC / ACP 进程替代 |

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
- Codex 现有 follower IPC 不含创建/改名入口；本轮直接连接本机 App Tools 管道时，DJ 运行时和原生 bundled Node 均被关闭，未接通不等于平台不支持。不能再将此写成空对话限制，也不以新 App Server 或占位 prompt 补齐。Claude、Pi 创建仍未接通。
- DJ 未接通或达不到效果时，调用方 AI 可选择自身原生能力、其他可用接口或已安装 Skill 完成；不依赖特定第三方工具，已受理或 unknown 操作须先查证，避免重复效果。

本次补齐：干净候选源码树重建后，4 项创建/改名集成与 2 项保护性单测通过（134 条断言）。OpenCode、Cursor、Antigravity 的专用测试对话均完成真实原生改名并读回同 ID、同 epoch；Cursor Inspector 已关闭。额外运行的历史 lifecycle 套件中，9 项依赖已禁用且当前 fixture 未提供的 oc-profile，返回 not_found；未恢复进程托管或将其记为通过。
