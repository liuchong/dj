# Agent 工具适配设计

DJ 不进行推理、答案生成、语义状态识别或业务计划。此层只连接既有工具协议、序列化输入并读取确定的原生观察；提交给外部 Agent 不等于 DJ 自己具有 AI。

当前约束优先：正式配置拒绝非空 managed_profiles，以下 managed/CLI 段落保留为历史协议说明，不能装配为消息投递回退。用户本轮要求补齐原首期 OpenCode、Pi 的已有进程核心接入；其他工具、IM、性能和可选创建/启停验收后置。OpenCode 连接当前 Desktop 的既有 HTTP server；Pi 必须先具备原进程本机收件接口，不能用新 RPC 子进程冒充。

OpenCode 当前原生消息读取支持最新有界页和 x-next-cursor/before 续页，不把 message ID 猜成游标。每页最多 32 行，响应或投影超过预算时仅对只读 GET 逐次缩页；单条仍超限时明确 partial，不无界读取整段历史。分页覆盖与模型实际回复分别观察。

## Codex/Cursor CLI 接线

`managed_profiles` 可显式配置 `tool=codex|cursor`、可信 `argv`、`cwd`、`native_namespace` 和非空 `workspace_refs`。Codex 使用 `codex app-server` 的 JSONL 协议，Cursor 使用 `agent acp`。只有公共 `instance.start` 才启动新进程，`session.create` 才创建本端口管理的新会话；不接管其他终端或桌面的历史会话，也不替换现有 receiver。同一 tool 不混配桌面 endpoint 和 CLI profile。

原生 CLI 沿用自身登录或 profile 的受保护环境配置，不把 key 放进 argv。Cursor 可显式设置 `auth_method=cursor_login` 执行 ACP 认证；原生凭据失效时该方法可能发起登录流程，未配置时 DJ 不调用它。需要无人值守密钥接入时，应先按原生 CLI 要求配置受保护的认证环境，不自动开启登录。JSON-RPC 单帧上限 1MiB、最多64个待响应请求；日志流只排空、不落原文。权限请求保持待处理，不自动批准，也不把输入流写入成功当作投递成功。Codex 以 `turn/start` 返回的 turn ID 确认接收，Cursor 以本次 prompt 的实际原生进展或最终响应确认；结果不明保持 unknown、不自动重发。

