# 会话查询、免订阅直发与显式生命周期

先核对运行时和当前授权，不因文档存在就启动工具。此流程不要求 IM 连接、订阅或已绑定 agent_id；会话目录可能包含未登记目标。所有引用必须来自本次授权查询，示例 ID/key 不能用于真实请求。

## 机械查找

session.list 按工具、实例、工作区等范围列出原生会话：

```json
{"scope":{"tools":["codex","cursor"],"visibility":["live","history"]},"limit":50}
```

“某个 Agent 下的会话”先区分工具类型、运行实例和已登记目标。一个 agent_id 只代表已登记的一个会话；找某种工具全部会话用 tools，不能把它当父 Agent 名称。所有范围仍受当前授权和已配置适配器约束。

session.search 的 query 是区分大小写的字面文本，不是自然语言任务路由：

```json
{"scope":{"tools":["opencode"]},"query":{"text":"issue-123","fields":["title","message.text"],"mode":"literal"},"limit":50}
```

只查消息命中可用 session.message.search：

```json
{"scope":{"tools":["codex","cursor"]},"query":{"text":"issue-123","fields":["message.text"],"mode":"literal"},"limit":20}
```

看 snapshot_id/as_of、sources/stale、coverage_complete 与 next_cursor。分页 complete 不证明所有来源已覆盖，离线或未索引不能当作不存在。结果提供事实/原文片段，由你根据用户意图判断任务可能在哪里，不让 DJ 选“最合适”的目标。

search 仅按稳定 session_key 顺序，不支持全局时间/相关度排序；预算用完可有空 items 和非空 next_cursor，必须视为尚未查完。需要刷新或搜索某个/几个已知会话，scope.session_keys 可精确选择，最多 100 个；一个 agent_id 不是使用这条路径的前置条件。旧 cursor 失效重新查，不把不同快照拼作完整一页。

需要新数据时显式 catalog.refresh；它只读外部来源并更新目录，不启动/恢复工具，也不触发模型：

```json
{"scope":{"tools":["opencode"]},"include_content":true,"idempotency_key":"catalog-example-1"}
```

保存 catalog_run_id，从 catalog.get 看覆盖/continuation；需要续扫则用同范围的新 refresh 动作。不要设置定时轮询。私有目录或正文没有 read 权限时不能换接口绕过。

## 已知原生会话直发

已知实例和原生会话 ID 时用 session.resolve：

```json
{"instance_id":"inst_example","native_session_id":"native_example"}
```

核对返回的工具/namespace/会话摘要；可用 session.probe(session_ref) 只读确认 receiver/epoch（不发送测试消息），再 session.send：

```json
{"session_ref":"ssr_example","content":{"type":"text","text":"请检查当前任务的状态，并把结果留在本会话。"},"idempotency_key":"direct-example-1"}
```

也可用已有 agent_id，二者互斥。无须订阅或注册新的 AgentTarget。session.send 是给 Agent 输入；message.send/reply 是向 IM 发送，两种操作不能混用。

保存 operation_id/delivery_id，以 delivery.get 查投递状态；没有 agent_id 仍可按 operation_id/session_key 查自己的 delivery。目标原生回答通过 session.message.list/get 读取，正文未覆盖则显式定点 catalog.refresh(include_content=true) 后再读，不会自动回某个 IM。offline 不会自动启动或换会话；unknown 先 reconcile，不能新键重发。短期 session_ref 过期后用稳定 session_key 调 session.get，或精确重新 resolve，已受理 Delivery 仍保存固定目标。

delivery_policy 仅 busy/offline/ttl_seconds，默认 steer/hold；busy=queue 显式要求等待空闲，原生未声明忙时输入支持则明确受阻；context_policy/current 不属于直发参数。注销登记、暂停订阅不取消独立 direct，也不清共享 unknown。stopping 时新直发被拒绝，不能另起同名实例绕过。

## 显式启动与创建

创建是调用方明确指定的机械操作，可以为空，也可以带 content 首条消息；DJ不自行决定任务、工具、模型或权限，不注册Agent或订阅。须具备session.create授权、获准workspace_ref、匹配实例epoch和独立幂等键；原生端口没有create能力时在创建动作受理前返回unsupported。

当前正式接线只连接已有客户端或 CLI 进程的原生接口；managed_profiles 必须为空，原 argv profile 启动路径已禁用。不能为投递创建 App Server/ACP 子进程，不能用启动参数传递消息、会话、模型或会话配置。当前没有接口式自动拉起客户端的实现；没有活接收端时报告不支持或离线，不自动替换。AI 工具主动调用 DJ MCP/API 是另一条受支持接入方向。

先 instance.list/get 核对支持的已有实例。部署凭据须显式配置 instance.inspect、session.create、lifecycle.inspect、lifecycle.reconcile；create 权限不隐含其他查询权限。ownership=existing 可以创建，不要求 managed profile；不要为创建打开已禁用的进程托管。

