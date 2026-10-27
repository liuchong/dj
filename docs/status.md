# 当前状态与接续入口

2026-10-27 触发黑名单已实现并更新常驻服务：人员与字面字符统一为可组合规则，当前只支持 suppress_trigger；Core 保留入库、查询、已提交/领取内容，匹配与提交/领取前检查只拦自动动作。新增 message.filter.get/update 提供服务级持久策略、权限/版本/幂等。3项集成+1项保护单测通过（52断言）；服务ready、WebSocket connected、规则默认为空，未写入实际人员或字符。详见[0002](specs/0002-message-trigger-filters.md)。

> Lark 当前接线以 [规格 0001](./specs/0001-lark-realtime-subscriptions.md) 和官方 WebSocket / HTTPS API 直连实现为准；外部 IM 命令行进程路径已移除，以下旧施工记录不恢复该路径。

2026-10-27 官方 API 直连已落地并部署：Lark 应用 WebSocket → Core → 默认原生 @ / 显式组合关键词订阅 → 原 Codex 对话原生 IPC 已真实通过，并读回两条输入及确认。Core 的本人发送、机器人原消息回复也分别获得官方读回；独立 recipient 绑定已核对。常驻服务保持原名称，保留数据库、凭据及旧版本恢复备份；源码、运行包与真实控制器均不调用 Lark 外部 CLI 或 SDK。Skill 通过 MDP 校验并安装至通用、Codex、Cursor 的 Skill 目录，调用方采用确认单独留在私有记录。当前应用事件可见范围不等同于本人全部收件箱，其他 IM 与性能专项仍按既定范围后置。

2026-10-27 本机接收增量：Claude Code UDS 与 Antigravity App HTTPS 接口已接入生产装配及私有 native configure 命令。Antigravity 原会话的公开发现/核验/直发、同键单 delivery、实际 Skill 摘要和独立 recipient API 调用均有真实证据；一条授权 Lark 订阅消息已进入同一原会话并持久 accepted。模型在该输入后返回 429 额度耗尽，没有生成 IM 回复；用户已明确以工具接线为目标，不要求模型实际工作。原控制器的提前读取流式 JSON 失败及回复等待超时保留，完整原生回复后续只读确认，未重发 bootstrap。Claude Code 协议夹具已验证收发/迟到回执/不确定性边界，但本机无活 Code 会话；运行中的 Claude Desktop 不冒充该接收端。仅新增并运行必要保护回归，不恢复全矩阵或性能验收。


2026-10-27 OpenCode/Pi 现有实例的核心真实验收已通过：两者均保持原进程/原会话/原模型，完成公开直发与同键去重、主 Skill 与 clients.md 实际摘要、独立 recipient 的 status/whoami 核对。只向授权国际版专用 Lark 机器人发送一条本人身份刺激，两条订阅分别投给原会话，各自通过独立身份回复；平台读回 3 条消息，两个 reply_to 均精确指向该原消息。Pi 接收扩展临时加载在已有 TUI 中，Inspector 已关闭，未更改持久设置；不把 runtime 加载写成永久安装。

收尾遇到服务排空饥饿：旧周期器在每次 drain 前继续 tick、补排观察任务，原控制器已记录收发通过但未自然退出，受控树随后取消并完整回收，原记录不覆盖。修复 main 的 requested 分支后，以成品 CLI 恢复同一台账，无新模型输入或 IM 发送；4 条 accepted 均 native_drained，outbound 仍为 2，claims/租约为 0、socket 删除，约 608.6ms 正常退出。新 T45.standalone-draining-observer.system 保护通过 7 断言；build307 与真实恢复版 build302 生产输出字节一致，只有测试输入/产物变化。最终包 46 载荷摘要/归档核对通过，见 delivery。

首轮真实控制器以库嵌入运行，service.status 的 build_id 原样记录为 source-unverified，不能作为安装身份凭据；后续成品 CLI 恢复使用真实包 build_id 并与 manifest 核对。真实平台、native 及终态证据留在本机 acceptance 的 live-agents-300、live-agents-recovery-304、live-agents-terminal-310；没有重跑完整功能/性能矩阵。

以下为先前阶段记录，按当时已验证范围保留；当前状态以上述真实终态为准。


2026-10-27 本轮 OpenCode/Pi 自动施工交付完成，按用户最新要求不因缺少/未启用 AI 收件端询问或等待。OpenCode 原 Desktop 会话的公开直发已被原模型接受和回复，新分页端口只读核对同一回复成功（无重发）；Pi 已完成原生进程内扩展、私有 UDS、精确原会话端口、配置/Core 接线及目录包。Pi 没有被安装或重载到用户现有 TUI，不声称真实 Pi 模型/IM 或独立 recipient 已验收，后续由用户安排。

Pi 本地 T63.pi-existing-receiver.integration 15 断言通过：独立 Node 进程使用明确标识的 Pi SDK 夹具，Core 经真实 HTTP/UDS 解析/probe/直发，原生会话与消息 ID、分页、同键单输入及关闭回收均成立；不是实际 Pi 或模型进程。后置 T38.native-access.unit 19 断言通过。build290 的 161 输入/647 输出逐项绑定，和集成版 build288 相比只变更保护性单测及其产物，生产输出未变。目录包 46 载荷摘要一致，Node 26.8.2 能直接加载包内 Pi 扩展工厂；最终归档 47 文件（含 manifest），详情见 delivery。没有重跑全套功能/性能、发送新 IM、修改客户端设置或启动替代 Agent。


2026-10-27 用户已继续本轮范围：补齐原首期 OpenCode、Pi，使核心接入达到 Codex/Cursor 当前程度后结束 Goal；其他 IM、性能及可选验收后置。已找到 OpenCode Desktop 1.19.4 的原 DJ 会话，保持 opencode-go / DeepSeek V4.1 Flash。公开免订阅直发实际 accepted 且原模型生成了唯一标记，原控制器因长历史整体超过响应预算没有观察到回复；此失败保留，输入未重发。opencode-http.eli 已改为有界分页，保留 x-next-cursor 原生不透明游标并绑定会话，超预算只对 GET 缩小页；build275 定向 T63 集成 15 断言通过，修复后从同一原会话只读读回该标记。build278 后置 T38 游标保护 13 断言通过，生产输出与 build275 字节一致；新目录包已生成。独立身份和订阅回复继续接线；本机暂未发现运行中的 Pi，未启动替代 CLI。

当前授权的 Codex/Cursor 主线及运行包交付已完成，原 Goal 的全范围验收仍未全部完成。Cursor 公开 session.resolve/probe/send 已在无 IM/Agent/订阅的新服务中通知原会话、读回唯一标记并证明同键重放只有一条 direct delivery；无 Event/Contribution/IM 出站或 claims。服务/租约/socket 清理，Inspector 端口关闭，受控树 exit_code=0/cleanup_complete=true。与 Codex 的公开直发、两客户端原会话订阅回复及 Skill 只读采用证据分别保存。只剩实际客户端配置启用，以及用户明确延后的其他工具/IM 和性能验收；不据旧 Goal 自动恢复这些工作，也不把旧 A20 改写成通过。

当前目录包的 Codex 公开免订阅路径已真实通过：仅配置原 Desktop endpoint，在无 IM、Agent 登记或订阅的新服务中，经 session.resolve/probe/send 送入原调试会话，持久 delivery 为 accepted，并从原生会话读回唯一模型标记。同键重放只返回原 delivery；origin=direct，event_id/agent_id/reply_context_id 为空，events/contributions/outbound/claims 均为零。服务正常停止、socket 删除、service_lease 为零，受控树 exit_code=0/cleanup_complete=true。此证据补齐公开入口与此前适配端口级通知的区别，没有修改业务源码、重新发 IM 或恢复其他工具矩阵。

Codex 新专用调试对话的 Skill 只读采用已通过：通过运行中应用的原生接口创建本地对话，实际读取主 Skill 与 clients.md，两个摘要均与当前文件一致；随后用仅开放 service.status/agent.whoami 的独立 recipient profile 各查询一次。实际 build_id/主体一致，正确返回 unbound，未注册 Agent、创建订阅或发送消息；数据库对应计数均为零。临时服务正常停止、租约/socket 清理，受控树 cleanup_complete。此对话只用于 Skill/API 接线，不替换原订阅目标，也不拿新对话结果证明原会话通知；原链路证据保持独立。实际 MCP/Hook 启用仍未验证。本轮未改业务源码、包或客户端配置。

Codex/Cursor 当前主要业务链的交付资料已集中到 [交付与使用](delivery.md)，提供有 SHA256 的 macOS arm64 运行归档。当前构建的 156 个输入、637 个输出摘要和目录包 40 项载荷均一致；归档另含 package-manifest.json，共 41 项，启动器及只读 helper 执行权限保留。没有为打包重跑业务测试、启动服务/AI 或发送 IM，也未安装或部署。原生接收、独立 API 原消息回复的既有证据沿用；实际 Skill 完整参考、MCP/Hook 配置采用及历史性能缺口继续如实保留。

Codex 原调试会话已通过现有应用接口恢复并收到本次只读核对请求，但接收方将跨会话转发视为不能扩大旧固定命令范围，未执行文件或 API 查询。此结果只证明恢复和请求接收，不证明 Skill 采用；也不能将其写成用户未授权。未重复请求用户确认、未另建会话或启动 Agent CLI，临时查询服务已停止且 socket 删除。本项保留为客户端采用缺口，不阻塞既有 Codex/Cursor 通知业务及当前文档交付。

Cursor 已补按 ID 加载既有本机记录：列表仍只报告已加载对话，精确 ID 的核验/读取/提交先核对原生本机记录与工作区，再调用原生加载方法；请求结束释放临时引用，保持信任/实例校验及 unknown 边界。build250 的 T01 集成 137 断言、build252 的 T38 保护 39 断言通过。真实新进程中已通过生产端口读回同一原调试对话，未重新发消息；主 Skill 摘要、实际目录包 build_id、独立 recipient 与原生会话绑定均核对一致。此次主 Skill 和独立 API 调用采用成立；clients.md 被客户端文件工具拒读，未绕过，完整参考说明/MCP 配置/Hook 实际采用仍开放。两项原控制器非零终态保留，后续读回回执单独记录；原临时服务停止、租约释放，自己开启的 Inspector 已关闭。用户已允许自行调整原先自写的临时调试说明，不再把它当额外审批门槛。

以下为采用核对的中间记录。

真实 Skill 采用核对尚未通过：只读预检中原 Cursor 调试会话在线/idle，原 Codex IPC owner 查询超时，不向其试发或换会话。Cursor 首次控制器漏带 epoch，被提交前护栏明确拒绝为 definite_not_sent；原记录保留，修正后一次提交 accepted。观察超时后对同一原会话只读读回，模型明确没有执行工具：外部消息无权修改原 recipient 接线，且该工作区不允许读取 DJ 项目文件。此结果证明原消息送达与配置授权边界有效，不能证明 Skill 加载或 API 采用；未重发、未绕过拒绝、未安装或改客户端配置。两次独立临时 DJ 服务均 stopped/socket 删除，受控树完整回收；原客户端保留。用户随后已明确授予该只读核对范围；不再因本项目自己写的临时调试说明重复请求相同授权。直接授权已通过原本机接口送入原对话；后续查询报原生接口不可用，核实旧 Cursor 主进程已结束、当前为新进程，不能把新进程冒充旧绑定，也不能把 submitted 当采用通过。该轮临时 DJ 服务已停止、socket 删除、claims=0、服务租约释放。下一步重新发现原目标并先读回，不重发已接受请求；原 Codex 接口仍未确认活 owner。

