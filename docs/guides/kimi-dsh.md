# Kimi 与 DeepSeek Harness

DJ 直接连接本机已经运行的原生服务，提供目录、状态、历史、准确会话输入与显式空会话创建。工具 ID 为 kimi、dsh；形态使用 native_provider 区分，不建立同品牌多套业务逻辑。

| 形态 | native_provider | 接口与边界 |
| --- | --- | --- |
| Kimi Desktop Work | kimi-desktop | 原生 runner state、control.v1 WebSocket；仅 client-origin Work，不能当作普通 Chat |
| Kimi Code Web | kimi-web | 原生 server registry、REST；不接管普通 TUI |
| DSH Desktop | dsh-desktop | 原生 Host Typert、同 authority 的 Cookie；共享历史不等于桌面打开 |
| DSH Web | dsh-web | 现有 Web 服务；只读协商原生 RPC，写入不做协议重试 |

## 配置

每个 agent_endpoints 条目明确 tool、native_provider、instance_id、native_namespace、ownership=existing、endpoint_ref、base_url、directory、workspace_ref 以及 process_binding。同一后台可按授权工作区配置独立实例；目录与命名空间不能混用。

process_binding 包括 pid、process_birth、process_helper_ref、executable_ref。部署使用包内 libexec/dj-process-info 读取当前用户进程元数据，不启动 Agent。桌面还要 parent_pid、parent_birth、parent_executable_ref；DSH Web 另需 entry_ref、package_ref 指向实际 @deepseek-ai/dsh 安装入口和 package.json。

Kimi Work 的 registry_path 指向原生 runner.state.json，base_url 使用其中的动态 WS /control；Kimi Web 的 registry_path、data_root、credential_ref 分别来自原生 server/instances 注册文件、当前数据根及同根 server.token。DSH Desktop 的 cookie_database 指向原生 Cookie 数据库，只读匹配准确 authority 的明文 Cookie；加密或缺失则拒绝，不解密或搬用其他实例凭据。DSH 显式 credential_ref 必须为私有 JSON，包含与 base_url 完全相同的 endpoint 及 cookie。

端口、PID、启动身份必须从真实实例读取，不能照抄例值。配置文件保持私有，不把本机实际参数或账号凭据提交。每次请求重验进程和监听归属；旧进程重启后先重新发现再更新绑定，未知发送不可借换实例重试。

## 使用

使用统一 session.list/get/probe/send 和 session.message.list/get；已知实例及原生 ID 先 session.resolve。命名空间、工作区和原生会话必须完全匹配，标题只用于查找。session.create 创建空会话，不自动输入；某原生空会话还未配置模型时，由原客户端或明确的原生设置操作处理，DJ 不替已有会话选模型。

DSH 忙时输入使用原生 steer；Kimi Web 使用原生 prompts 受理；原生内部处理时点不等于 DJ 完成。Kimi Work 未核实忙时追加前明确不支持，可显式 queue 等待空闲。native accepted、原文读回、模型完成分别判断；模型额度或凭据错误不能冒充发送未受理。

列表与历史按原生游标分页，scope/coverage 明确保留。历史只包含 user/assistant 文本，不发布思考、工具参数或注入内容。migration-required 的 DSH 历史可以被发现但不会隐式迁移或派发。旧 DSH Web 不提供 agentAvailable，保留缺失，以其原生 running 状态和准确可寻址会话判定输入；不把缺失字段补成 true，也不把 Web 历史当作桌面 Agent。

## Skill、MCP 与 GEPO

dj skill install/check --target kimi 使用共享 .agents/skills；Kimi Code 的共享扫描目录可以发现它，Work 可显式读取同一完整 Skill。dsh 目标使用 .dsh/skills；原生 DSH 也能读取共享 .agents/skills。自定义数据根按原生说明单独安装，不声称默认路径覆盖所有 profile。

Kimi Code 可用 dj skill config --target kimi --client-profile 生成 mcpServers.dj 的 stdio 片段，手工合并到本实例 mcp.json，保留其余配置和信任；新增 MCP 是否进入已有会话以原生生命周期为准。DSH 不猜测插件化 MCP 配置格式；使用独立 DJ profile 的 CLI 或支持私有 UDS 的 GEPO 接口，宿主提供 MCP 时再使用同一 dj mcp serve 桥。不得借用 operator 或其他会话凭据。

正式边界见 [0012](../specs/0012-kimi-dsh-existing-sessions.md)。
