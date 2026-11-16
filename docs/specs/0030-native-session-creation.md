# 0030 原生空对话创建

DJ 独立提供会话发现、创建、读取、定位及投递。它直接调用已有实例的原生接口，不依赖其他 Agent 控制工具，不替 AI 选择任务或协作对象。调用方来自哪个工具，不限制目标工具；不建立工具两两配对的实现。

以本机安装版与官方最新版为接口依据；旧安装可更新，不保留旧版兼容路径。Cursor 原生作用域按构造器能力形状定位，不绑定某个安装版或压缩变量名；进程身份和协议核验继续保留。

## 请求与权限

`session.create` 需要 `instance_id`、`expected_instance_epoch`、`workspace_ref`、独立 `idempotency_key`，可提供 `title`、绝对 `directory` 及目标支持的 `model_selection`。创建空对话与发送首条消息分开，不自动登记 Agent、订阅、复制权限或选择模型。

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
| Codex | 当前未接通符合合同的空对话创建接口 | 已有 owner IPC 只控制原对话；已确认的 App Tools 创建同时提交首条消息，不能用占位任务冒充空对话 |
| Claude / Pi | 当前不支持已有实例上的空对话创建 | 不新建 CLI / RPC / ACP 进程替代 |

不支持的创建在持久动作受理前返回 `unsupported`，带原因 `native_empty_session_create_unavailable`。不支持的模型覆盖同样在受理前拒绝，原因 `creation_model_selection_unsupported`，不悄悄使用其他模型。Antigravity 模型使用明确的原生 enum，不按展示名称猜测；新建空对话的显式初始模型只用于首次输入，不冒充之后的实时模型选择。

## 不确定结果与验收

持久 lifecycle 绑定精确目标与创建键。原生调用前失败为明确未创建；请求可能已写出后失败为 unknown，保留原生 ID。Antigravity、Cursor 的创建键派生确定性原生 ID，恢复只查原 ID，不因查不到再创建；OpenCode 原生结果缺 ID 时保持 unknown，不按标题猜测。

`lifecycle.get` 返回创建工作区、原生引用及可见会话引用；恢复仍受原身份和当前权限约束。ready 是原生创建受理及目标核对的证据，不等于模型运行、桌面当前 Tab 或业务任务完成。随后单独 `session.send`，沿投递台账观察。

验收聚焦创建与工作区组合：已有实例跨目录、目录范围拒绝、缺查询权限、准确 epoch、空对话无 prompt、模型显式覆盖、原 ID 不重复创建及不确定恢复。复用既有收件/订阅证据，不重跑 IM、性能或全工具矩阵。

本轮验收：4 项创建集成、1 项既有桌面系统接线回归、2 项关键边界单测通过（合计 7 项）。已有 OpenCode Desktop、Antigravity Desktop、Cursor Desktop 均经本机原生接口创建空对话读回；Cursor 再次使用同一创建键读回同一 ID，Inspector 已关闭。该证据不包含模型执行、IM 外发或 Codex 空对话创建。
