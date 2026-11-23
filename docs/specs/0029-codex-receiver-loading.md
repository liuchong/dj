# Codex 原对话加载与投递状态

DJ 是机械接线工具。调用方已经指定的准确会话没有加载接收端时，服务应尝试在原客户端内加载，不创建替代对话、不决定任务负责人。

## 原生边界

Codex App 的 send_message_to_thread 经 sendFollowUpMessage 先执行原对话 resume，再按原状态发送。DJ 的 owner/follower socket 不提供该准备步骤。macOS 使用同一客户端的原对话 URL 事件触发客户端加载，正文仍从已验证原 socket 发送。只向已有同 UID 进程定向事件；不启动客户端或 Agent，不启动 App Server，不改签名、信任、模型和权限。客户端可能切换当前对话页。

端点显式配置 receiver_loader_ref 和 process_helper_ref，其他平台保持不支持该宿主能力。默认查询不会加载；只有受理后的投递在 claim 内尝试。历史原生 ID、未归档状态和工作区须先核实，socket 身份、进程出生身份和 Bundle ID 须匹配。加载后的 owner、epoch 与工作区重新核对，再进入 submitting 持久切点和发送。

每目标每分钟至多发一次加载事件，最多保存256个退避条目；同目标并发合并或明确等待。owner发现由DJ本地定时器限时1秒，不能只依赖原生timeoutMs；超时不证明不存在；加载后至多3次有界重查。取消、TTL、draining、失主和授权照常在提交事务中复核。加载不等于恢复业务；仅提交已获准的新输入。

## 客户端重启

如果 follower socket 已失联，DJ 只采用当前 Codex App 主进程已授权的原生工具宿主接收端。查找按当前 PID 及进程出生标识核验，同一原生会话的目录和 ID 必须经 `read_thread` 确认。送出正文后失去回执按 unknown 处理，只核对原投递。未注册时状态为 `target_receiver_unavailable`，同路下一次检查至少间隔五秒。登记由当前 Codex 原生工具宿主提供，DJ 自行发现已登记的新接收端并保留原会话队列。

主进程生存和文件存在只用来定位。实例查询确认当前接收端确能完成原生只读请求，失联则返回 `live_receiver: false` 和具体原因。历史读取不得提供新进程代次证据；对已定位会话，`offline: hold` 的明确发送在实例恢复期间仍入原路队列，最终发送必须再次验证活会话及当前实例门禁。工具宿主卸载后的短期参考仍按它签发时绑定的持久会话判断。新授权宿主用独立 socket 原子发布新登记，不依赖旧宿主退出清理。

## 工具性状态

session.probe 提供新鲜 live_receiver、runtime_state、receiver_reason、observed_at/stale。session.get 的旧缓存不是当前接收端证据。delivery.get 暴露 blocked_reason、receiver_reason、submitted_at、accepted_at 与原生 receipts。ready/deferred 不等于送达，accepted 不等于模型处理或业务完成，unknown 不等于未发送。

未配置、系统权限拒绝、原生拒绝、加载尚未完成、冷却等待均有明确原因。由调用方 AI 选择是否请其他准确 Codex 对话代转，DJ 不自动选助手。改走其他入口前先取消原待投并确认；submitting/unknown 必须先核实，已 accepted 不转发。处理结果由 AI 决定。

## 验收

定向验收覆盖只读查询不加载、加载后准确原会话投递、跨工作区与归档拒绝、失败原因和退避、原生回执与提交切点、取消/未知防重。实际 macOS 验收应在已有专用测试对话执行，不向业务对话灌入探测任务。保护性单测覆盖输入与状态边界。


## 当前验收结果

4项定向集成/保护性检查通过，覆盖原生有帧长协议、真实SQLite受理/提交/回执、查询不加载、发现超时、加载与冷却、取消防双发和宿主输入拒绝；既有Codex/Cursor桌面接线回归通过。本机正式launchd服务对既有未加载的专用测试对话完成自动加载、原生投递和模型标记回复，无人工打开、无替代Agent进程。补齐本地发现截止后的样本约4.4秒确认接收，属于单次本机观察，不是时延保证。安装Skill与源码字节一致，业务订阅、规则、过滤和退订状态保持原值。

## 故障归属与入口核对

未加载对话与队列未消费是两种状态。旧历史IPC、外部CLI队列或单一MCP连接失败不能直接归为DJ加载失败；以准确目标的DJ受理记录、receiver_reason、提交切点、原生接收及实际读回定位。单一MCP目录不兼容时先检查最新已安装CLI，CLI可用继续原授权操作。外部CLI入队后若无法resume，不算Desktop送达，DJ也不自动接管该外部队列。

再次实测：已有专用对话起初由原生App列表返回notLoaded，DJ只读resolve返回receiver_discovery_timeout；随后通过正式session.send自动加载，无人工点击，约4.2秒记录原生accepted，并从原会话读回唯一诊断标记。此为单次当前安装链路证据，不保证所有外部队列或客户端状态均相同，也不构成时延承诺。

## 轮换冷线程唤醒与短暂目录窗口捕获（2026-11-24）

Codex Desktop 仅在会话导航/目录发现（`mcpServerStatus/list`）时短暂拉起配置为 stdio MCP 的接收代理（`connectors/codex/launch-mcp.sh` / `mcp.mjs`），并在该次会话实际执行 `turn_input` 后将其转为长期驻留子进程。为此：

- `requestCodexAppWake` 支持显式 `cooldown_ms` 并返回退避已过时长 `elapsed_ms`，便于短窗口轮询与后台退避（默认 60 秒）分别控制节奏。
- `resolveWakeCandidates` / `nextWakeThreadId` 从优先目标、`caller-context.json`、`control_manifest_path` 登记文件及只读 `state_5.sqlite`（非归档最新线程）组装去重候选列表并按端点游标轮换唤醒，避免单一已打开标签重复导航无效。
- `probeWith` 在本地控制与 IPC 快照均不可达时触发 `wakeAndProbeCodex`（上限 7.5 秒、留足截止余量），在唤醒后以 100 ms 间隔轮询捕获新登记的 `<owner_pid>.json`，使紧随其后的投递直接提交正文并由原会话 `turn_input` 接续持久驻留；同时将 Codex 原生接收端监督收敛为单把 `<owner_pid>.lock`，消除双锁上限退出现象。