Codex / Cursor 可选本机消费回调已交付：dj hook pull 从原生 stdin 接收事件并验证 recipient、bound_agent_id、工具和原会话，再领取一项；固定事件幂等键，绝不自动确认或启动 Agent。Codex UserPromptSubmit 附加当前轮上下文，Cursor stop 仅 completed/loop_count=0 返回一次 followup_message，配置 loop_limit=1。skill hooks 只打印片段，未改客户端文件或信任。build230 的 T18 集成 99 断言、build232 的 T26 保护 65 断言通过；两次构建生产输出字节一致，目录包 dj-build232-hooks 已完成摘要及仓库外入口检查。实际客户端 Hook 触发与 Skill 采用仍未验证；不恢复其他工具或性能矩阵。

订阅主动消费已完成：新增 delivery_mode=pull 与 subscription.pull/ack，待办独立持久化；限时领取、重启恢复、同键空结果与租约重放、原接收主体授权、过期换代和回复代次重检均已接线。pull 不启动原生会话或生成 deliveries，consumed 仅确认消费，不代表任务完成。build214 定向集成 31 断言、build218 的 MCP/GEPO 集成 46 断言、build220 后置保护 46 断言与原推送集成回归 27 断言通过。目录包 dj-build220-pull 摘要和仓库外 CLI 入口已检查；这些是本地接口功能证据，真实 AI 拉取采用、工具回调仍未完成。

订阅提示词与任务装配已实现并通过本地功能验证。spec.instruction_policy 提供固定 prompt 与六字段 task_template，随预览票据、订阅版本和贡献持久化；提交前独立重检后随原消息投递，不运行模型或脚本。build208 的 T12.subscription-instructions.sqlite 27 断言与 T38.envelope-snapshot.unit 29 断言通过，覆盖多订阅、改版/暂停、冻结快照、旧订阅兼容、超限阻塞及 UTF-8/非递归边界。T18 公共入口回归 39 断言通过。新目录包 dj-build208-instructions 已生成；只证明本地功能与包交付，真实模型按模板执行和客户端 Skill 采用仍开放。后续主动消费结果见页首；工具回调仍待实现，不恢复历史性能循环或全工具矩阵。

Skill 安装与客户端指引已交付：skill targets/install/check/config 支持共享目录及 Codex、Cursor、Claude、OpenCode、Pi、Antigravity、agy；显式用户/项目 scope、完整引用复制、无覆盖、软链接拒绝，配置生成不读凭据、不修改客户端。build190 定向集成 39 断言，build192 后置保护 32 断言；两者生产输出字节相同。新目录包 dj-build192-skill 的 39 项摘要及仓库外安装/检查/配置生成均通过。仅在隔离目录验证 Codex/Cursor，没有安装到实际客户端、没有启动 AI；模型加载采用及提示词/待办消费/回调缺口保持开放。

GEPO 0.2 已接入原私有 UDS 服务：认证后发现树形目录、同路径 GET 用法和 POST 原业务参数，复用现有权限、台账、schema 和幂等。build185 的 T18 集成通过 22 断言，CLI/MCP/API/GEPO 原键重放只产生一次原生夹具输入；build187 的 T26 后置保护验证元数据不执行目标动作及空权限不泄漏路径。新功能尚不代表客户端配置/Skill 已安装或各工具采用；原真实 Codex/Cursor 通知证据沿用，不重复外发。

以下为先前批次。目录包 dj-build181-managed-inspector 的 38 项文件摘要一致，包内只读 native helper 与仓库外 CLI 帮助入口实际可执行；无需运行时编译器，未安装或部署。原 build180 包的 helper 执行权限丢失记录保留，修复 packageFiles 权限规范化后新包验证通过。180→181 仅打包工具输入/产物变化，全部生产产物字节一致，119 条集成、34 条保护及真实自动开关结果直接沿用，不重复发消息。

已按用户确认采用 Cursor Inspector 方案，并完成 DJ 自动开关：仅在 DJ 调用原 Cursor 会话接口时，核对同用户原 PID/出生标识/信号处理器后临时开启，finally 关闭本次自己开启的端口；原先已有端口不抢占、不关闭。取消请求也使用独立短预算清理。只读 Darwin 进程元数据 helper 随目录包编译交付，不发送信号或承载业务消息，核心生命周期仍用 Eliscript。没有安装扩展、重启客户端或启动替代 Agent。

真实自动通道验证通过（cursor-auto-179.json）：初始端口关闭，原实例/原会话发现与提交后立即关闭，原模型在 Inspector 关闭后继续完成唯一标记回复；取消后的关闭及既有端口保留均通过。Cursor→DJ 的 MCP/API 不依赖 Inspector；集成中 API whoami 与拒绝向非 Cursor 进程发信号分别通过。build178 定向集成 119 断言，build180 后置配置保护 34 断言；178→180 仅单测输入/产物变化，全部生产产物（含 native helper）字节一致，沿用真实结果，不重发 IM 或模型输入。

以下为先前结果；当前 Inspector 使用方式以上述自动生命周期为准。

Cursor 原会话业务链已接通：新增显式 native_api endpoint，使用已有本机 Inspector 调用固定版本原生 Agent Repository，按精确 PID/origin/UID、窗口和工作区核验后发现、读消息与发送。不会自动开 Inspector、抢占 debugger、创建会话、改 Bridge/模型/信任或启动 Agent CLI；无端点时明确不可用。仅支持已加载 local 会话，历史覆盖不能声称完整。该通道是有前置配置的版本适配，不能写成无需调试器或通用公开 API。

build172 生产端口真实完成国际版 Lark→原 Cursor 订阅会话→独立 recipient API→精确原消息回复。平台读回、原 delivery/immutable binding、独立主体与唯一 outbound 对齐，claims0；原会话未替换。控制器先因 15 秒停止观察窗口到期记录 draining/exit1，原始日志保留；随后权威读回确认 native_drained、服务租约释放、socket 删除，已有 Cursor 保持运行，Inspector 关闭。私有证据 lark-cursor-existing-relay-173-terminal.json 区分消息闭环通过与原控制器非零退出，不改写失败。

build174 收敛 native 会话仅 live 可见、标题有界，并补充关键配置保护；发送实现与已验证路径保持一致，不重复发真实 IM。T01.desktop-relay.integration 115 断言、T38.desktop-runtime.unit 31 断言通过；没有重跑全套、性能或其他工具矩阵。后续交付必须保留 native_api 所需的本机 Inspector 条件，不能将已关闭端点报为当前可投递。

新目录包 dj-build174-native-cursor 已生成：37 项文件摘要全部匹配，仓库外 CLI 帮助入口通过，运行不依赖编译器；未安装或部署。build172→174 业务差异已通过逆向摘要证明仅为 native 标题上限与 live/history 可见性收敛，真实发送实现未变；原 14 字符标题与 live 发现路径不受影响，沿用该闭环证据。

以下为先前批次结果；最新状态以上述记录和唯一 TODO 为准。

Cursor 内部原生原会话通知已取得新证据：单次 submitMessage 调用在原 local 会话中产生原输入与唯一标记回复，原生状态回到 done/completed。首次缓存中的 aborted/空列表未被当作终态，也没有重发；后续原生内存读回确认完成，临时 Inspector 已关闭。此结果仅证明内部入口可用，当前仍未接入 DJ 的常规生产投递路径，Lark→Cursor 原订阅会话→回复保持开放。私有证据为 cursor-existing-notify-168-summary.json；接口边界见 [Cursor 本机接口记录](construction/cursor-local-api.md)。

Codex 已有客户端的 Lark 原消息回复闭环通过：操作员先通过原客户端 IPC 给专用原会话配置固定 DJ API 入口，接收方真实调用 `agent.whoami` 核对独立主体与 `bound_agent_id`。随后仅发送一条新的 Lark 调试消息，经真实订阅到达该原会话；模型用自身 recipient 客户端调用 `message.reply` 并查询 `outbound.get`，平台读回确认本人发送者、指定机器人发送者、精确 `reply_to` 和唯一回复。投递 1、出站 1、claims 0，临时服务正常停止，既有客户端未停止或重启。未新建 AI 进程或会话，未修改全局信任或 MCP 配置；本次接收方走 DJ API，不能写成原生 MCP 已接入。证据为 `lark-existing-relay-164-summary.json`、原始受控日志及原平台读回；先前缺少工具配置、错误要求 whoami 返回原生 ID 的尝试均保留，不改写成通过。Cursor 仍开放。

build165 仅更新运行说明，全部编译产物与 build160 字节一致，沿用已通过的定向集成验证。新目录包 `dj-build165-local-only` 的 37 项文件摘要全部匹配，仓库外 CLI 帮助入口通过；未安装或部署。

以下为先前批次的结果与当时缺口，接续以本页顶部和 TODO 为准。

Codex 原会话通知已取得真实证据：通过 macOS 原生 AppleEvent 让运行中的客户端加载原专用会话，再由生产 Desktop IPC 核对 owner、会话与工作区，直发后在同一会话读回唯一模型标记并恢复 idle。随后国际版 Lark 专用机器人真实收信，经公开发现、注册和订阅转发到同一个原会话，投递 accepted、claims 为零；原会话读回了匹配的 IM 消息信封。没有创建副本、启动 Agent CLI 或通过启动参数投递。原话题回复仍未通过：接收模型正确拒绝执行外部 IM 正文里的脚本要求，且当前没有可用的 DJ MCP 工具。后续应在可信客户端配置中接入回复能力，不把外部正文当作执行授权。临时 DJ 服务已正常停止，既有客户端保持运行；私有证据为 `codex-existing-notify-159.json`、`lark-existing-relay-161.json`。

本轮同时收敛 Codex 的工作区发现：历史 SQL 先按配置工作区过滤再按 ID 分页，避免翻过无关工作区的历史才找到目标。build160 与定向 `T01.desktop-relay.integration` 通过（91 断言，含跨工作区和归档行排除、分页边界）；不重跑全套或性能。build159 的测试布尔常量编译失败、真实联调中发现翻页上限及缺少近期成功 watch 读取的失败记录均保留；这些发送前失败没有产生 IM 刺激消息，随后一次真实消息的通知通过与回复失败分别记账。

核心交付要求是：IM 消息到达后，DJ 根据现有订阅中的 ID、名字等定位线索，核对并主动通知原始订阅会话，消息经本机已有实例的 IPC/socket/API/MCP 送达，不经 CLI 参数传递。名字不是替换目标的依据。创建空对话仅为可选增强，没有创建接口不妨碍已有会话支持；没有原会话通知能力则不能报告该工具核心接入完成。

Cursor 就绪判断已修正：每次本机 Bridge 发现前只读检查原生 renderer 的两项启用状态；关闭或缺失时返回 `unknown / desktop_bridge_disabled`，不把仍在监听的 socket 或空列表报成可用/目录已完整。不会改开关、重启客户端或发送模型输入。build157 的定向 `T01.desktop-relay.integration` 通过（87断言）；当前真实客户端也经生产端口读回该拒绝状态。新目录包 `dj-build157-local-only` 的37项文件摘要一致，仓库外CLI帮助入口通过；尚未安装或部署。

一次性本机 Inspector 调研已完成并关闭：新版 Agents Window 的内部原生 `createAgent` 在获准专用工作区成功创建 `DJ local relay` 空对话，实际读回 local 身份与零消息，没有触发模型。另已定位无需 Inspector 的原生 Agent Host Unix socket / HTTP/2 RPC；当前实例未启用 daemon，socket 不存在，Desktop Bridge 功能也关闭，普通 IPC 创建与收发仍未接通。没有绕过原生 override 资格检查、改开关或安装扩展。接口位置和实测边界见 [Cursor 本机接口记录](construction/cursor-local-api.md)；私有回执为 `cursor-native-api-158-summary.json`。此前主进程打开请求没有会话身份确认，不盲目重发。

