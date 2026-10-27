# Cursor Agents Window 本机接口边界

核对版本：Cursor 3.27.14。此记录区分一次性开发调研、显式配置的版本适配通道与 Desktop Bridge；不能把调研成功直接当作生产接线通过。

## 已实际调用的内部原生 API

新版窗口的 Agent Repository 支持：

```text
createAgent(message, environment, options)
```

本机空对话使用已有工作区环境，明确传入 `skipInitialSubmit: true`、固定的 `composerId` 和 `trustPolicy: "require-trusted"`。该路径不发送第一条消息，不放宽工作区信任，不决定模型，不新建 worktree。

一次性 Inspector 调研已实际调用这个入口，在获准的专用工作区创建本机空对话。窗口 Repository 读回 `source=local`、实际会话 ID 和零消息；标题为 `DJ local relay`。私有会话身份和操作回执保留在忽略的本地证据目录，不进入仓库。此事实证明内部原生创建存在，不证明 DJ 已获得无需调试器的外部创建入口。

原生实现位置：应用资源中的 `out/vs/workbench/workbench.glass.main.js`。常规窗口的 `composer.createNew` 与新版 Agents Window 的创建路径不同，不能互相替代。

## 原有会话的原生通知实证

同一已存在的专用 local 会话已通过内部原生 `getAgent(id).submitMessage(text, options)` 接收一条通知，随后在同一会话的内存消息记录中读回原输入和唯一标记回复；原生 header 为 `done`、composer 为 `completed`。投递期间没有创建会话、启动 Agent CLI、改模型或修改开关，临时 Inspector 已关闭。私有证据为 `cursor-existing-notify-168-summary.json` 及其引用的单次 issued 记录和原生读回。

首次观察时，持久缓存显示 `aborted` 且消息列表为空，但原生提交 Promise 尚未完成；后续同一原生会话已经完成并包含两条消息，而磁盘缓存仍为空。故此次不能把缓存中的空列表或 `aborted` 当作投递终态，也没有因观察提前结束而重发。实际接收事实由精确原会话的原生运行态及消息读回证明。

这证明内部发送入口能通知原会话，不证明当前生产 Desktop Bridge 已接通，也不证明 Lark 到 Cursor 的订阅回复闭环完成。后续业务接线新增下述显式 native_api 通道；原先调研事实不自动证明新适配器已经通过验证。

## 无需 Inspector 的原生接口

| 接口 | 入口与能力 | 本次证据边界 |
| --- | --- | --- |
| 主进程 Node IPC | 版本对应的主进程 Unix socket；`launch` 与 `diagnostics` channel | 原进程诊断调用成功。工作区打开请求会触发新版窗口的创建入口，但该请求不返回可用会话身份，不能据此确认创建或盲目重发。 |
| Desktop Bridge | 原生私有 manifest 指定的 HTTP-over-UDS；`listThreads`、`sendMessage` | 本机服务存在，但 renderer 的 `desktop_bridge` 开关关闭。此时空列表不证明没有对话；DJ 必须拒绝将其报成完整目录或就绪状态。 |
| Agent Host | `~/.cursor-agents/daemon.sock` 上的 HTTP/2 protobuf RPC；服务名 `agent.v1.AgentHostService` | 已核对随应用安装的原生实现与协议定义；当前实例未启用 daemon，socket 不存在，尚未进行实际 RPC 调用。 |

Agent Host 定义了 `GetDaemonInfo`、`CreateSession`、`ListSessions`、`HasSession`、`SendMessage`、`AttachSession` 与观察接口。原生连接代码以 `GetDaemonInfo` 检查 API schema revision `1`，不是把任意 socket 当作有效接收端。

协议与连接实现位于应用资源中的：

- `extensions/cursor-agent-host/dist/330.js`：服务定义、Unix socket 上的 HTTP/2 客户端。
- `extensions/cursor-agent-host/dist/480.js`：产品连接、发现与握手。
- `extensions/cursor-agent-host/dist/914.js`：窗口 Provider 与 daemon 请求映射。

这些文件是当前版本的定位依据，不是 DJ 的运行时依赖，不复制进交付物。原生连接器还包含启动和替换 daemon 的逻辑，DJ 不得直接调用它来冒充“只连接已有实例”；后续如接入，必须只连接已存在的端点并核对实际身份、工作区和版本。

## 当前结论

当前账号下，`desktop_bridge` 与 `cursor_agent_host_move_exec` 均为关闭状态；原生设置 Feature Flag override 的资格检查也为拒绝。未覆盖或绕过这些检查，未改实验开关、登录身份、模型或安全设置；该扩展的公开配置声明未提供 daemon 启用项。

无需 Inspector 的两个原生服务在此实例中仍未开启。为完成原会话通知，DJ 现提供下述显式 native_api 版本适配通道，并已通过生产端口的真实 Lark 订阅与原消息回复；这不表示 Bridge 已启用，也不表示调试端点的前置配置已经消失。创建仍是可选增强，不是通知的前置条件。

本次调研已关闭自开的 Inspector，并确认原 Cursor 主进程身份未变。后续推进复用以上接口定位和私有回执，不重复整个调查，不安装扩展、不接入远端控制服务，也不恢复 CLI 消息投递回退。