仅列举本服务显式创建并持有的会话；本进程消息观察有界保留，截断后明确 partial。实例停止只处理本端口持有的子进程，有未完成原生工作或权限请求时保持 draining，不结束其他工具进程。协议依据：[Codex App Server](https://learn.chatgpt.com/docs/app-server)、[Cursor ACP](https://cursor.com/docs/cli/acp)。

## 统一能力声明

每个适配器按 tool + surface + protocol + version + os 报告能力，不以一个 supported=true 代替差异。

| 能力 | 含义 |
| --- | --- |
| discover_history / discover_live / discover_window | 历史、活接收方、真实窗口状态分别可查 |
| attach_existing / managed_start / managed_resume | 已有实例连接、新托管进程、恢复历史分开 |
| start_idle / steer_busy / native_queue | 空闲启动、工作中追加、原生排队 |
| observe_accept / observe_start / observe_idle / observe_finish | 不同证据可独立缺失 |
| lookup_dispatch / native_idempotency | 结果未知核对与原生去重 |
| text / attachments / reply_tools | 允许输入内容和统一工具可用性 |

每个能力带 supported/unsupported/unknown、证据类型、核对时间和限制。unknown 不当作 supported。协议 ACK 观察转换须精确到原生字段；错误保持可重试、未送达、结果不明的区别。

通用接口见 [架构](../architecture.md)，目标身份见 [领域模型](../domain-model.md)。默认优先公开协议。对同一目标从私有方式切换到公开方式前，核对原生命名空间和所有未结算投递；不因工具名相同而切换。

## Codex

公开 App Server 用于 managed 会话控制：initialize 及具体 thread/turn 方法属于 Codex 自身协议，与 DJ 的 MCP 协议版本无关。thread/list 是历史发现，thread/loaded/list 是该实例已加载列表；turn/start、turn/steer 和 expectedTurnId 要按原生规范使用。[CX01](../references/official-sources.md#codex)

existing 桌面采用单独、默认关闭的私有适配配置，核验 owner 和当前版本。活动 steer 成功不能推出 idle start 成功；首轮必须分别实测。普通 TUI 历史可读但没有接收口时，返回 history_only。不会以 codex exec 或新 App Server 替代原目标，不更改目标模型、权限或服务等级。

## Claude Code

三条独立路径：existing inbox、显式开启的 Channels、managed CLI/SDK。inbox 先定位真实会话地址，保留 inbound accept/hold/refuse；socket 写出但无 ACK 时是 uncertain。Channels 必须有用户会话 opt-in 与组织/插件条件，默认不启用 permission relay。[CL01–CL05](../references/official-sources.md#claude)

managed print/stream 使用原生会话身份和授权，不能描述为接管已有 Desktop Code。普通 Desktop Chat/Cowork 不自动属于 Code 命名空间。余额或认证失败单独记录为模型运行失败，不抹掉已观察到的输入接受。

## Cursor

managed 首选公开 ACP 或 SDK 集成；ACP 需 initialize、认证、session/new/load、session/prompt 与权限回调。工具授权由已有策略决定，不能复制示例中的自动同意行为。[CU01–CU04](../references/official-sources.md#cursor)

官方 SDK Bridge 通过 sdk.v1 提供 SDK agent/run 能力；它与实验 Desktop Bridge 不同。existing 桌面实验方式必须单独标注版本、当前实例、会话列表上限和重启恢复证据。启动新 SDK Agent 不算唤醒原桌面对话；不默认启用 bridge 开关或重启应用。

## OpenCode

连接指定现有 HTTP server 的健康、实例、项目和原生 session；后端会话可能由多个客户端共享。新起 opencode serve 只表示新服务，不代表附着现有桌面。异步 prompt 返回 204 只算请求接受，结合事件和消息 ID 观察结果。[OC01–OC04](../references/official-sources.md#opencode)

普通服务支持与桌面当前 Tabs 检查分开。current_window 只说明此刻打开，不猜 creation_origin。私有 Inspector 或 runtime Tabs 访问仅限显式授权与兼容版本。ACP 是另一公开托管选择，不能与 HTTP 会话身份混用。

## Pi

managed RPC 采用长期子进程 stdin/stdout JSONL；持续读取 stdout，遵守背压和严格 LF 分帧。命令用唯一 ID 关联响应。prompt 可能返回 started/queued/handled，handled 不意味着有模型 run，不能一律等待完成事件。[PI01–PI05](../references/official-sources.md#pi)

busy 时显式选择 steer 或 followUp；无行为字段的错误不转成静默重发。agent_end 与 agent_settled 分别记录，后者才表示原生不再自动续跑。RPC 和 SDK 适配单独实现；普通 TUI 若没有已核验收件口则只发现历史，不自动接管。

## agy / Antigravity

agy managed 使用 input-format/output-format stream-json 的同一进程，按每回合 result 决定何时提交下一条。conversation 恢复启动新进程，需 managed_resume 权限，不替代 existing TUI。原生 SUCCESS 或 exit 0 还须检查 response、denied_actions 和实际事件。[AG01–AG05](../references/official-sources.md#antigravity)

桌面独立适配 language_server 的版本敏感私有 RPC，明确工具 namespace、真实会话 ID、实例 epoch 和已授权凭据来源。桌面历史、CLI 自身历史、CLI 中的桌面摘要镜像分别标记。导入历史不能创建两端实时共享保证。任意非托管 agy TUI 的自动鉴权/attach 仍是待验证项。

## 能力不满足时

注册可保存目标描述，但用于主动订阅至少要求 attach_existing 或已批准 managed 模式、明确目标身份、start_idle、可安全处理 busy 的方式和接受证据策略。缺失 start_idle 时订阅创建返回 unsupported；只有 steer 的目标不能满足“空闲自动开始工作”。

无法观察 start 的适配器可以投递，但显示 start_observation=unsupported，不能通过 T06 的完整唤醒验收。未经厂商支持的 lookup 不以历史文本搜索充当确定未送达证据。各工具以独立兼容档案记录原生版本、协议版本、OS、模式和通过的验收编号，首轮不填造支持版本范围。

## 面向模型的接线约束

发现必须返回可直接复用的 candidate_ref 与 target_summary，不把原始 endpoint、认证参数或历史列表交给模型自行拼协议。登记核验可信主体的 target_constraint；适配器不能从用户消息猜接收实例。回复工具若无法在目标宿主调用则明确 reply_tools=unsupported，不能宣称完整双向链路通过。

## 首期绑定

当前交付优先接通已有 Codex Desktop IPC 与 Cursor Desktop Bridge，具体配置和能力边界见[桌面端接线](desktop.md)。OpenCode HTTP 与 Pi managed RPC 保留已有实现，专项验收后置。共同使用 DJ CLI 完成订阅/回复；OpenCode MCP 属于需单独通过的宿主兼容面，Pi 不依赖未验证 MCP 客户端。profile 创建 Pi 进程与模型调用 agent.register 分开，真实 session 身份在登记前由可信宿主核验。具体范围和版本候选见 [首批接入](../release-scope.md)。

## 目录、直发与生命周期扩展

适配器新增独立能力 list_sessions/read_session_messages/create_session/start_instance/stop_owned_instance，并分别标明 scope、分页、完整性、版本和归属。不以能发送推出能创建，不以能读当前会话推出能遍历所有历史。session_ref 可指未登记目标，直发必须 probe 原 receiver 并加入统一 TargetRoute；目录采集绝不生成实时 IM Event 或触发订阅。

首期 OpenCode 增加指定实例空 session 创建及获准 managed serve profile 的显式启动；已有 server/session 仍不被替换或停止。Pi start 产生已核验初始会话，当前 get_messages 可作受限采集来源；同 RPC 的 new_session 会切换会话，首期 session.create 不以它伪装为无影响创建。具体契约见 [统一控制面](../agent-control-plane.md)，其余工具缺证据则公开覆盖/能力缺口。
