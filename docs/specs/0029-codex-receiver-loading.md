# Codex 原对话加载与投递状态

DJ 是机械接线工具。调用方已经指定的准确会话没有加载接收端时，服务应尝试在原客户端内加载，不创建替代对话、不决定任务负责人。

## 原生边界

Codex App 的 send_message_to_thread 经 sendFollowUpMessage 先执行原对话 resume，再按原状态发送。DJ 的 owner/follower socket 不提供该准备步骤。macOS 使用同一客户端的原对话 URL 事件触发客户端加载，正文仍从已验证原 socket 发送。只向已有同 UID 进程定向事件；不启动客户端或 Agent，不启动 App Server，不改签名、信任、模型和权限。客户端可能切换当前对话页。

端点显式配置 receiver_loader_ref 和 process_helper_ref，其他平台保持不支持该宿主能力。默认查询不会加载；只有受理后的投递在 claim 内尝试。历史原生 ID、未归档状态和工作区须先核实，socket 身份、进程出生身份和 Bundle ID 须匹配。加载后的 owner、epoch 与工作区重新核对，再进入 submitting 持久切点和发送。

每目标每分钟至多发一次加载事件，最多保存256个退避条目；同目标并发合并或明确等待。owner发现由DJ本地定时器限时1秒，不能只依赖原生timeoutMs；超时不证明不存在；加载后至多3次有界重查。取消、TTL、draining、失主和授权照常在提交事务中复核。加载不等于恢复业务；仅提交已获准的新输入。

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