## 显式 native_api 版本适配通道

Cursor endpoint 可选择 `native_api`，与 `manifest_path` / `control_manifest_path` 互斥，通过原生 Agent Repository 调用原有 local 会话。manage_inspector=true 时采用下述 DJ 按需开关模式；未设置时仅连接已开启端点。两种模式均不安装扩展，不修改 Bridge、实验开关、模型或工作区信任，不自动退到其他通道。

配置必须提供 `inspector_url`（仅 `http://127.0.0.1:PORT`）、`process_id`、原进程 `performance.timeOrigin` 对应的 `process_origin`、精确 `workspace_id`；endpoint 另有 `window_id`、`workspace_ref`、`directory` 与原实例身份。每次连接核对原进程 PID、origin、UID、browser 类型，再检查客户端版本 3.27.14 及原生对象形状；重启或升级需要重新发现并更新可信配置，不自动换进程或目标。

只列举指定窗口、工作区中已经加载的 local 会话；对明确原生 ID 的 probe/messages/submit，先核对本机 header 和 localRepo.agentMap 中既有记录及 workspaceIdentifier.id，再按需调用 localRepo.loadAgent。临时加载引用随请求释放；列表不加载历史，未知/归档/非本机或其他工作区记录拒绝。消息从该原生记录按游标与字节预算读取，不以滞后的磁盘缓存代替当前会话。发送前再次核对原会话 idle 和已受信的工作区，继承原会话设置。仅在原生 onDidSendRequest 确认后返回 accepted；响应超时或发送状态不明保留 unknown，不重发。单进程请求有界串行，外部已有 renderer debugger 时拒绝抢占。临时 CDP 对象与本次 renderer 调试连接在调用结束时释放；预先存在的 Node Inspector 不由 DJ 关闭；DJ 自行开启的端口按下述流程关闭。

这是一条依赖明确调试端点、固定客户端版本的本机接口接入方式，不是无需前置配置的通用公开 API。可选创建继续 unsupported。生产端口及真实订阅结果分别记录，不以内部调用证据替代。

## 本批交付证据

生产端口在已配置原实例上完成发现、注册、订阅、消息读取与原生发送。可信操作员先为原会话配置固定 DJ API 客户端；随后本人给获准机器人发送一条新消息，原 Cursor 会话使用独立 recipient 调用 message.reply/outbound.get。平台读回核对本人发送者、机器人发送者、精确 reply_to 与唯一回复；持久 delivery 的 binding 指向原 native_session_id，recipient 与出站主体相同。没有新建会话、启动 Agent CLI 或修改原会话模型。

真实链路基于 build172；build174 只进一步限制 native 会话的历史覆盖声明、截短标题投影并补配置保护，未重复真实发送。build174 的 T01.desktop-relay.integration 为 115 断言，T38.desktop-runtime.unit 为 31 断言。私有终态证据为 lark-cursor-existing-relay-173-terminal.json。控制器在 15 秒停止观察窗口结束时先记录 draining 并以 exit1 退出；后续权威读回确认 native_drained、服务租约释放、socket 删除及 claims 为零，原始失败记录保留，不改写成 guard exit0。Inspector 已关闭，已有 Cursor 进程保持运行。

## DJ 按需管理 Inspector（当前采用）

用户已明确允许在无更好接口时采用此方式，并由 DJ 控制开启与关闭。native_api 可设置 manage_inspector=true、process_birth 与 process_helper_ref；后者指向目录包 libexec/dj-process-info。这个只读 Darwin 小程序只读取真实 UID、进程出生标识、可执行文件及 SIGUSR1 是否有处理器，不发送信号、不接收消息、不启动 AI。业务逻辑与生命周期仍由 Eliscript 实现。

一次 DJ→Cursor 操作在同一有界队列内：核对 helper 文件权限及同用户原进程/出生标识/处理器，确认默认 9229 端口空闲，再向原进程发送 SIGUSR1；通过 Inspector 复核原 PID/origin/UID 后执行原会话操作，finally 使用独立短清理预算关闭本次自行开启的 Inspector 并检查端口。原来已有的调试端口不抢占、不关闭；进程身份变化不向新进程重试；未知发送不重发。

仅 DJ 调用 Cursor 接口的方向使用这段控制。Cursor 主动请求 DJ 的 MCP/API 不开启 Inspector；两条方向的身份与权限保持独立。没有安装扩展、修改客户端启动参数、重启客户端或创建替代会话。

当前 build178 的真实自动开关验证已通过：原进程初始无 Inspector，DJ 自动完成原会话发现/通知；提交返回时端口已关闭，原模型继续运行并给出唯一标记回复。取消请求后端口也关闭；已有占用端口不被关闭。没有创建对话或启动 Agent CLI。build180 仅补保护性单测，全部生产产物与 build178 字节一致；119 条集成断言与 34 条保护性断言通过。Cursor→DJ 的 agent.whoami 调用与端口不可用/不发送信号的场景分开验证，API 调用不触发 Inspector。私有证据为 cursor-auto-179.json、对应 guard 日志及 build-178-vs-180.json。
