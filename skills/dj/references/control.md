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

创建是调用方明确指定的机械操作，只创建空对话；DJ不自行决定任务、工具、模型或权限，不随创建发送首条消息、注册Agent或订阅。须具备session.create授权、获准workspace_ref、匹配实例epoch和独立幂等键；原生端口没有create能力时在创建动作受理前返回unsupported。

当前正式接线只连接已有客户端或 CLI 进程的原生接口；managed_profiles 必须为空，原 argv profile 启动路径已禁用。不能为投递创建 App Server/ACP 子进程，不能用启动参数传递消息、会话、模型或会话配置。当前没有接口式自动拉起客户端的实现；没有活接收端时报告不支持或离线，不自动替换。AI 工具主动调用 DJ MCP/API 是另一条受支持接入方向。

已有运行实例支持新建会话时，session.create 使用返回的 instance_epoch 和获准 workspace_ref：

```json
{"instance_id":"inst_example","expected_instance_epoch":"epoch_example","workspace_ref":"wsp_example","title":"issue-123","idempotency_key":"create-example-1"}
```

创建只建空会话，不自动 prompt、复制权限、安装 Skill 或注册订阅。核验得到稳定 session_key 后取当前 session_ref，再单独 send。Cursor 必须使用实际 Desktop 接口；CLI-only 证据不代替 Desktop。OpenCode 的创建也不证明新会话已成为桌面当前 Tab。

要让新会话订阅 IM，需要可信宿主/操作员将独立 recipient/client profile/Skill 接入真实会话并固定 target_constraint，再 discover/register → 接收方 whoami/回复工具核对 → preview/create。创建者自己的绑定不变，不能替新会话复制凭据或登记为自己；未完成接线就只报告已建会话。若只要定向输入，直接 send，无须这段部署流程。

这一步由可信宿主使用 `Core.reloadConfig` 或 standalone 私有配置/SIGHUP 完成；它不是普通 Agent 的 CLI/MCP 权限修改工具。只支持 principals/client_profiles 的原子重载，不能通过发送配置 JSON 改连接或启动参数；已有主体权限变化需提高 authorization_revision，注销 ID 不复用。

创建超时先 operation.get 找回 lifecycle，再 lifecycle.get/reconcile；原生结果 unknown 不按标题猜成功或换键再建。普通 Agent 不执行 lifecycle.resolve。已有客户端属于原宿主，不能停止借用的工具或强停原任务。历史生命周期 ready 仅是当时动作结果，不能替代当前 receiver/instance/session probe。
