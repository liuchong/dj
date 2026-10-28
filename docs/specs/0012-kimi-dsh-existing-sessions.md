# 0012 — Kimi 与 DSH 已有实例接入

以 kimi、dsh 两类工具接入四种本机形态：Kimi Desktop Work control.v1 WebSocket、Kimi Code Web REST、DSH Desktop Host Typert 和 DSH Web RPC。native_provider 明确区分形态，instance_id 与 native_namespace 隔离实例。共用历史不代表桌面当前打开或最初创建归属。

原生列表、状态及消息读取进入统一目录，原授权和实例门核对后向准确原会话输入，取得接收回执。支持通过已有实例显式创建空会话，不附带 prompt、不改变已有模型或自动批准权限。普通 Kimi TUI 没有收件接口时明确不支持，不能启动替代进程。

每次请求核对当前用户 PID、启动代次、程序、原生注册信息和实际监听归属。桌面核对主进程与后端亲缘，DSH Web 核对安装包及 web 形态。仅数字 loopback，不使用环境代理，不跟随重定向。token/cookie 仅从准确实例的原生文件读取，不放入引用、日志、命令行或仓库。

只读请求可协商协议；写入不确定时不换协议重发。旧实例代次引用拒绝，重启需重新发现。migration-required 和无可用 Agent 的历史不隐式迁移。保留 submitting、幂等与审计，不使用 UI、Inspector、Agent CLI 或终端注入。

默认输入方式由准确端口能力决定：DSH 原生 steer、Kimi Web prompts 原生受理；原生处理时点不等于 DJ 业务完成。Kimi Work 未确认忙时接口前明确受阻，可显式 queue。Kimi Work 只覆盖 client-origin Work，不覆盖普通 Chat。

消息页只发布 user/assistant 文本与安全状态，过滤 reasoning、工具负载和 injection；游标绑定原会话与实例，遵守条数、字节和期限预算。模型凭据或额度失败与传输受理分别记录。

先一次完成业务和配置、Skill、说明，再集中做本批定向集成与四种现有实例验证，最后补关键保护性单测。不重跑其他工具和性能矩阵。

## 本批状态

- [x] 四种形态的统一端口、原生鉴权/进程证明、Core 装配、配置与 Skill 接线。
- [x] Core 与真实 loopback 协议定向集成、关键保护性单测通过；不重跑其他工具矩阵。
- [x] 四种现有实例均由完整 Core 创建专用空会话、提交一次并读回原输入；Work 与 DSH Desktop 另取得准确回复，两个 Web 端未取得模型回复，不据此否定传输受理。
- [x] 本机服务更新为 ready，保留原配置并接入四种已有实例；经安装后的统一接口刷新并读回四份原输入。Kimi 共享 Skill 与 DSH 专用 Skill 文件核对一致，未自动修改客户端 MCP/信任，也不把安装等同于会话已采用。
