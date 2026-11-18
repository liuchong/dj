# 0018 — 离线补收与原会话投递恢复

## 收件恢复

Lark user/bot 共用持久 HTTP 断点，各自独立运行。重新上线继续原窗口与分页；新窗口最多覆盖一天，保留两分钟重叠及两秒安全尾差。历史窗口完成后立即排下一窗口，追平后恢复配置的轮询间隔。每页、并发、应用限流、入站容量和事务去重保持原有边界，不因追赶放宽预算。断点与消息原子提交，失败不越过未收取的数据。

`source_health` 读取当前身份的 `inbox:*` 消息断点，不再使用旧 watch 的停滞水位。`ready` 表示请求已成功且当前无已知请求错误；`catching_up` 与 `lag_seconds` 单独说明历史尚未追平，不能把连接在线说成消息已收齐。追赶判定留出至少三十秒及三轮断点扫描的余量，避免多群轮巡的正常延迟被误报为积压。没有断点或成功证据仍不报告正常。

## 投递恢复

- 明确 `failed + definite_not_sent + retryable` 的通知自动恢复为待发，采用 2–60 秒指数退避，受全局并发、队列容量、TTL 和原发送前身份／授权／实例门复核约束。最多每五秒调度四条；不自动重试永久拒绝。已过期通知结束，不补发。
- `submitting` 在服务重启后仍转 `unknown`，不冒充未发送。`unknown` 自身绝不重新提交；默认异步消息不会因此阻塞其他独立通知，显式排队模式保留屏障。
- Codex 提供仅正向的接收核实：从准确原生会话的 IPC 快照中查找与不可变 attempt 信封渲染结果完全一致的原生 **userMessage**。匹配才记录原生 accepted 回执；AI 引用、部分文字、空历史和查不到均不构成证明。
- 正向核实允许原客户端重启后的新进程读取同一原会话，仍校验命名空间、端点与工作区，不修改历史 binding/attempt、不发送输入。每五秒最多调度四条，单条核实后至少间隔三十秒。其他工具仍遵守其原生查回能力与实例栅栏。
- 客户端离线不自动新建 Agent 进程或替代会话。客户端自行恢复后继续原队列；接口式启动不在本批范围内。

## 验收

用真实 SQLite Core 加本地协议接收端验证长时间离线补收、断点重启／去重、明确未发送后的恢复、unknown 正向核实与不重发、工作区栅栏及健康水位。服务升级保留真实消息、规则和原有不确定记录，不以真实消息盲目重投作测试。

## Lark 原始事件确认与本地恢复

官方事件送达与业务处理是两个独立阶段。完整 WebSocket 事件先在当前连接身份下写入 `lark_event_receipts`，事务提交后才返回平台 `code=200`。原生 `event_id` 在连接与身份栅栏内去重，相同 ID 不同内容拒绝确认；不保存 header 的 verification token。存储失败、容量不足或本次确认耗时超过 2.5 秒均不发送成功确认，关闭该连接等待平台按其规则重试。平台重推可能有限次，不能承诺任意长离线都能补齐。

解析、引用/表情原文补取和文件订阅过滤在确认之后执行，与 WebSocket 重连独立。每次最多处理 8 个到期事件，解析失败或业务 inbox 暂满按 2–300 秒指数退避持续恢复，不因次数多自动丢弃。服务重启仍从持久待办恢复；处理中重启的预占最长等待 30 秒。规范化结果写入 `im_event_inbox` 与原始回执完成状态在同一事务内提交，进程在任一切点退出均不会留下“已经完成但没有入库”的状态。之后继续沿 Core 的持久事件、订阅、投递及不确定发送核实链路处理，不另起直发通道。

不支持的事件类型、非本用户的接收者通知、未订阅的文件变更必须留下明确忽略原因。错误诊断只暴露稳定错误码，不输出任意异常文本、凭据或原文。旧身份下未处理事件保留但不自动交给新身份，连接探测单独报告 `other_identity_pending`，需要明确核对。

每连接未处理原始事件最多 1000 条、合计 64 MiB；不会为腾空间删掉未处理事件。已处理/已忽略记录释放原始正文，只留 ID、类型、摘要、时间、次数和结果；保留最多 7 天、1000 条终态记录，收到后续事件时清理。原始回执去重超出此窗口后，Core 的 `source_key` 去重仍生效。普通消息历史继续由既有保留规则管理。

`connection.probe.event_source.event_receipts` 显示保留记录的 pending/retrying/processed/ignored 数量、待处理字节、最老待处理时间、最近 8 条事件及失败/忽略原因。计数是当前保留窗口，不是生命周期总数。`user_document_notices.realtime_observed` 从当前身份已规范化的真实评论事件恢复，重启不凭订阅状态伪造送达证据。