实例投影公开 workspace_scope、workspace_ref、directory 和 workspace_refs。directory 范围只允许配置工作区；instance 范围的 OpenCode、Codex、Antigravity 可使用同实例发现所得的工作区引用和绝对目录。directory 可省略，此时 DJ 仅从同实例、同 epoch 已发现的会话解析，找不到就返回 creation_workspace_unresolved，不能靠标题猜目录。更改范围属于管理员配置，不能在请求中自行放宽。

已有运行实例支持新建会话时，session.create 使用返回的 instance_epoch 和获准 workspace_ref：

```json
{"instance_id":"inst_example","expected_instance_epoch":"epoch_example","workspace_ref":"wsp_example","title":"issue-123","idempotency_key":"create-example-1"}
```

跨工作区示例（endpoint 已配置 workspace_scope=instance）：

```json
{"instance_id":"inst_example","expected_instance_epoch":"epoch_example","workspace_ref":"opencode-workspace-<发现所得摘要>","directory":"/absolute/project","title":"issue-123","idempotency_key":"create-example-2"}
```

当前能力：OpenClaw Gateway、Hermes 后台服务、OpenCode、Cursor native_api、Kimi/DSH 有各自的宿主创建路径。Antigravity 创建需要当前桌面实例能通过原生认证，先核对 agent.discover 的 coverage 和 reason。Codex 由已有原生 Node 工具宿主加载 DJ 接收端，配置 control_manifest_path，通过平台鉴权的 App Tools 接口创建/改名；必须提供明确非空 content，native_queued 与 initial_input_receipt_key 表示一次原生创建已同时受理首条消息，不再重复 session.send。Claude Desktop 通过原生 LocalSessions 创建/改名，CLI inbox 仍仅通知已有会话。Pi 接收扩展在同一宿主内创建独立 SDK 会话，原交互会话保持；空会话按 Pi 首条 assistant 后保存历史。模型覆盖以 instance.get 的实际能力为准，未实现参数明确拒绝。接线及宿主退出边界见 clients.md 与运行包 connectors/codex、connectors/pi 的说明。

不提供 content 则只创建会话；提供 content（纯文本）时要求额外 session.send 权限，创建成功后由持久 outbox 向准确新会话发送一次。lifecycle 的 ready 仅表示创建成功；initial_input_state=pending/queued/blocked 和 initial_delivery_id 分别表示待受理、已记入投递及被拒绝，具体送达看 delivery.get。进程恢复后用稳定幂等键找回首条投递，不另建对话或重复输入。也可在创建后单独 send。不得捏造占位 prompt、复制权限、安装 Skill 或注册订阅。Cursor 必须使用实际 Desktop 接口；CLI-only 证据不代替 Desktop。OpenCode 的创建也不证明新会话已成为桌面当前 Tab。

要让新会话订阅IM，可使用已部署普通AI profile和Skill，自行discover/register准确原生目标 → whoami的bound_agent_ids核对 → preview/create。凭据与目标分离，一个主体可登记多个目标；不借用operator或其他受限profile，不自动替接收方建立业务订阅。若只要定向输入，直接 send，无须这段部署流程。

普通调用身份的首次部署由可信宿主使用 `Core.reloadConfig` 或 standalone 私有配置/SIGHUP 完成；它不是普通 Agent 的 CLI/MCP 权限修改工具。只支持 principals/client_profiles 的原子重载，不能通过发送配置 JSON 改连接或启动参数；已有主体权限变化需提高 authorization_revision，注销 ID 不复用。

创建超时先 operation.get 找回 lifecycle，再 lifecycle.get/reconcile；原生结果 unknown 不按标题猜成功或换键再建。普通 Agent 不执行 lifecycle.resolve。已有客户端属于原宿主，不能停止借用的工具或强停原任务。历史生命周期 ready 仅是当时动作结果，不能替代当前 receiver/instance/session probe。

OpenCode 使用当前 `/api/*` 本机服务协议；现有运行中服务由原生 service_file 重新发现。桌面与后台历史分别核实，创建桌面会话需配置原生桌面控制入口；发送不启动新的 CLI/ACP。session.create 可显式提供 model_selection={provider_id,model_id,variant?}，完整模型 ID 可以含斜杠，variant 按该模型原生目录验证。持续发送保持既有模型，忙时输入使用原生 steer；持久接收与实际回复分别验证。

## 创建并发送首条消息

用户指明由某个本机工具接手，已有精确接收会话就用 session.send；只给工具且需要独立接手时，调用方可在已有原生实例直接 session.create，一次携带实际交接正文。先查一次目标实例和已知工作区，不扫描全历史、不先发给另一个助手代建。正文保留已有统一 Identity、任务、工作目录、当前进度与必要约束；Identity 已给出日志入口。

