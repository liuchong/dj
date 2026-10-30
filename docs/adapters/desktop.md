# Codex / Cursor 桌面端接线

本轮已完成原生协议集成，以及国际版 Lark 专用机器人到 Codex/Cursor 原订阅会话、独立 recipient API 显式回复原消息的真实验证。Codex 使用已有 IPC；Cursor 的 Bridge 未启用时可显式使用 native_api，由 DJ 按需开启、关闭原进程 Inspector。Inspector 自动开关、取消清理与既有端口保留已验证；Cursor→DJ 的 MCP/API 不依赖 Inspector。采用已有桌面实例的原生接口，查询、登记和发送均不新启另一个 Agent，不覆盖目标的模型、权限或服务等级。

## 服务配置

从 `config/service.example.json` 准备私有服务配置；所有相对路径都以配置根为基准。默认根为 `~/.dj`，因此示例的 `../.codex` 指向同一用户的 Codex 配置目录。示例中的原生线程 ID、工作区目录、Cursor manifest 名称和窗口 ID 必须替换为实际值；示例不会自动开启桥接或重启客户端。

| 配置 | Codex | Cursor |
| --- | --- | --- |
| `tool` | `codex` | `cursor` |
| `ownership` | `existing` | `existing` |
| 原生入口 | `socket_path` 指向同用户 IPC socket | `manifest_path` 指向同用户 0600 Desktop Bridge manifest，或显式配置 `native_api`（两者互斥） |
| 历史库 | `history_database` 指向当前 `state_*.sqlite` | Bridge 使用 `history_database`；native_api 读取原生内存，不需要历史库 |
| 目标范围 | `directory` 必须等于目标原生线程的 `cwd` | `window_id` 必须等于原生窗口；native_api 另核对原 PID/origin、workspace_id；自动开关另核对 process_birth 与只读 helper |
| 原生帧预算 | 可显式设置 `snapshot_max_bytes`，1–64 MiB；省略时沿用调用方响应预算 | 原生响应仍受调用方响应预算约束 |
| 工作区引用 | 明确配置 `workspace_ref` / `workspace_refs` | 明确配置 `workspace_ref` / `workspace_refs`；它们是部署者为该窗口分配的范围标签 |

服务只读打开原生历史库。Cursor manifest 的 token 仅在内存中用于原生请求，不进入配置投影、投递信封或日志。socket 必须属于当前用户；原生 socket 身份变化形成新的 instance epoch，旧绑定不会直接当成新进程的绑定使用。

Codex IPC 的状态快照是不可分页的原生帧，长会话可能超过 1 MiB。需要时由端点显式配置较大的 `snapshot_max_bytes`；它只放宽该原生帧的有界读取，不改变返回目录页、消息页及 DJ API 的响应预算。接收器先读取4字节长度并核对上限，再一次分配帧缓冲、按片段填充，避免长帧反复拼接造成二次复杂度。超过配置上限仍保留 unknown，探测 reason 明确为 desktop_frame_limit，不伪装为目标忙碌；不通过截断 JSON 猜测 idle，不申请无界缓冲。长会话部署应为该不可分页快照预留足够预算。

为两个目标分别配置独立的 recipient 主体和凭据，`target_constraint` 精确绑定 `tool`、`native_namespace` 与 `native_session_id`。复制 `config/client.example.json` 为对应客户端配置，分别引用自己的 recipient token。操作员使用独立 operator 凭据登记目标；不能让两个 Agent 共用 operator 凭据或相互复制凭据。

## 业务调用

1. 操作员启动 DJ，以 `catalog.refresh` / `session.list` 查询已配置范围。Codex 的共享历史项只标为历史，`session.probe` 通过 IPC 找到原会话 owner 并取得状态快照后，才报告活接收方。Cursor 只返回明确配置窗口里的 local 线程，draft 或其他来源不进入可发送目标。native_api 只返回指定工作区已加载的原会话，不宣称完整历史覆盖。
2. 用返回的精确 `session_ref` 调用 `session.send`，或通过 `agent.discover` / `agent.register` 绑定独立 recipient 后创建订阅。默认 busy=steer 时，Codex 可通过原生忙时接口接收独立通知；显式 queue 才等待空闲。unknown 不猜测为空闲，所有模式都保留提交前复核。
3. DJ 按既有流程先持久化 `submitting` 再执行原生发送。Codex 空闲使用 owner 定向的 `thread-follower-start-turn` v2，忙时 steer 使用 `thread-follower-steer-turn` v1；Cursor Bridge 使用 `sendMessage` 且 `force=false`；native_api 核对 idle 后调用原会话原生 submitMessage，DJ 自动管理的 Inspector 在操作结束时关闭。不自动尝试第二种发送模式，不强制打断原任务。
4. 原生 ACK 或 Cursor submitted/queued 仅证明接口接受，不证明 Agent 已开始、已回复或已完成。超时、断线及不确定响应保持 `unknown`，不自动重发；未能取得可靠去重/观察证据时按既有人工核对流程处理。
5. 信封继续携带原 `reply_context_id` 与 `allowed_actions`。Agent 通过自己的 DJ CLI/MCP 凭据显式调用 `message.reply`，由现有 IM outbox 回复原话题；桌面端口不代替 Agent 生成答案。

## 查询与能力边界

Codex 会话列表来自只读状态库，消息来自当前原生 owner 的会话快照；快照历史不完整时报告 partial，不读取或复制开发者自身的原始运行日志作为兼容证据。Cursor 列表有原生 200 条上限，达到上限保持 partial；Bridge 消息读取限于本机已有缓存，缺失项不伪造完整正文；native_api 列表只报告已加载对话；已知原生 ID 的核验、消息读取和提交可通过本机 localRepo.loadAgent 加载已有本机记录，前提是原生 header 为 local、记录存在且工作区 ID 精确匹配。请求结束释放临时引用；提交引用仍由原模型请求持有。不会为了列表批量加载，不创建新对话或提交额外输入，也不把滞后缓存的空列表当作终态。两者都保留有界分页及响应字节预算。单条消息自身超过页字节预算时明确拒绝，不返回无法推进游标的空页，也不静默截断正文。

这两个已有桌面端口不提供原生未支持的创建会话、启动/停止用户客户端、原生幂等或确定未送达查询；能力明确为 unsupported。需要这些能力时不能用新托管实例替换当前目标。已有 OpenCode/Pi 的独立生命周期能力保持原实现，不因此声明 Codex/Cursor 的全部形态已支持。

先完成两条主要业务链的必要功能验收，再补关键保护性测试。其他工具的完整验收矩阵不作为本次交付前置。

## Cursor 自动 Inspector 配置

native_api 指定 inspector_url、process_id、process_origin、workspace_id；当前适配 Cursor 3.27.14。manage_inspector=true 时再提供从只读进程信息 helper 得到的 process_birth，以及指向目录包 libexec/dj-process-info 的 process_helper_ref。仅 macOS arm64 默认 9229 端口，helper 已随成品编译，不要求用户安装编译器。原进程重启后必须重新核对身份，不自动换目标；已有调试端口不抢占，发送 unknown 不重发。完整字段及私有配置方式见[目录包运行说明](../../packaging/runtime.md)和[接口记录](cursor-native.md)。