文档通知不提供本机可设置的 since/cursor。`subscription_status` 只返回是否订阅；平台应用事件确认也独立于用户在正式客户端是否已读。DJ 能恢复自己已可靠收到的原始事件，不能凭空补出平台从未送达、超过重推窗口或未开放为公共事件的通知。缺失时通过原生事件日志核查，不能用读取某条已知记录或显式快照重放冒充历史通知补推。

验证入口：`tests/integration/event-receipts.test.eli` 用本地官方帧协议替身、真实 SQLite Core、订阅与既有会话端口，覆盖确认前独立连接读回、慢补取、重启恢复、规范化写入回滚、重复 ID、六种资源类型、明确忽略、容量与身份隔离；`tests/unit/event-receipts.test.eli` 保护摘要、验证 token 剥离、退避和错误脱敏。此证据不代替平台对某次真实桌面通知的送达确认。

## 合并转发详情与补收连续性

Lark 按 message_id 读取详情可能同时返回合并转发外层消息及其内嵌消息。
DJ 的单键 history 读只选取 message_id 精确一致的唯一记录，不将内嵌消息当作
各自来源群的新到达事件；缺失或重复目标仍拒绝。原响应字节上限与列表分页上限不变。
这样合法的合并转发不会卡住 pending_ids，后续群消息与新图钉继续通过原持久断点补收。
订阅暂停／恢复不重置传输水位，也不改变 Pin 条件；恢复后的新动作仍经正常扫描、
去重与订阅投递，不靠手工重放解决。

## 已有原生实例的进程重启与公用重发现契约

所有 `ownership = "existing"` 且实现活体实例与准确原会话双探针契约（`probeInstance` + `probe`，对外公开 `capabilities.instance_epoch_refresh = "supported"`）的适配器统一接入 `service/recovery` 启动恢复与 `lifecycle/native-refresh` 运行期推进，不在 `lifecycle/gates` 硬编码工具名字名单。当前已接入的 existing-instance 适配器（Codex、Cursor、OpenCode、Antigravity、Claude Desktop、Claude Code native inbox、Kimi Work/Web、DSH Desktop/Web、Pi 接收扩展）及后续遵循同一契约的新适配器共用同一恢复规则：

- **读侧探测与写侧/游标栅栏统一分离**：`probe` 与 `probeInstance` 核验同一已配置实例、原生命名空间、工作区与准确 `native_session_id` 并返回当前真实 `instance_epoch`，不因旧 `binding.instance_epoch` 在探测阶段提前失败；`submit`、`create`、`lookupCreate`、`rename` 与带游标/会话栅栏的 `readMessages` 则严格校验刷新后的 `expected_epoch`。
- **公用本机重发现基础层**：
  - `adapters/agent/local-endpoint-resolver` 统一承载缓存核验、单飞 `pending` 去重、原进程退出或 PID 复用判定、同 UID 可执行文件/父进程/参数/私有目录 manifest/唯一 loopback 监听端口或 Unix socket 重发现，以及发现后的二次身份复核（闭合 PID 复用竞态）。刷新所得运行时端点、CSRF token 与 TLS 叶证书仅保存在端口内存，绝不回写持久配置文件、SQLite 或日志；多候选无法唯一定位时统一 fail-closed 拒绝，绝不启动新客户端进程。
  - `adapters/agent/electron-recovery` 统一承载同 UID Electron 主进程与目标窗口重发现（Cursor 与 Claude Desktop 共用），仅在原 `(process_id, process_birth)` 已退出或被复用时重绑唯一主进程与匹配窗口，活进程窗口/origin/epoch 不一致时保持拒绝。
- **门禁与幂等边界**：启动恢复只在原生探测成功后开放恢复门禁；运行期 `agent.probe`、`session.probe` 与待投调度可推进开放门禁，或开放仅因启动离线而关闭的 `recovery` 门禁，绝不覆盖显式停止门禁。原 Agent 登记、规则、订阅以及历史 `binding` / `attempt` 快照保持不变，未发送消息继续投递，`accepted` / `unknown` 绝不因客户端重启重发。


本批5项定向集成与3项保护性单测共165条断言通过。新集成使用真实本机HTTPS接收端、PID及监听端口，模拟App可执行文件/出生元数据，连续更换PID、端口、证书和token；不重配、不重启Core即可由agent.probe、session.probe或待投路径恢复。验证显式停止、多进程歧义拒绝、配置不改、凭据文件不产生及旧绑定不改；既有积压/unknown不重发与OpenCode恢复用例通过。

真实已安装App另做只读核验：向新适配器传入失效进程/端口种子且不提供凭据文件，仍自动取得当前本机实例ready及原生epoch；初始化命令仅生成endpoint，不生成credential文件。此证据不是实际重启用户客户端或重新投递业务消息，没有把模拟集成冒充实际App重启验收。

部署核验同时修正instance.list/get的MCP输出schema：正式声明workspace_ref、directory、workspace_scope，与已有Core投影一致。真实stdio集成与类型保护性单测覆盖列表及单项读取，避免合法工作区信息被严格校验拒绝。