Codex 的 instance.ready 和 session_create=supported 表示已有桌面进程与已配置能力。创建受理前 DJ 还会探测同代次原生创建接收端；入口过期、宿主退出或原生工具不可用时返回 unavailable，details.reason=native_creation_receiver_unavailable，未记录 lifecycle、未提交首条。此时可以修复原入口，或按授权用原生 Codex App Tools/已接通的 Agent Control 管理入口一次直接创建。命令返回 recorded 后须查原 lifecycle；unknown 仍按同一创建键或原生项目定点读回，不另建或换路重发。

```json
{"instance_id":"inst_example","expected_instance_epoch":"epoch_example","workspace_ref":"wsp_example","title":"issue-123","content":{"type":"text","text":"请调查这个明确的问题。"},"idempotency_key":"create-with-input-example"}
```

## 修改标题

- operation: session.rename（session_ref、title、idempotency_key），返回 lifecycle；原生读回同 ID、同实例和准确标题才为 ready。支持的现有端点：OpenClaw Gateway、Hermes 后台服务、OpenCode、Antigravity、Cursor native_api；未接通端点返回 unsupported，不直接修改第三方历史数据库。重试原键找回同动作，unknown 只读回核对，不再次写入。
- permissions: session.rename 独立授权，不隐含在 session.send、session.create 或 session.inspect 中。lifecycle.get/reconcile 沿用原权限。
- alternative: DJ 达不到目的时，AI 可使用自身原生能力、其他可用接口或已安装 Skill 继续完成；无需特定外部工具。先核对原操作是否已生效，避免双路重发；准确原目标、授权与回复身份不变。

## Codex 原对话加载与送达核对

Codex 原生 send_message_to_thread 会先加载原对话；DJ 的 follower socket 只负责已有接收端。macOS 端点配置 receiver_loader_ref 与 process_helper_ref 后，已受理投递可向同一已验证 App 进程发送原对话链接，等待接收端出现，再从原 socket 发正文。不会启动 App、Agent CLI 或 App Server，不新建对话；客户端可能切到目标对话页。列表、resolve、probe 不自动加载。

调用 session.probe 取得新鲜 live_receiver/runtime_state/receiver_reason；session.get 的缓存必须结合 stale 判断。session.send 返回 ready 只表示持久受理，不表示送达；保存 delivery_id，以 delivery.get 的 state、blocked_reason、receiver_reason、submitted_at、accepted_at 和 receipts 核对。accepted 是原生接收，busy 是当前运行观察，都不是该任务完成证明。

receiver_discovery_timeout 表示本次有界探测未确认owner，不等同于会话不存在。receiver_loader_unconfigured、receiver_load_permission_denied、receiver_load_rejected、receiver_load_pending 或 receiver_load_backoff 表示加载尚未完成。调用方 AI 可以据此决定请准确的原 Codex 助手使用其 send_message_to_thread 代转，保留原任务和回复身份；DJ 不猜助手、不自动转交。原 DJ 投递仍待投时，先 delivery.cancel 取消并读回确认，再走另一发送入口；submitting/unknown 先 reconcile，禁止双路盲重发。已 accepted 的消息不再转发。查询后续原生 userMessage/轮次确认是否开始处理。 Codex 重启清掉 follower socket 时，DJ 会在接收端目录查找当前 App 主进程登记的原生宿主，核对原会话再继续。若 `blocked_reason=target_receiver_unavailable` 且 `receiver_reason=receiver_control_unavailable`，检查当前 Codex App 是否注册了 [原生工具宿主接收端](../../../connectors/codex/README.md)，保持原队列继续等待。

## 入口失效和未加载目标

- 单一MCP连接返回`incompatible`时，先用稳定安装入口`~/.dj/current/bin/dj status --json --client-profile ~/.dj/client.json`检查当前服务。新CLI正常就使用同一profile继续原操作，不因旧MCP目录状态停工。受理过的操作仍先查原operation/delivery。
- 发送前核对准确的显示标题、工具、工作区和原生ID。相似名字的对话用原生 ID 区分。Codex 会话没有原生名称时标题为空，可继续用原生 ID 定位。
- 当前为notLoaded只说明接收端尚未加载。配置了原对话加载器的DJ会在session.send受理后的投递阶段加载并重验，再发送正文；无需用户手工点击。仅probe不触发加载。
- 外部接口的`queued`、CLI退出码0、`codex queue`入队记录，都不是原Desktop已接收的证据。尤其`could not resume`意味着自动恢复失败，不能报告“发到了”。外部队列不由DJ消费，也不能替代已存在Desktop的跨进程通知。
- 其他入口的发送已经unknown时，先核对准确原目标的历史和原操作；不能为试验加载再发送同一正文。明确未发送或取消原待投后才换入口。跨工具通知或直发受阻时只走DJ或目标原生非UI接口排查，禁止改用`kimi-cu`、`osascript`等桌面UI自动化向目标客户端窗口模拟输入。