当前AI工具接入仅限本机已有进程的IPC或loopback API。Cursor只接受local会话；OpenCode端口、配置和观察器只接受loopback地址。新版Agents Window的本机创建接口仍在核对，不以扩展安装为前提；原有连接器记录属于历史本地试验，不能据此重装。 定向T01.desktop-relay.integration通过（81断言），验证非local会话被排除、远端地址在网络调用前拒绝且本机IPC链路保留；T38.opencode-observer.unit通过（130断言），覆盖远端HTTPS/HTTP拒绝。build156成功，未重跑性能或全工具矩阵。

执行期旧启动路径已补齐阻断：生产 Core 的 OpenCode HTTP 端口固定为 existing_only，拒绝实例启停且不声明已证明旧进程消失；已记录的 start 动作执行前还须核对 profile 当前 enabled 状态，避免禁用后的历史记录重新触发进程启动。build151 的 T01.desktop-relay.integration 通过（74断言），覆盖真实 Core/SQLite 中禁用 profile 的 recorded start 被阻断、native start 零调用及端口拒绝边界。更新目录包37项摘要一致，仓库外 CLI 帮助和库导入通过；仅复制交付物，没有部署服务或启动 AI。Cursor 创建连接器仍未安装，真实创建与消息闭环待安装许可及原生读回，不增加全工具或性能重验。

当前接入约束：AI 主动请求 DJ MCP/API，或 DJ 通过接口向已有客户端/CLI 进程的会话投递。正式配置拒绝非空 managed_profiles，Core 不装配进程托管 Agent 端口、不执行 profile auto_start。Cursor 使用 Desktop Bridge，Codex 使用已有 Desktop IPC；未取得相应真实消息证据的链路仍开放。未来自动拉起客户端必须与业务通信分离，不能以启动参数创建或恢复对话。

本轮实现已切断正式 argv 启动接线：build139 的 T01.desktop-relay.integration 通过（36断言，公开直发/订阅/回复走接口、Agent spawn 为0，四类旧profile均拒绝）；build140 的 T38.desktop-runtime.unit 通过（19断言，含八种tool/auto_start组合拒绝）。初次集成失败为测试spy替换整份process端口丢失服务owner方法，修正为只覆盖spawn后通过，原日志保留。本轮未重跑全套，旧托管profile用例不作为新接入方式的完成证据。当前只读发现未找到可用Cursor Bridge，未发送消息或启动替代Agent；真实Desktop消息闭环仍待完成。

后续真实 IPC 进展：Cursor 经系统正常启动且未传客户端参数，随后由 DJ 生产 cursorRequest 成功向其 Unix socket 发送 listThreads；当前接口返回0条。Codex 的已有 Desktop socket 也由生产 openCodexChannel 完成 initialize，未新启 Agent、未发送模型输入；三个历史托管测试会话未取得活 owner，不能作为接收目标。两条握手只证明真实客户端通信，不证明模型投递或订阅闭环。私有证据为 cursor-native-141-proof.json 与 codex-native-142-proof.json。

允许显式创建空对话，仍受既有 session.create 授权、workspace_refs、实例epoch及幂等台账约束；创建不包含prompt，不自动send/register/subscribe。新增前置能力检查：没有原生create方法或session_create支持时，接受业务动作前立即unsupported，避免留存无法执行的创建生命周期。build142的原生协议夹具集成用例44断言通过，覆盖未授权/非白名单工作区拒绝、Desktop创建unsupported和原有直发/订阅/回复；Agent spawn仍为0。首次build141验收因测试将主体标签字符串传给内部Core而unauthenticated，改用fixture主体对象后通过；业务源码未改，原失败保留。Cursor原生Bridge目前仅列举/发送，创建接口尚待接入，不能把用户许可当作客户端能力已实现。

Cursor受限创建连接器已实现并生成VSIX，尚未安装或启用。控制业务由Eliscript实现，原生扩展仅作薄胶水；默认关闭、仅信任的本地单根工作区，逐请求复核workspaceRef/目录/信任/启用状态。固定原生命令只建空对话，不传prompt或模型配置、不提交输入；先同步持久化issued台账，再调用命令，同键重放、失败/重启后lookup均不重建。只有既有Bridge在相同epoch/window读回固定ID才ready，否则unknown。创建socket、认证与台账有界且私有，不改变DJ的无AI定位。

build148集中验证完成：T01.desktop-relay.integration通过（68断言，含真实UDS控制服务与原生命令夹具、原有投递/回复）；T38.desktop-runtime.unit通过（25断言，含稳定创建ID及默认不启用）。VSIX为40228字节，SHA256为1aa8be7d999e3202d2abda9373c9915de329e0eebc994d4f4394830b0ee12d76；五项包文件摘要、ZIP/XML结构与Node入口加载验证通过，未安装、未声称真实Cursor创建完成。build143的工具异步入口失败、144的缺失编译入口及其后必要工具恢复均保留；145的66断言通过后补齐工作区重检、台账同步及写读容量一致边界，147/148各项成功记录均留存。当前等待用户决定客户端扩展安装/专用工作区启用，目标明确不自动部署；不重跑性能或全工具矩阵。

以下托管 Codex 的真实 Lark/MCP 回复是历史协议与平台证据，不能作为已有客户端接入的完成证明。CLI/ACP 子进程 stdio 验收不满足当前接入要求。


同时修复托管实例恢复：历史 stopped 记录及与实例/epoch/launch token 精确匹配的原生 stopped 生命周期证据保留终态，不重新变为 stopping，也不释放后来占用同 profile 的 slot。build134 的公开 CLI 业务与恢复用例通过（19断言），build135 的关键证据边界保护通过（9断言）；实际故障库在135上重启后两个实例均为 stopped，服务正常退出且未再次调用模型。当前无调试服务或模型任务留在后台。build136 已生成更新后的目录包，复制到私有配置根的 artifacts/build136；37份文件摘要一致，仓库外 CLI 帮助与库入口导入通过，不代表自动部署或完整首期验收。完整 S3 和 Cursor 认证仍开放。

## 历史施工与验证记录（以下状态以当时冻结版本为准）

CLI 接线已完成业务实现及必要本地验证：Codex App Server / Cursor ACP 托管端口、JSON-RPC 有界传输、配置与 Core 装配已接通。build131 的公开实例启动、会话创建、直发、订阅、原会话回复与归属内停止集成用例通过（15断言，含显式 ACP 认证）；build129 的权限不自动批准及 EOF unknown 保护用例通过（6断言），该用例与 JSON-RPC 产物到131字节未变。真实 Codex CLI 已完成专用实例启动、会话创建、唯一标记提交、模型响应读回、idle 确认及正常停止。真实 Cursor 原安装为错误 CPU 架构；独立官方 arm64 运行时已完成握手，但显式认证在15秒截止前未完成，未创建真实会话。所有本轮原生进程已退出并完成受控清理。专用机器人订阅到真实模型及模型显式调用回复接口仍未通过，不以本地协议对端或单独两段连通代替闭环证据。

当前正式接线使用 key/secret/token，不依赖桌面。Lark/飞书 bot HTTPS 业务接线已完成；build123 的密钥接口集成验收通过（1例、14断言），build124 的消息解析保护性单测通过（1例、4断言），两版生产产物字节相同。真实国际版专用机器人已通过操作员本人身份发送、DJ 密钥轮询入库、无订阅时零 Agent 投递、公共 message.send 发回消息及原平台读回；临时调试服务已正常停止并完成清理。订阅后的真实 Agent 转发与 Codex/Cursor CLI/API 闭环仍开放。下方桌面和 user OAuth 条目为历史组件证据，不是当前交付路径。

历史组件段：Codex/Cursor 原生桌面接线已完成生产实现、原生协议夹具的集成功能验收与关键状态保护性单测。新增 desktop-transport.eli / desktop.eli；Core、配置、恢复、信封编码和默认使用说明均已接通。build121 已通过双工具注册、直发、订阅转发、显式原话题回复及 T31 提交切点定向验收；unit49 在此前未变状态分类实现上完整 80/80 通过。真实 Codex 只读探测确认实例 ready、当前会话 busy 且有活接收端，没有发送模型输入。Cursor 尚无可用桥接 manifest，启用及正常重启仍待用户答复。两条真实模型/IM 链路不报告已通过。

固定搭档本次独立只读审核只指出一项阻断：消息超过页预算时可能形成无法推进的空页。已修正为明确 desktop_history_limit，原集成用例在 build121 上 1/1 通过（27 断言），关键状态定向单测 1/1 通过；不再增加审核轮次或全工具矩阵。

交付增量：源码已签名提交并推送 4f5cf5f。build122 的目录包已生成并复制到配置根的 artifacts 子目录；37 份包内文件摘要全部匹配，在仓库外 cwd 执行 CLI 帮助成功，ESM createCore 与 61 项操作目录可加载、MCP 模块可导入。不含 node_modules、编译器、测试或实际凭据；这只证明目录包入口可用，不证明服务/IM/模型验收。首次私有检查把 Map 当普通对象计数而失败，修正检查后通过，原始失败保留。默认 ~/.dj 的私有操作员配置已由生产 loadConfig 校验，未启动服务；Lark 专用 profile 的应用匹配且 identity=user、verified=true，token 状态 needs_refresh，尚未配置获准 watch。

当前主线（2026-10-26 用户调整）：先完成 Codex、Cursor 的实际业务接线与可用交付，包括会话发现/精确目标、注册、直发、订阅转发和原话题回复。测试服务于这条业务链，只复用/补充必要验证；不逐个 AI 工具重复完整验收，不继续新增性能优化批次。RC1–RC3 仅完成过 A 设计，现已延后，未进入 B/C。

