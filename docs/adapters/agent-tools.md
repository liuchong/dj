# Agent 工具适配

DJ 只连接已有进程的原生接口，核对实例、原生会话与工作区，并把输入和回执映射到统一台账。它不运行模型、不选择任务、不用新建 Agent CLI 进程代替原会话。

## 当前接线

| 工具 | 接收方式 | 约束与说明 |
| --- | --- | --- |
| Codex | 已有 Desktop 的本机 IPC | 核对 owner、原会话与工作区；历史记录不等于活 receiver |
| Cursor | Desktop Bridge，或显式 native_api | native_api 可由 DJ 按需管理本机 Inspector，操作后关闭自己开启的端口；[详细配置](desktop.md) |
| OpenCode | 已运行实例的 loopback HTTP API | 准确工作区、私有凭据与原生会话；有界消息分页，不将 message ID 猜成游标 |
| Pi | 原 TUI 内加载的接收扩展，经私有 UDS | 扩展在原进程调用接收接口；临时加载与持久配置分别核对；[扩展说明](../../connectors/pi/README.md) |
| Claude Code | 同用户进程的原生 UDS 登记与回调 | delivered/held/refused 与无 ACK 分开；普通 Claude Desktop 不替代 Code 会话 |
| Antigravity | 原应用的 loopback HTTPS/RPC | 核对进程出生、原生会话、工作区及获准凭据；[原生接线](native-inboxes.md) |

真实验证范围见[项目状态](../status.md)。工具列在表中不表示当前机器存在可投递实例，协议夹具也不替代真实接收证据。

## 能力与身份

端口按实际实现声明 supported/unsupported/unknown，包括发现、读取、已有会话输入、接受观察和可选创建等能力。查询、创建、停止与投递分别授权，不能用一个 `supported=true` 概括全部能力。

发现返回可直接复用的 candidate_ref；登记时核验 recipient 的 target_constraint。名称用于展示和过滤，准确目标是 tool、namespace、实例、工作区和 native_session_id 的组合。空闲输入、工作中追加与原生排队不是同一个动作，不支持时明确返回。

正式配置拒绝非空 `managed_profiles`，不装配 argv 托管端口、不执行 auto_start。历史托管协议资料不能作为运行回退。已有实例不在线时不静默切换新会话、模型或其他工具。

## 原生输入与观察

- 输入序列化使用统一信封编码。`conversation_rules.text` 保持原会话保存的原文，通知信封不规定最终自然语言回复的格式。
- 协议接受、原生输入读回、模型开始和任务完成分别记录。HTTP 204、socket 写出或进程退出码不能单独证明全部业务完成。
- 结果未知时保留 dispatch 关联和原 attempt，先核对，不自动重发。没有可靠 lookup 时返回 unknown，不用文本搜索伪造“确定未送达”。
- 原生历史、当前加载会话和真实窗口可见性分别报告；超出读取预算时明确 partial，不无界加载整个历史。
- Agent 通过自己的 DJ CLI/MCP/API/GEPO 身份调用回复工具；端口不借 operator 凭据自动代发。

## 可选创建与实例生命周期

`session.create` 仅在已有实例确实提供原生创建接口、获准工作区和身份核验通过时受理。创建为空，不附 prompt，不自动登记或订阅。缺少接口时，在生成无法执行的动作前返回 unsupported。

正式已有实例端口不因 DJ 停机而关闭用户的客户端。实例启动或停止的接口描述存在，不代表当前配置装配了可执行端口；以能力与权限检查为准。

## 实现与参考

生产装配在 `src/host/bun/io.eli`，端口位于 `src/adapters/agent/`。协议参考见[官方资料](../references/official-sources.md)，版本敏感的 Cursor 原生接口见[本机接口记录](cursor-native.md)。