OpenCode/Pi 与其他工具的专项验收放到交付之后，保留已有源码和证据；旧 12/20、各批次性能失败与组件通过均属原范围证据，不代表当前 Codex/Cursor 已跑通。当前编译基线为 build122；相对 build121 只更新 packaging/runtime.md，全部 588 份编译产物字节未变，沿用已通过的受影响范围验收，新的交付范围见[发布范围](release-scope.md#当前交付优先级2026-10-26-用户调整)，唯一下一步见 TODO 顶部。下方历史记录中的“补齐所有控制器/先做 RC/全工具矩阵”不再是当前执行指令。

历史组件记录：PO1–PO3本地D与固定搭档179/180审核已闭环。build115原字节manifest 3780ac21ae0810ca196b1a93ceeeb4673854ecce792e6719f55dbb98e690b447，130输入/578输出；unit48完整79/79（1182断言）、integration68新增PO 1/1（98断言），连同未变范围形成953项组合覆盖（79+849+25），不是单次全量。59业务源码、生产与性能产物未变。真实Pi日志/会话未读取，未启动Pi或模型；默认6个driver有源码入口、9个仍占位，全部未授权且未装配。该轮原后续计划已被当前交付优先级替代，正式验收仍12/20，S3和最终签名交付未完成。

吞吐最新复核：冻结build115单独运行performance28的T27.route-load，仍失败internal_deadline。负载wall70082.022ms、5582事件、42614已接受投递，unaccepted9893/routing396/claims0；remaining10289是混合单位，不是尚缺投递条数。tick186、skip185、error0、max_concurrent_ticks1、退出无在途；setup31944.328417ms、exercise70084.608917ms及runner118495.093042ms分别保留，不混作吞吐窗口。未复跑其余三项未变性能，不把本轮单项称作整组3/4。原FULL/6000/60000/100EPS门槛不变，无主机因果或跨轮净收益归因。

诊断63仅在相同NULL-owner数据的私有SQLite副本中比较完整/部分deliveries_owner索引；8192行的WAL20571192→20056192字节，INSERT中位142.9091045ms→143.912625ms，未证明稳定INSERT或全服务收益，不采用生产。诊断64在私有编译图完成25s四轮ABBA的1/2/2/1微任务跳数对照；平均每批28.5179/28.3386/28.6149/28.7969项，未证明额外微任务提高合批/吞吐，也不采用。四轮预期exit79只是未完成诊断，非验收；自有测试数据已在各guard终态后核实无占用并清理，原始摘要/日志/私有编译图保留，130输入/578产物零漂移。下一候选仅在A阶段讨论同岗位回执与下一新claim是否可同提交，尚无新实现或新测试。

最新：LI1–LI3 已完成本地 D。build109 manifest eae9bdbf0eed107ac89f6f94a24a1372634c58323464d58b14d88db008e62595，124输入/562输出零漂移，59业务与生产/性能未变。unit45完整78/78、integration65 LI 1/1通过；连同未变范围形成951项组合功能覆盖，非单次全量。固定搭档177发现的chat非选中话题噪声误拒已修复，178确认精确变更和必需断言通过；真实Lark用户API/chat/topic/E2E仍未运行。总阶段S0–S3为3/4完成，正式验收12/20；完整吞吐、真实资源/其他控制器与最终签名交付保持开放。

当前增量：O1–O3当前build106（manifest 1a98c057e76c38ad7a27ee250ce28b70c4fd9ad7668bcfd9c5f981ee5f0306d3，118输入/546输出，59业务未改）：OpenCode只读观察核心/保护CLI及两专用默认未授权入口已写齐。unit43完整77/77、integration62新增O一项1/1通过；配合未变范围的旧846 integration与25 system形成949组合覆盖，非106单次全量。独立174未发现工具确定缺陷，175确认五组必需断言补齐、无新确定缺陷；1025拒绝是16页/1024行组合边界，不称独立row-counter分支。真实OpenCode E2E尚未运行，native_instance_id明确为授权endpoint标签而非HTTP进程证明；Pi、M完整短进程覆盖、其他控制器、真实资源与100EPS/最终签名交付均开放。


当前增量：G1–G2 D已收齐。build94原字节manifest 50b2d0bab09d32aa7c46ed7a9e9bb17b95fd041d57bb293dcf747f23a8e5dd77，114输入/526产物/59业务无漂移。G-A1..A6功能与固定独立搭档审核成立；945为build93 unit36的75项、integration56其余844项、system29的25项，加build94 integration57定向T40 1项的组合覆盖，非单次845/845。performance27四项独立进程串行终态为3/4，全部cleanup_complete=true。route-load为status=failed、schedule_completed=false、internal_deadline；负载wall70011.342125ms，摄取4549事件、接受34110条投递、unaccepted9872、routing183、claims0，remaining10055为混合单位，非10055条投递；tick144、skip143、error0、最大并发tick1、退出无在途tick。大扇出10000候选/1000投递、173turn、exercise2693.264375ms、候选CPU p95 2.813ms；目录10万metadata/转发500、exercise53758.796292ms；正文配额534962176bytes、capacity_exceeded=true、转发84/11轮。完整100EPS、真实256MiB/IM/Agent/Skill及最终签名保持开放；不作跨轮净收益或主机因果归因。 原始构建/集成失败及B160/162部分交回事实保留；root完成全部B缺项后才进入C/D。准确终态见本地root-build94-functional-terminal.json与root-build94-performance27-terminal.json。

更新：2026-10-25。当前为 **S3：全量实现之后的集中整合与验收**。I01–I30、S1/S2 已按“源码写齐、实现待验”记录；唯一施工/验收清单见 [TODO](../TODO.md)。已提交基线为 c1eb7b1，签名有效，master 已推送 origin/master；当前大量实现与修复仍在工作区，必须保留，不能当作已验收交付。

DJ 是无 AI 的确定性消息组件。首期保留 Eliscript→ESM/Bun、SQLite WAL/FULL、单 owner、UDS API、薄 CLI/MCP、可嵌入核心和 Skill；Lark 国际版 user / Telegram bot × OpenCode/Pi。统一查询、字面搜索、免订阅直发、显式启停/空会话创建、原话题订阅回复均在范围内；默认根 `~/.dj`。完整目标见 [Goal](construction/goal.md)。

## 最新验证结果与下一步

磁盘阻塞已解除：获准清理本项目无需提交的测试/临时数据后，已删除所有无占用的旧测试fixture（13057个目录、约39.6GiB已分配文件空间），保留源码、当前构建和全部验收证据，Git状态未变。目录负载按build87原冻结输入重新运行，首次磁盘中断日志仍保留；真实控制器/profile与资源装配、100EPS及最终签名交付继续开放。

Y批前最后冻结构建为build87，原字节manifest SHA256为8593865fc76ed34bca789624e084de744a8829b3e74ce97737fb3400a21fcf0c；Y批前114项输入/526项输出逐项匹配，59份业务仍匹配repair81；Y批测试改动后的绑定快照待C完成后重新冻结。build84完整功能运行后的测试修正仅位于T31.cancel-before-submitting新增N/V段；build87定向integration52通过（771 expect、guard正常退出且清理完成）。独立审核指出的drain期间tick成功Result、seal窗口无fault/native动作显式断言均已补齐并通过；旧源码来自保留的build84 source map，其map及sourcesContent摘要分别匹配原manifest输出/输入，不称作原字节源码备份。

performance23四项独立受控进程已收齐，3/4通过。route-load负载wall70465.398375ms，events4420、native_inputs33442、unaccepted9754、routing123、claims0、tick_error_count0，内部截止失败；remaining9877为不同单位的混合计数，不将未完成routing_work全部乘10。大扇出通过；正文配额body_and_index_bytes=534962176、capacity_exceeded=true、转发84条、11轮refresh通过。目录负载首次因磁盘满中断并保留原日志；获准清理测试数据后，invocation02完成10万metadata、转发500条，实际exercise72663.808792ms、verify总wall75039.755833ms、guard正常退出且清理完成。其余三项不能抵销route-load失败，不作跨轮净收益或主机因果推算；完整吞吐与真实资源等仍开放。

私有诊断42绑定build87复制图，只有五份私有计量接线变化，共享输入/产物未变。实际窗口26067.004125ms，1060事件、6716已接受、3724 ready、routing done1044/ready16、claims0；33个完整tick均两波，tick中位748.44375ms。SQL方法/迭代器15923.764798ms、query查找825.549881ms；COMMIT1843次/2904.663160ms、10行deliveries批插1044次/1779.828645ms、delivery进度更新13432次/1340.672360ms。异步阶段含交错工作，不与SQL相加；第二组未传可选progress，不能用非空progress合计当全部匹配事件。诊断预期exit79且清理完成，不是容量通过。首次缺少显式./文件前缀导致Bun只做过滤、无测试匹配，原调用日志保留。当前仅围绕实测成本讨论下一批设计，不重开已闭环N/V，也不调低完整门槛。

清理测试数据后的同build87定向performance24仍失败：负载70317.786583ms、events3091、accepted22803、unaccepted8107、routing/claims均0，tick98、skip96、tick_error0、最大并发tick1、退出无在途tick；guard0447bbccd891477480ecab054e2b8687正常退出且回收完成。114项输入/526项输出仍零漂移；其余三项performance23通过结果沿用，完整性能仍3/4，不把清理前后的计数差作净收益或因果证明。原performance23失败保留。

补充组件诊断43/44均未改变生产输入：43在保留FK、索引、STRICT与FULL的16000行样本ABBA对照中，拆除两表payload重复typed字段使WAL从60428072降至54400512字节，但含codec的写入墙钟与基线重叠，且需要新的原始payload兼容设计，因此不采纳。44保留完整payload，改用json_each载荷提取typed列；两轮INSERT方法耗时均高于两个原参数绑定轮，不采纳。两者仅是旧记录样本/最小父表的组件实验，不能外推完整服务EPS。diagnostic40已计量同步序列化与快照压缩，本轮不重复相同探针。

有界系统调用诊断45保持build87共享输入/输出不变：自有Bun子进程只加载私有元数据探针，不访问SQLite内部句柄。完整后一次窗口25140.512625ms，1580事件/10839已接受；捕获WAL读取234536次、960659456字节/736.445ms，fsync2788次/499.456ms，数据库读取2466次/9.967ms。实际WAL增长但写出调用未被捕获，因此符号覆盖仍不完整，不能据此排除I/O瓶颈，也不能把读取次数当sqlite3_db_status cache miss或设备读数；这些耗时与SQL/阶段重叠不相加。首次编译不支持独立fdatasync符号、首次仅部分libc覆盖均保留，两个运行均预期exit79且清理完成，不是容量通过。当前回执+下一claim联合提交候选经独立源码讨论后未采纳：会改变next-claim SQL异常时receipt的回滚窗口；不增加复杂handoff或擅改失败契约。

公开VFS诊断46已覆盖先前遗漏的写出边界：25229.168833ms窗口，2126事件/15352已接受，原系统SQLite source_id一致且VFS转发flags/结果不变；主WAL xWrite约1.49秒、xSync约0.74秒，另有约1.31GB临时写入/2.92秒。组件47按SUBJOURNAL标志分类并对同样数据作ABBA，temp_store=2消除约191.75MB子日志写入，而WAL字节/同步数/FK/行内容保持；真实服务私有ABBA48–51亦分别观察到默认约1.05/1.53GB子日志写入与两次内存模式零子日志文件写入。四轮accepted依次12116/18222/22051/19476，有重叠，不作净EPS或内存百分比归因；SQLite allocator状态0/0视为不可用。候选Y契约仅在openStore自有连接设MEMORY并readback，不改FULL/主WAL、回滚或任何配额。所有短窗均预期exit79且清理完成，不是容量验收，256MiB真实资源与100EPS保持开放。

当前L1–L3功能验收版本为build75：原字节manifest SHA256为57e421d3b0beb4d0ea3f7591cbf5c5c066f6a813f52b6f6b41fc9d8b250f73c6，114项输入/526项产物逐项核对无漂移，59份业务保持repair70。unit31完整75/75、integration46完整845/845、system24完整25/25，共945/945功能通过；无用例缺失/重复，三个guard均exit0且cleanup_complete=true。先前build70构建失败及71–74功能失败均保留，未改写为首轮通过。最后两例测试期望已按现有Result结构、实际批SQL与同tick busy探测语义对齐；没有放宽生产约束。L-A1–L-A7已取得功能证据，本地A01/A05/A11/A12/A14/A19恢复；四项独立performance22已全部终态且清理完成：大扇出、十万目录与正文配额通过，route-load失败。负载wall70476.820166ms、events5955、native_inputs32088，未接受1182、routing2628、claims0；remaining3810为混合单位，距60000投递目标尚差27912条（含45个未摄取事件对应450条、2628个未物化事件对应26280条及已物化未接受1182条）。该构成不证明单轮路由配额是根因，也不作跨轮净收益归因。完整吞吐、真实资源、Skill采用及最终签名交付保持开放；私有诊断38已完成并清理：25.3717秒窗口1811事件、915已路由、7898已接受、claims0；10行投递批插915次/1399.31ms，SQL方法/迭代器14.91秒、查询查找0.82秒，57个完整tick中位409.96ms。异步阶段含交错工作，不能与SQL相加，也不替代容量门禁。诊断39亦已完成并清理：25.1676秒窗口，configuredPrincipal调用311587次/累计1129.08ms（约窗口4.5%）；进程CPU为user19.904263秒/system6.514616秒，含Bun后台线程，不能解释为JS线程或SQLite独占成本。本轮不把主体查找缓存选作首要修复；仍待按剩余实测成本收敛下一批范围，当前未选择新业务改动，共享输入保持冻结。

J1–J3最近完成验证的冻结版本为build69：原始manifest SHA256为7dfcd13bee0d95c3f7dd4405d229fd1fedd084b99e547b9b14d617b1d335fd87，当时114项输入/526项产物零漂移，59份业务源码精确匹配repair65；此证据不直接适用于下述新L输入。unit26为75/75、system19为25/25，integration38其余844项加integration41的T31定向通过组合覆盖845项，共945项功能。66→68仅修正T31.cancel-before-submitting的drain/owner恢复；68→69将恢复循环显式限制为至多16次并硬断言stopped，异主注入绑定自有service_id/owner_token、断言changes=1并精确恢复租约。两段逆向范围证明均准确恢复前版源摘要，其他用例/共享函数及非测试产物字节一致。原始失败及中间构建完整保留。

performance21四项独立进程已全部终态并完成清理：大扇出、十万目录、正文配额通过，route-load失败。其负载窗口为70122.717208ms（摄取60025.452333ms、排空10097.264875ms），6000事件全部入库，50006条投递已接受；routing_work为done=5118/ready=882，deliveries为accepted=50006/ready=1174，claims=0。remaining=2056是882条routing_work与1174条delivery的混合计数；距60000条已接受投递实际尚差9994条，其中8820条尚待物化。114项输入与全部performance产物在68→69间字节未变，可沿用该性能证据；3/4不等于完整性能验收，不作跨轮净提速归因。

私有诊断37基于build69复制图计量25.052秒：2506事件、2267事件完成路由、21443条已接受投递，另有1227条ready投递和239条ready routing_work，claims=0。160个完整tick中159个执行两轮；SQL方法/迭代器合计16.07秒，query/prepare查找0.78秒，COMMIT为5188次/2.54秒。匹配与两轮派发均仍有显著成本，不能把enqueueWrite项数等同于独立COMMIT次数；异步phase墙钟含交错工作，不与SQL计时相加。该诊断预期exit79并完成清理，共享输入/产物无漂移，仅用于选择下一批修复，不替代正式容量验收。

U1–U3最近完整收齐的冻结版本为build64：59份业务文件精确匹配repair62，原始manifest SHA256为1f742eb0b0fa6c5eb35d842ad5dd485244d23dad651d9efd775e213e3b6307f9，114项输入/526项产物逐项核对零漂移。unit24完整75/75、system18完整25/25通过；integration36原始844/845加新增T40.mixed-entity-ids的integration37定向1/1，组合覆盖845项。62→64仅identity/storage两份测试修正，旧844项集成用例和共享函数字节未变，全部非测试产物未变；945项功能覆盖成立，不改写首次失败记录。

首次build62的unit23为74/75、integration36为844/845、system17为25/25，失败仅新增两例的夹具/断言：UUID样本末组超长、毫秒hex期望错误，以及误读未公开settled字段。修正后使用合法独立固定向量和原生settled观察对应的公共receipts验证，业务校验与投影不放宽。U-A1/U-A2/U-A3已取得功能证据，整体U-A4仍因完整吞吐未达标而开放。

performance20四项逐例独立进程串行收齐：大扇出、十万目录、正文配额通过，route-load在70011.61ms负载窗口内部截止失败，2657事件、19187已接受输入，未接受7243、routing14、claims0；全部guard清理完成。整例116776.24ms包括fixture准备，不能与负载窗口混用。6000事件/60000已接受输入/FULL/端到端100事件每秒门槛不变，3/4不等于完整性能验收。

私有诊断35只在build64副本增加SQL/轮次计量：25.708秒、1251事件/8243已接受/4267 ready，routing全部done、claims0；79轮tick的wall中位281.53ms、p95为548.00ms。每tick新增投递中位160，实际原生输入增量中位及最大128，route岗位中位及最大32。SQL方法/迭代器15.51秒、COMMIT共2248次/2.40秒，查询查找0.84秒；异步phase不可与SQL相加。两项状态更新计数探针未正确展开数组绑定，明确不可用，不把零值当业务事实。诊断36仅在私有副本原setup后短时JSC采样，11293条样本仍以SQLite读写为主要热点，不支持把通用序列化改造选为本批主要修复。两个诊断均受控退出并清理，不是容量验收。

J1–J3已按完整契约/施工手册实现并取得J-A1–J-A5功能证据：第一轮有已提交进展且可能有其他候选，才允许一次宏任务后重检owner/state/storage并进入第二轮；每轮32/16、全局64不变，同tick对route/outbound去重且每route仍四步，跨tick角色优先级只翻转一次。该契约替代旧每tick单轮配额。repair65保存59份源码，仅runtime相对repair62变化；build69冻结114项输入，945项功能组合覆盖成立。完整性能仍未通过，J整体验收保持开放。下一批L1–L3的A契约/五文件施工手册已定稿，B四文件已全部交回且未运行；C五文件已一次写齐，当前业务快照repair70与root-freeze70绑定59份业务源码/114项输入，相对build69仅五份业务与两份integration测试输入变化。全量实现后词法深度及diff检查通过；D首轮build70的生产模块已编译，整体构建在storage测试1565行try/finally层级处失败（guard189944a8bce442679f907984e849910d，exit1、清理完成）。随后仅storage测试修正并重冻为build71，整体构建成功（guard cc9d1aa1a0c1414a9879f6bc13a609f3，exit0、清理完成）。原字节manifest SHA256为72891319808c059cfd15b6e7f8479ecaaa0065ad74c292808b2ebddbc08e76e9，114输入/526产物已逐项核对无漂移，59份业务仍匹配repair70；第一轮功能已收齐：unit27为75/75、system20为25/25，integration42为842/845且845项均有观察、无缺失/重复；三项失败为T40.write-batch-commit、T40.write-batch-isolation与T12.update-cutover。三个guard均已清理，原始失败保留；已交测试方合并定位/修正夹具冲突，尚未开始本批性能验收，不把构建或942项局部通过当完整验收。范围仅严格批插deliveries、单事件有界缓冲及两处派发窄列读取，不加routeEvents轮次、不缓存授权结论、不跳过真实查重。

L后续测试夹具修正后build72成功，原字节manifest SHA256为252184e594db50b1458f28a1685f6374e9936f40f32c3d32e13be85a9fbb70ba；114输入/526产物逐项匹配，59份业务保持repair70。71→72仅storage的T40.write-batch-commit/isolation与delivery的T12.update-cutover三个用例变化，剔除这三个完整用例后其他源码逐字节一致。unit28为75/75、system21为25/25，完整integration43为843/845，全部845项有记录且无缺失/重复；剩余失败是T40.write-batch-commit与T12.update-cutover，原始失败与三个guard清理证据均保留。正向批次复用route/seq以及第二recipient目标约束仍待测试侧修正；后续按实际改动范围定向复验，本批performance尚未开始，当前943/945不算完整功能验收。随后两项用例内部继续修正并完成build73（manifest SHA256为fdc303fa36f221d2c6cd6c1a49e2147d9d0a8c9c8fc062bba5be25b8ce9e7ea5）；114输入/526输出当前摘要匹配，59业务仍为repair70。72→73仅T40.write-batch-commit与T12.update-cutover两个完整用例内部变化，其他源码及全部非测试产物字节一致，可沿用843项已通过集成结果，build73的unit29为75/75、system22为25/25，完整integration44仍为843/845；三个guard均已清理。T12已推进至SQL计数探针误匹配旧前缀，实际多行幂等SQL为INSERT INTO ... ON CONFLICT；T40已推进至后续L2事务块，尚须定位其被storage_unavailable包装的原始异常。两项未通过，性能仍不启动；后续按真实影响定向复验。随后build74成功（manifest SHA256为44c39f23f5f2335382c3f65b9af9d2228daea204e860e7d3b254d863136841b1），114输入/526输出匹配，业务仍repair70，仍仅上述两用例内部变化。私有build73副本中的有界异常诊断已定位T40两处陈旧断言：created上限错误文案不符，以及capacity完整Result与缺元数据对象的全等比较；只在副本中对齐后该完整用例通过，诊断均已清理，不计为正式验收。须在正式冻结测试中修正并定向复验后再进入性能。build74三层终态为unit30 75/75、system23 25/25、integration45 843/845，全部guard已清理，尚未开始性能。T12修正SQL探针后推进至busy状态期望：同tick路由后已执行busy探测，两条新队首应为deferred/rev3；私有副本只对齐四处state/revision期望后完整T12的76条断言通过，仍须正式冻结复验。

U1–U3仅九类纯实体主键采用无counter的UUIDv7，其他控制/幂等/受限句柄保持v4。宿主时钟越界/非整数拒绝，不静默夹紧；静态混合主键分页保留，并发新增在当前cursor之前的记录须新查询，不宣称更强快照保证。U批最近验证产物为build64；J批源码/测试已按上述repair65冻结交D，不能把旧产物的通过结论直接套用到新输入。

## 历史构建与修复依据（不代表当前版本）

默认页缓存对照及WITHOUT ROWID组件诊断不足以支持改生产参数/布局，均保持原状。实体ID私有诊断显示值得正式实现，但仍有持久积压，不作为完整吞吐通过或净收益证明。binding复用仅保留备忘，没有扩大本批范围。

K1–K3五份业务文件已全部实现，58份源码冻结为repair-59；最终功能验证基于build61的113份输入/522项产物，已逐项核对。unit21为74/74、system15为25/25；完整integration34原始840/844记录保留，storage四例纠正后integration35四项定向全部通过，组合覆盖844项成立。59→61仅storage测试四个用例内部修正，其他用例、共享函数和所有非测试产物字节一致，不称integration34单轮全绿。

新增测试修正分别为：批读失败调用不应计为成功调用且仍须零SQL；no_match文本不能包含匹配词；大贡献fixture使用独立事件；EXPLAIN语句显式finalize；恢复fixture的事务回调须返回Result。索引迁移在显式释放查询语句后通过，原SQLITE_LOCKED与私有诊断25/26均保留，不把未逐个定位的活动语句说成已证具体锁源。业务源码未因这些测试问题追加修改。

build61原始manifest SHA256为ad102a80c8a04c425e3efbf9644bd9a31c3b97a853bedcce5e4e938dc8b6c67c；另存改写built_at的派生回执与原始字节分别保存，不能混用摘要。当前943项功能覆盖完整；性能19四项逐例独立执行已全部终态，route-load在70168.89ms内部截止失败：3908事件、29366输入，持久未接受9714、routing/claims为0，259轮tick、无consumer错误或重入、退出无在途tick，guard清理完成。其余三项独立通过：大扇出负载阶段6905.00ms，十万目录52532.45ms且刷新中转发500条，正文配额拒绝成立且刷新中转发84条。四个guard全部cleanup_complete=true；不将部分计数当100事件/秒通过，不以主机快照解释全部差异。

本地A01–A05、A07–A09、A11/A12/A14/A19共12项恢复；K1–K3整体验收及完整S3保持开放。当前完整门禁为943项功能组合覆盖、性能3/4；剩余吞吐和真实资源验收均不能省略。以下build58表格与通过记录保留为历史，不能套用于当前源码。

W1–W3三文件业务实现已完成并独立审核，上一build58的113份输入/522项产物与58份repair-57业务源码逐项无漂移。unit20为74/74、system14为25/25；完整integration32为843/844，唯一T40失败因新增W2夹具复用已登记Agent的recipient，触发agents_recipient唯一索引。改用独立A2后，build58定向integration33的T40为1/1、332断言通过。57→58仅该用例两个身份字符串变化，其他用例/共享函数与所有非测试产物同摘要，组合覆盖844项成立；原始失败报告保留，不称integration32单轮全绿。

| 层次 | 最新日志 / run_id | 结果与适用边界 |
| --- | --- | --- |
| build | dj-build-all-58-invocation-01.log | 构建成功，manifest SHA256=394dd421a3e385bb9a311839f8783677c605bdd7c22af1993ae03aa746e68318；113输入/522产物零漂移，cleanup_complete=true |
| unit | dj-unit-20-invocation-01.log / 2026-10-24T12:02:48.526Z-ea052592-eb50-479c-8c2b-abfa655d3ec7 | 74/74，wall=566.65ms，cleanup_complete=true |
| integration | dj-integration-32-invocation-01.log 与 dj-integration-33-t40-commit-invocation-01.log | 完整843/844加T40定向1/1，组合覆盖844；定向run_id=2026-10-24T12:01:37.508Z-139c22da-1415-4c4a-8508-2f2da807c2c7，两次均cleanup_complete=true |
| system | dj-system-14-invocation-01.log / 2026-10-24T12:02:51.102Z-837b87d3-fadf-4ad9-9b3e-daa48e2ec340 | 25/25，wall=17537.68ms，cleanup_complete=true |
| performance | performance18四项独立进程终态收齐 | 3/4通过；T27.route-load在70081.35ms内部截止失败，2579事件/18701输入、持久未接受7089、routing/claims为0。大扇出、十万目录、正文配额通过，全部cleanup_complete=true |

build58曾恢复A01–A05、A07–A09、A11/A12/A14/A19共12项本地验收，A09由目录/配额性能补齐；当前K1–K3新源码待复验，W1–W3整体验收及完整S3仍开放。真实控制器实现/供应、原生观察入口与资源装配也仍未完成，见[真实验收准备](construction/real-preflight.md)。

performance18原始报告全部保留：route-load的run_id为2026-10-24T12:03:28.756Z-25da7782-53fb-4c33-ad1a-b05a97480036；large-fanout为2026-10-24T12:05:50.672Z-9e155312-644a-4ce3-a9b7-e473a76945f8（负载阶段8231.90ms）；catalog-load为2026-10-24T12:06:45.286Z-774a6e8e-82af-4d04-82dc-37909fffdc02（100000条、刷新中转发500条）；body-quota为2026-10-24T12:08:26.738Z-fbd547d3-d001-4322-87a6-67f8b76b1d47（配额拒绝成立、刷新中转发84条）。整例计时包含fixture，不能与负载阶段混用。外部负载快照和电量不证明具体限频或W1–W3净收益，不据此放宽门禁。

诊断27在build61私有图25.35秒中记录1645事件、11371已接受投递，SQL方法/迭代器18.32秒、COMMIT4.71秒；不等于完整吞吐验收。页缓存原生计数探针28因当前Bun禁止动态扩展加载而停止，没有换引擎。私有默认→32MiB→默认的三个短窗口为1645/11371、2031/14805、1824/12933（事件/已接受）；默认重复也有变化，不能据单次差异认定净收益或miss/spill原因，生产页缓存参数保持不变。后续仅做有界组件布局研究，未改共享源码或验收负载。

诊断23/24已在build58私有编译图完成并受控回收，共享源码/测试/产物摘要未变。23的25.81秒窗口中两表各4748次多行语句（每事件16+16+16+2行）已生效；SQL方法/迭代器合计17.36秒、COMMIT3.58秒，仍不能由减少语句数直接推断净收益。24读回实际cache_size=2000页、page_size=4096、cache_spill=20000；观察窗口内没有COMMIT前WAL文件长度增长，未取得事务内溢写证据。文件长度不等于SQLite内部spill计数，当前不调整数据库页缓存或驱动语句缓存。两次均提前有界退出，不能当吞吐验收。

以下为修复依据与历史，不构成当前吞吐通过：诊断22的25.63秒窗口内query/prepare查找598138次合计760.62ms，约3%，返回Statement身份约98.48%复用，不支持缓存调参。SQL方法及iterator.next合计16.98秒，其中COMMIT约3.43秒、贡献插入2.26秒、决定插入0.84秒、投递插入1.79秒；包装开销与环境差异不能当净提速，异步phase包含交错工作也不能与SQL相加。W1–W3已按单事件有界多行写入契约实现，FULL、授权新鲜度、容量及性能门槛保持。

build52/53、unit15、integration27/28、system10及四项performance16均已终态且cleanup_complete=true。当前943条功能用例覆盖来自完整轮次与T12定向修正；不改写原始失败报告。以下保留早期性能历史：performance14整组wall=550539.24ms、计量峰值1860124672字节。large-fanout、catalog-load、body-quota三项分别完成，但小型Bun1.4.4探针已证实超时后未清理的定时器可在下一用例期间继续触发，存在共享事件循环干扰风险；原T27实际持续DML时段仍未获独立证明，三项耗时不能作为无干扰性能基线。真实profile的deployment-resources用例未运行。

原T27库只读核查得到3850条done routing_work、38500条accepted delivery、claims=0，service_lease仍为ready；这不是6000事件/60000输入的完整验收，也未成功完成正常stop。最终文件mtime或退出时checkpoint不足以单独证明超时后持续写入的起止时间；机制探针不替代原运行的分时计数证据。

performance14时的旧T27每事件串行await ingest/tick，同一路由每轮仅有一条待派发消息，因而不会启用第二至第四条连续派发；真实main采用独立20ms调度。其后的容量驱动、取消和清理合同已在build51写齐并通过快速回归；保留6000/60000、FULL、10ms绝对输入日程、持久排空及100事件/秒端到端门槛。换驱动本身不算性能修复通过，私有独立producer诊断也不替代正式门禁。

固定Bun1.4.4 / SQLite3.54.0的只读诊断比较了空队列、10条活跃路由和9968条积压三种分布。旧JOIN、现EXISTS与活跃索引起始候选在18组keyset/limit探针中结果相同；现查询在积压下避免临时去重，稀疏时额外成本不足以解释整体超时。本轮不据此再改生产SQL，也不原样重跑失败性能用例。诊断是内存小数据模型，不是FULL磁盘吞吐验收。

上一完整T27结果为performance13：6000事件/60000输入与独立SQLite持久排空完成，但wall=154130.880083ms、actual=38.927955事件/秒，未达100。该结果属于修改前业务版本，不作为build49实测速率。performance12因监控写盘ENOSPC中断；历史失败、构建清单与采样证据全部保留。不得以主机负载快照归因全部波动或豁免门槛。

历史build48仅因新增测试let初始化依赖报错，改let*后build49成功；当时业务58份未变。上一基线共12项本地通过记录保留；当前验收勾与范围以本页最新结果及TODO为准。数据库1GiB活页预算与WAL实际磁盘分别记账，未降低容量保护或FULL持久性。

build50的独立T27采用10ms绝对producer与20ms非重入consumer，performance15在wall=70345.523208ms因internal_deadline失败：实际3643事件、27370输入，持久未接受9060、claims=0、routing=0；tick_count=243、tick_error_count=0。完整逐例终态已记录，cleanup_complete=true，区别于performance14缺终态的外部超时；部分计数不计算完整通过率。

整批测试源码写齐后的独立审核发现两处驱动缺口：consumer完成时的共享唤醒可提前结束producer绝对日程等待；完整排空报告在吞吐断言前固定写passed。build51已合批修正：正常consumer不再唤醒producer，producer重验绝对时刻；完整排空与门禁通过分别记录，吞吐不达标如实写failed。新增按时摄取回归，unit14为74/74（169断言，288.00ms），T31定向integration26为1/1（56断言，359.08ms），两项均cleanup_complete=true。原始失败保留，尚无新的正式吞吐通过证据。

诊断19复制build51的冻结编译图，仅在私有副本原始setup完成后采样35秒；没有修改共享dist或业务源码。采样结束时2112事件、15180条accepted、5940条ready、routing全部done、claims=0，主动exit79并cleanup_complete=true，不能作为6000/60000验收。23244个JSC样本中，repository插入SQL为4614、替换3109、读取3416；COMMIT为3658，其中合批flushWrites为3403、入口acceptEvent为229。当前证据指向匹配/投递阶段整体读写与合批提交成本，不支持把入口单事件提交认定为首要瓶颈。样本数量不是调用次数或精确墙钟占比；WAL文件约4.77GB也不等于活页用量。下一批修复依据具体重复写和查询收敛，FULL、配额及吞吐门槛不变。

DJ Skill已保留原生YAML并整理为MDP正文，原调用、幂等、unknown、权限与cutover边界保留。实际MDP SDK解析及最小Skill MDS模式通过，原生Skill校验器通过；这只证明正文结构与原生元数据格式，不证明客户端发现或实际采用，A20保持开放。系统Python缺PyYAML、uv默认解释器架构不兼容的校验尝试均保留，最终显式选择当前可执行解释器完成校验，未修改产品依赖。

Lark国际版user授权已验证成功；专用chat/thread、Telegram/两Agent授权资源与真实控制器仍缺。当前仓库的15个driver仍为缺失controller入口与全零摘要占位，控制器实现/供应和原生观察来源装配也属于未完成项，详见[真实验收准备](construction/real-preflight.md)，不能只归因为缺少凭据。真实19例、原生操作与四组合原话题回复、Skill实际采用、稳定物理资源未执行。完整目标、S3和最终签名交付继续开放。唯一施工/验收清单见TODO，不重开S1/S2或重复bootstrap。

## 实现范围与早期施工历史

所有生产分组及消费者已写齐：core/application/policy/storage、registry/catalog/search/refresh/lifecycle、subscriptions/ingestion/routing/delivery/messaging、两 IM/两 Agent 适配器、service 的配置/owner/恢复/调度/投影/主入口、library、CLI/MCP/API、Skill、构建与目录打包。准确声明和消费者见 [接口交接](construction/contracts.md#s2-声明与消费者交接)。实现存在不表示业务闭环已经通过。

S3 证据保存在项目私有 `.local/acceptance/20261023-s3-01/` 与 `20261023-s3-02/`，逐组 runner 另建 run_id 目录，绑定 manifest、JUnit、逐例分段计时及环境；原始失败不覆盖。

- 工具链实际读回 Bun 1.4.4、Darwin arm64、SQLite 3.54.0。固定 Eliscript 源 SHA 为 b1c7741365545d5a048079d64f863524cf7117e2；492项准备输入摘要 `6fd89941eba21098e56a31e2c9c7751894d582789709dd8b0c39fab6499022db`，重核零差异。隔离源 stage3 accepted/identical，313项固定点一致，安装 metadata 与回执对应。共享语言检出未改，不需要重复 bootstrap。
- 首轮逐模块编译6/88成功、82份首错；已经成批处理括号/声明作用域、宿主值、关键词值与控制流写法。后续逐模块89/89可编译，完整项目图也已成功构建。当时构建包含四生产、19测试、三工具入口，manifest 绑定109份输入、504份输出；新增 tools/runtime.eli 是工具图依赖。
- 固定编译器生成的运行包 shim 原先遮蔽 runtime/literals 导出；构建器现在把同固定隔离源的 runtime/platform ESM 安装到各自输出图，记录相对路径与身份并纳入输出摘要，未修改 npm 包或共享语言源码。
- unit 第05批 **73/73通过**，run_id=`2026-10-23T12:54:09.433Z-30d5a751-a075-4b21-870b-1985bb416230`，suite_complete=true，无缺失/重复。包含 T38.native-access.unit 的 null/false/0/空串/missing 回归。后续修复没有改变该组直接覆盖的纯模块；完整 A 条目仍需其他层证据。
- integration 第01–03批分别暴露导出缺失、工厂返回/局部作用域和仓库 revision 守卫缺陷，均保留失败报告。第03批实际835例、21通过、814失败；不能把该结果当成当前修复后的结果。
- T40.repository-revision.sqlite 的真实SQLite回归、T24.address-proof.integration 的 Core启动/精确地址/异步后撤权回归分别已通过。仓库内部省略 expected_revision 与显式 revision 守卫已区分；线上 null 仍按严格 schema 拒绝。
- integration 第04批因共用测试装配/接口清理问题中止，exit130，controlled-run cleanup_complete=true，整组未完成。没有将它补写为完整报告或通过。已修复9处 withCase 清理参数边界、协议用例缺少信封字段、字符串冒充正则、适配器目录数组被发现逻辑 shift、测试HTTP停止等待自身响应，以及过长测试socket路径。
- integration第05批遇同步查询不前进而中断，exit130、cleanup_complete=true；修复search的metadata/messages/done阶段边界与循环之后的唯一结果投影，同时修正transport AbortSignal被目录stat遮蔽。
- integration第06批完整执行836例，811通过、25失败，另2个未处理错误；run_id=`2026-10-23T13:31:36.075Z-c663168e-972f-42dd-bc48-aac6031894ca`，无缺失/重复。三入口61操作对照恢复通过，但跨主体status、少数协议/负向用例、备份及迟到请求仍需修复。cleanup_complete=true、计量峰值约605MiB。
- 后续修复非operator状态投影、SQLite私有备份目录、XOR参数向量、Lark失败后的本地查询、Telegram引用主体、原生事件等待和目录扫描阶段。integration第07批833/836通过；第08批835/836通过，零未处理错误。请求断线屏障已限定session.send，operation.get查回不会再次被拦；目录catalog.get条件体与done状态测试已修正。第09批完整集成 **836/836通过**，run_id=`2026-10-23T13:49:08.188Z-bb58ebe3-b7e3-402e-a103-58781a0e98cb`，suite_complete=true、无缺失/重复/未处理错误。
- 最新第18批完整图构建exit0；unit第06批73/73通过。system第03批 **25/25通过**，run_id=`2026-10-23T13:48:23.156Z-b6d02f5f-c42f-4fc8-b215-58e9f505944d`，suite_complete=true，无缺失/重复。实际覆盖生产standalone启动/唯一owner/新schema拒绝/停止、受控协议崩溃恢复、独立recipient重载、Pi安全排空，以及目录包复制到仓库外后的standalone+MCP运行。系统前两批失败保留，修复了测试凭据重生、陈旧socket、托管peer身份、复制目标和stdin装配。不是实际厂商/model/IM验收。

- 性能第01批中断：两个路由用例在配置准备失败；十万目录在372秒仍未完成，暴露逐条COUNT全目录的增长成本与测试微任务循环未让出计时器。exit130、cleanup_complete=true，整组未完成，不能记为通过或完整失败计数。
- 已补事务局部CatalogQuota，一批读一次实际计数，写成功才增加、回滚丢弃，保留十万上限；真实SQLite的T40.metadata-quota-rollback.sqlite已通过。配置principal上限4096，容纳1000接收者及其他主体；负载规模不变。新增回归后当前integration必需数为840。此前836集成/25系统是本次性能修复之前的证据，须复验受影响范围。

## 尚未取得的验收

历史build58的12项本地验收证据保留；当前K1–K3源码待集中复验。A06/A10/A13/A15–A18/A20还需真实资源或完整吞吐与交付证据。目录包曾验证独立启动，未安装Skill或系统服务，未部署。

真实组的 `config/acceptance.example.json` 授权默认false，必须核实当前受保护profile、外部控制/观察器源码摘要及测试资源归属。Lark user OAuth现已完成并验证；尚无真实IM外发或原生Agent启动验收。专用两IM/两Agent资源、原生回复ID/启动事实/Skill采用与macOS资源观察仍无真实运行证据，影响A15/A16/A20；不得用受控协议对端或JSON自报替代。

## 下一执行起点

当前业务源码58份冻结为repair-59，K1–K3五文件与全部接线已实现，root-freeze-59保存当前113项绑定输入。测试方四份交接文件摘要已核收，源码/测试在集中验证期间保持冻结。下一步独立审核、scope all一次构建、功能回归及4项逐case隔离性能验收；不继承build58为新代码通过，不实施没有证据支持的缓存调参。

performance15与16之间同时改变了业务实现和绝对日程驱动，原始计数差不能归因为R1–R5独立净提速。160条匹配产出与128条连续派发是饱和单tick上限，并非正常100事件/秒下必然失配；实际tick阶段和提交次数仍需计量。私有诊断不作为正式验收，不改FULL、6000/60000、容量或100事件/秒门槛。

Graph未单独索引DJ，父目录旧索引对本批路径亦无覆盖，相关调用核对使用定点源码读取和直接调用点搜索；不把图结果当成完整依赖证据。真实IM/Agent授权资源与控制器缺口继续只影响对应真实闭环，不重开S1/S2，不重复bootstrap。

## S3-02 集中验收历史

性能第02批完整执行四个本地用例，全部失败；第03批路由超过预算后中断，exit130、cleanup_complete=true。已修复fixture新增主体凭据、原生正文页大小、capacity布尔判定，并添加schema-1幂等live部分索引和精确表名约束的dbstat统计。十万条、6000事件、1000目标、10000订阅及512MiB配额不变。

300事件私有诊断生成router-standalone.cpuprofile，但其装配有后续ingest拒绝，不能用来证明持续吞吐或完整负载。随后直接采样原始T27路由用例，28207个JSC样本中11624个进入delivery_reconcile的pendingRows查询；它才是当前热路径定位依据，45秒诊断主动结束，不作为验收。实际旧负载数据库无结果查询约1.4秒，修复后查询计划使用部分索引，一次约0.04毫秒；这是单次查询诊断，仍需整例验证。

空事件页且cursor不变的观察现零行写，变化时持久化一次，并在事务内重检旧cursor；实际SQLite的T16.observation-checkpoint.sqlite回归通过。移除没有查询消费者的metadata FTS重复写，真实SQLite的T47.metadata-index-boundary.sqlite证明标题/正文搜索结果保留。真实fixture的client读取复用生产loadClientProfile解析相对路径与私有文件。

性能第04批已结束：框架报告large-fanout及body-quota通过，route-load和catalog-load超时；runner缺route逐例记录，suite_complete=false，不能记为完整通过。十万目录修复后的第05次单例在25.06秒通过，run_id=2026-10-23T14:47:40.711Z-2fed4c02-8920-4017-a6a2-a301816a9047。

三个reconcile请求队列及accepted未排空观察队列已增加固定谓词部分索引，schema-1幂等补建；T40.pending-work-indexes.sqlite第02次通过，覆盖查询计划、旧库补建、keyset及标志变更。第01次暴露SQLite选择原state索引，已用包含状态/排空表达式的观察索引修复，失败记录保留。

路由第05次框架虽报通过，但事后实际SQLite只有4616事件，循环没有检查ingest失败，故明确撤销它的负载验收效力。第06次加严为逐条成功和60000次真实peer输入，实际以capacity_exceeded失败，证明容量保护生效，但完整负载仍不达标。没有提高1GiB/64MiB预留上限或削减语料。

新attempt以有界无损压缩的envelope_snapshot保存冻结信封，并引用不可变原binding_id，核对/观察不转用route当前绑定；兼容旧内嵌binding。unit第08批74/74通过，run_id=2026-10-23T15:06:31.735Z-f87c2576-36ac-4f9f-831e-ad08febdd27c，包含压缩/完整性/解压上限回归。integration第10批840/840通过，run_id=2026-10-23T15:10:30.658Z-dfc63ace-2d2c-4ffc-b173-fe1ee584fe85；system第04批25/25通过，run_id=2026-10-23T15:11:54.027Z-d9ffd799-7345-4921-b7b0-45504e95c8aa；均无缺失/重复/未处理错误，cleanup_complete=true。

性能第07批完整收齐四项：large-fanout 9.57秒、catalog-load 66.76秒、body-quota 47.16秒通过；route-load已实际入库6000事件、数据库约867MiB，但最后一条仍ready（59999次输入），故失败。run_id=2026-10-23T15:12:03.452Z-6073d359-1e95-401e-b961-87f8b37c58f6，四项都有逐例记录，suite_complete=false，cleanup_complete=true。生产容量问题已缓解，但必须在停源后有界排空并保留60000精确断言，不能降低计数。

第30批完整图构建exit0，110份输入、510份输出；build-30-manifest.json已私有保存。仅路由测试补10秒有界排空和实际吞吐字段，生产代码与已过本地组一致。路由第08次在300秒截止时实际只有2784事件，run_id=2026-10-23T15:18:19.598Z-351b3469-f07c-4c19-adc9-79008e207c10；runner缺逐例结束记录、suite_complete=false，cleanup_complete=true。此轮不能算通过，也不提高预算；正在以独立45秒JSC诊断复查剩余热路径。18逻辑CPU主机的事后load快照约24/23/20，仅是环境观察，尚不能断言耗时波动原因。

独立诊断08从模块加载开始采样，混有大量10000订阅装配成本，不能冒充稳态热点。诊断09使用当前编译后用例的私有副本，只重定位相对导入并在原setup结束后采样45秒，源/副本摘要留本机；未修改dist或生产源码。25293样本中，COMMIT调用6431、仓库get4592，pendingRows的all仅255；原查询热路径已收敛，后续主要成本是提交及状态读写。诊断实际488事件后主动exit79，cleanup_complete=true，绝非6000事件验收。没有把主机繁忙当唯一原因，也未更改FULL、预算或负载规模。

100事件/秒目标须与实际耗时比较，未达到不能以用例通过冒充达标。三项选择器/授权探针已核验：错suite/无匹配均非零退出；缺授权real记录19例not_run、exit2。初始探针对real期待抛错文字，随后按实际结构化报告校正判定，原始探针记录保留。T42/T44/T49的真实验收标签已补齐，修复“只归A20”导致的映射遗漏；只改标签不改断言。第31批完整图构建exit0，较已保存的build30仅tests/cases.json输入摘要变化，510份输出逐项一致，故不为标签变化重跑未受影响的本地组。build31完整manifest也已私有保存。尚未提交本轮实现。

上述诊断进程均已结束并回收。后续已实现同轮同步写入合批，见下节；不在没有新依据时原样循环300秒负载。真实19例和物理footprint/Skill观察仍缺专用配置及控制器接线，待资源信息后完成，不索取已提供的应用秘密。

## 同步写入合批修复

新增application/write-batch.eli，在同一轮微任务内最多64个同步变更共用原带ownerGuard的Store.transaction；每项SAVEPOINT隔离，领域Result失败仅回滚本项，异常/提交失败回滚整批；所有Future在COMMIT后才发布。dispatchRoute的claim/prepare/receipt三个阶段等待该结果，原probe/submit仍在事务外，finally保留原claim清理。没有更改WAL/FULL、容量、原生帧、队首/unknown或授权守卫。

T40.write-batch-commit/isolation/failure/bound.sqlite四组已写齐并实际执行。build32/33分别暴露裸globalThis、dotimes不受当前编译器支持，修正为已有NativeGlobal和while；失败保留。build34完整图成功；integration11为844/844通过，run_id=2026-10-23T15:45:07.441Z-37255a58-6616-483d-b7d9-d0bcc4e6fef1，153.60秒，无缺失/重复/未处理错误，cleanup_complete=true。

当前按用户要求以两个独立对话异步结对：业务实现与整合由Codex负责，独立审核、测试和验收补齐由Antigravity默认Argon负责；不使用子agent、不切换模型。研发协作对话不算产品真实IM/Agent/Skill验收。测试源码补充与review收口后再冻结构建输入、集中复验；当前尚无合批后的系统/性能通过证据，所有A勾待恢复，不把844集成通过代替完整目标。

结对审核后的业务修复已写入：有效must领域失败按SAVEPOINT隔离，未知异常/Future仍整批回滚；dispatch finally对已释放claim不再开启空事务，残留清理仍在事务内重检身份；reconcile回执与成功后的待核对标志清除在一个合批项内。recordReceipt原本已有事务，未将其误报为auto-commit漏洞。schema增加匹配五状态队首谓词的deliveries_route_head，保留submitting/unknown屏障；EXPLAIN从旧route唯一索引切换为此部分索引，仅证明计划选择，不构成吞吐验收。不采用未经证实的runtime claim_owner过滤或“空COMMIT必然一次fsync”结论。对应新增测试由结对方编写，完成后集中构建及复验，当前尚无此批通过证据。

追加测试源码已包含must隔离、五状态索引幂等迁移/查询计划、独立SQLite读连接观察submitting提交、draining在途回执与新提交拦截、reconcile失败保留待核对标志及持久队列排空。整合检查发现排空统计误将routing_work终态写成completed，已在构建前纠正为生产实际done，避免把所有已完成工作统计为待处理。业务源码冻结通知已发送，测试方补齐剩余原子性断言后集中验证；发送/静态检查均不算测试通过。

真实Lark接线准备已推进：指定应用通过CLI的app-secret-stdin初始化独立dj-lark-user profile，品牌lark，专用profile默认身份设为user；验证应用身份匹配且user授权仍missing。已发起最小IM读取/用户回复范围的官方Device Flow，等待用户完成授权；未用bot补位、未发送消息、未建立授权测试群或完整DJ服务配置。CLI凭据归CLI管理，应用秘密、授权链接及device code均不写入仓库。

Lark用户授权后续已完成：首个交互窗口过期后按用户要求重新生成，用户明确确认完成后才轮询结束登录；随后auth status --verify实测identity=user、brand=lark、verified=true、user ready/token valid，应用身份与指定值一致，具备IM读取/用户回复及离线刷新所需scope。凭据仍只由CLI保存。测试chat/thread、Telegram与两Agent测试资源尚待接线，OAuth成功不代表真实消息闭环通过。

结对方集中验证的新证据：build35首次调用执行器文件名错误、尚未进入编译，失败日志另保留；修正运行入口后完整构建成功，111输入/514输出、cleanup_complete=true，build-35-manifest.json已保存且输入摘要核对无变化。unit09为74/74，run_id=2026-10-23T16:32:43.965Z-3ffdf5e2-1021-41cc-bde2-e4383cca726c；integration12为842/844，run_id=2026-10-23T16:33:27.483Z-abf8f4c3-1e88-4ba1-baaa-2afaad43059d，完整收齐且仅T16.observation-checkpoint.sqlite/T31.submit-cutover.sqlite失败；system05为25/25，run_id=2026-10-23T16:34:48.894Z-23269ee5-082a-4ef2-8208-8d4c516693ca。三组均无缺失/重复且执行器完成回收。两项新增用例已核对fixture缺失主体配置及断言读取未公开hold_reason，已通知测试方；保持冻结，先收齐性能组再统一修复，不因此扩大生产API。

performance08的严格路由和大扇出已产生通过记录，整组仍在执行时不先报全部通过。路由实际6000事件/60000输入、持久队列排空，CPU p95=1.654ms；负载阶段wall=97317.72ms、实际61.65事件/秒，尚未达到100事件/秒目标，不能因框架通过就声称吞吐达标。既定100来源/1000目标/10000订阅与FULL/容量未放宽，待整组终态后继续按实际热点处理。

恢复时先核对当前指令/Goal、Git、本文件、[施工手册](construction/plan.md)、[接口](construction/contracts.md)、[字段表](construction/operation-catalog.md)、[测试方案](construction/test-plan.md)和唯一TODO。秘密、原始会话、本机绝对路径不进入仓库；必要验收通过之后才签名提交并立即推送。

后续吞吐诊断已从同一份诊断10原始采样进一步归因：COMMIT位置4687个样本中，write-batch 2267、matcher独立事务1523、readSource健康状态622、ingestion 225、refresh 50。它们是采样占用而非事务计数；空来源轮询不是主要根因。源码还显示独立main固定20ms tick、每轮最多启动16条route，理想上限800次启动/秒，低于当前每事件10条route、100事件/秒所需1000次启动/秒。手动tick负载不受固定20ms约束，不能把该边界当作当前基准耗时的唯一解释。事务内只读复用、健康短事务合批及调度配额正在结对核查，尚未实施或取得新性能证据。

## 当前修复施工：七个业务文件已写齐，待测试冻结

本批已写入delivery/read-scope、ingestion/visibility、delivery/service、routing/matcher、delivery/scheduler、storage/repository及service/runtime。四表读scope严格限制在单次同步事务，finally撤销，256条上限、Future拒绝；routes和授权结论不缓存。静态SQL保留参数及revision；健康写入经原合批队列；route/outbound轮换优先且各自32/16、总64上限不变。没有调整FULL/队列容量、pacer或观察频率，也没有并发匹配多个事件。

当前属于S1/S2完成后的D整批修复，业务与回归按用户授权异步分工同步补齐。业务源码已作整体词法括号核对，尚未编译或运行；这不证明语言编译及业务行为正确。Argon仍负责补齐tests/用例说明，双方完成后统一冻结再集中验证；源码快照私有保存为business-source-repair-38.json。build37的947条是本次改动前的通过基线，不能直接支撑改动后的验收勾选。

双方首次输入快照已记录：Argon明确回报新增测试与用例说明全部写齐、没有运行；主开发核验57份业务源码快照一致，并保存112份输入的freeze-38.json。已交接独立集中构建/四层验收（计划build38/unit12/integration15/system07/performance10），由测试方自行连续执行，无需逐层等待口头许可；尚未观察到本批结果时不报启动或通过。运行中不改绑定输入。参考环境快照私有保留，硬件满足至少8逻辑CPU/16GiB；负载快照不作为耗时原因的证明。

首构建前独立核对又修正T31调度fixture：新增62个会话后显式catalog.refresh并tick，避免getSession命中旧目录，保证64目标已索引。尚无本批受控进程或构建日志时进行此项测试修正；最初freeze-38.json的delivery.test.eli摘要因此失效。测试方负责保留原快照并在首构建前最终冻结全输入，再按已有授权连续集中验证；57份业务源码仍与business-source-repair-38.json完全一致。运行开始后禁止再移动基线。

build38尚未编译业务源码即退出：先有不支持的执行器参数与admission入口错误，日志分别保留invocation-01/02；随后真正受控构建因Bun身份校验失败（run_id=0c0e027e9e9148c295527f9a92aad92e，exit1、cleanup_complete=true）。已核实默认Bun为1.4.0、仓库目标Bun为锁定1.4.4，prepared source commit/digest仍匹配；这不是业务编译失败。已给测试方提供build37相同的进程PATH固定命令，内外层bun均须使用仓库版本，不改全局Bun/锁文件、不重建编译器。修正后的构建仍待实际终态证据。

本批build38已成功：112份实际来源/518份输出，保存manifest与当前manifest一致，来源摘要无差异；build guard=58f8344bf16e42889225bedaab344a5a、exit0、cleanup_complete=true。首构建前补齐delivery测试的nativeSetTimeout导入，四份入口/身份/编译失败日志均保留，未修改生产源码。unit12为74/74（run_id=2026-10-24T04:56:51.855Z-ea684afb-4047-4efb-9845-e1a68a75dcfb）；integration15为843/844（run_id=2026-10-24T04:57:10.814Z-f95435ec-abaf-4837-9bdb-8edf8d7a405d），仅T12.update-cutover.sqlite新增断言失败；system07为25/25（run_id=2026-10-24T04:58:28.243Z-f9fa3a7e-9300-451b-b558-e74702c213cd）。三组终态均完成回收。T12读取原生信封contributions字段错误，freezeEnvelope实际字段为matched；已告知测试方保持输入不变，先收齐performance10再合并修复。性能组仍有已核实的受控进程，尚无终态，不报通过。

performance10现已收齐：run_id=2026-10-24T04:59:19.486Z-659f3442-ba99-4d6b-b80b-05bfcefa276e，3/4通过；路由107709.60ms因新硬断言失败，实际6000事件/60000输入、负载wall=98965.79ms、60.627事件/秒。其他三项为大扇出8661.30ms、十万目录23552.97ms、正文配额16553.59ms通过；guard=aa81ff5b6dbd4de19ed73a0bbfbefc47、exit1、cleanup_complete=true，峰值2460663808字节包含合成fixture。仍未达100目标，不能选取旧25.64轮声称稳定提升，也不重复跑已过未受影响项目。

四层全终态后已交接测试方修正T12原生信封matched断言，保留并实际验证后续授权撤销断言；生产源码暂不改。协调方已按build38逐文件摘要克隆216份相关输出做诊断11，仅在原setup后采样45秒并预期exit79，不是验收，不读写共享dist。等待本版实际热点后再决定下一批业务改动。


build39定向修正已核验：只改T12信封断言为matched，184份生产产物摘要与build38完全一致；integration16的T12为1/1通过（17次断言，run_id=2026-10-24T05:17:01.545Z-5a0fe9b1-573e-46c7-ae9a-b067f67d314e），build及测试cleanup_complete=true。可与build38其余功能结果合并读取，不能称为重新全跑844条；本地已知功能失败清零，吞吐仍为60.627事件/秒未达标。

私有诊断11/12/13均已终止并回收，预定exit79代表不完整诊断，不作验收。11采样中COMMIT约26.2%、repository.get约17.7%，是采样占用而非事务计数。12保持100/s发布计划但独立20ms调度，30秒观察2773事件/27720输入，约92.36事件/秒；13仅把SQLite建议缓存调大，30秒2522事件/25190输入，约84.07事件/秒，没有采用该设置的证据。短时不同负载历史不证明完整吞吐或因果收益，正式测试未改。

下一D修复批次按contracts末节写齐两业务文件：单route容量COUNT强制五状态部分索引；后台无请求主体的projectDelivery直接返回原最小投影；attempts增加delivery/outbound回执查询索引且幂等迁移。未扩大缓存、未实施多事件合批、未调整正式pacer/驱动或FULL。业务源码快照已保存business-source-repair-40.json，测试方补齐对应回归后冻结并集中构建/受影响集成与原路由性能；当前尚未运行本批。

后续诊断52绑定build88私有图，生产temp_store观察为2且探针不覆盖设置；窗口25188.28175ms、2473事件全部匹配、21132accepted/3598ready。SUBJOURNAL文件写入0，SQLite方法/迭代器15031.078332ms、query查找837.169613ms；投递状态更新42264次/1719.944677ms，COMMIT4995次/2751.025121ms，均是观察性成本而非端到端通过。53的16/64行SQL组件差异有限，54的同等CASE不变量守卫虽改变索引计划但计时有重叠和首轮漂移，均未采纳生产变更。55单次摄取调用中位0.331417ms而开始迟到中位52.099083ms，异步tick/producer时间重叠，不能加成孤立CPU。56延后40秒开始、观察29835.11475ms，新增2192事件/17112accepted，终态5059事件、37995accepted、待路由329；服务时钟止于50590ms，未覆盖60000ms维护点，空checkpoint结果不解释或排除正式运行的checkpoint成本。诊断期间有获准旧fixture文件清理，不作受控主机因果对照。所有诊断预期exit79并回收，不修改正式performance25失败。

EG1–EG2只修提交期echo再检的空缓冲finish与既有reason映射，精确手册和B归属已交原固定搭档；B/C未完成前不运行新验证。此修复不包含任何性能块大小、主键强制、跨事件缓存、配额或输入驱动变化。

诊断61在build109私有编译图仅对case helper增加JSC采样：25.169983秒、16659栈样本、2073事件/15075已接受，非完整容量验收；SQLite run self样本8232，其中5005定位COMMIT调用点。采样占比不等于精确墙钟或SQL次数。组件62仅比较原progress SQL与主键强制定位，最大deliveries路径16384调用235.658083ms/235.254625ms无明显差，未采纳生产SQL/索引修改；attempts/routes的小差值不外推服务净收益。首个WAL内存deserialize失败原样保留，改用独立文件副本完成组件。两轮自有测试库经归属/无打开句柄核对按用户授权清理，保留全部日志、profile、摘要和快照；生产输入/产物未改。
