# Skill 设计与分发

## 当前产物与边界

DJ 本身没有 AI。Skill 在调用方模型中加载，帮助其正确使用无 AI 的中转服务；不会给 DJ 注入理解、总结或智能路由能力。

[skills/dj/SKILL.md](../skills/dj/SKILL.md) 按 Agent Skills 格式组织，随目录包交付；`dj skill install` 可显式复制完整目录，`check` 核对摘要，`config` 生成 MCP 片段。客户端发现与实际采用仍需独立确认。名称 dj 与目录一致，description 聚焦跨 IM 订阅、登记、回复和投递诊断；不承接普通代码修改或所有 Agent 控制任务。

Skill 教模型定位自身目标、选择来源、生成确定性规则、建立订阅、处理注入信封、回复与诊断。它不持有 token，不启动隐藏守护进程、不创建定时器、不自动批准工具请求，也不替代适配器协议实现。核心步骤短文放 SKILL.md，具体例子与故障放 references。

[会话控制参考](../skills/dj/references/control.md)：跨工具/实例范围检索、已知会话直发、受原生能力约束的显式空会话创建。该分支不要求已登记目标或 IM 订阅，不把 whoami 未绑定当成不能查询；动作仍受 scope/grants 约束。模型依据事实/片段作判断，服务只机械查询，不替用户选任务位置。

格式依据 [Agent Skills 规范](https://agentskills.io/specification)和[客户端接入说明](https://agentskills.io/client-implementation/adding-skills-support)。厂商扩展字段不进入共享必需元数据；暂不写 allowed-tools 或自动执行 hooks。

## 发现与安装设计

目录包已携带自包含的完整 skill 目录，不要求安装后依赖开发仓库。使用 `dj skill targets` 查看目录，`dj skill install --target TOOL --scope user|project` 显式安装；项目级必须加 `--project DIRECTORY`。`--dry-run` 不写入，相同内容重复安装返回 unchanged，不同内容或链接拒绝并保留。安装与注册 MCP 是两项独立操作；`dj skill config --target TOOL --client-profile FILE` 仅生成配置片段。完整说明见[客户端接线](../skills/dj/references/clients.md)。

| 产品 | 官方项目入口/候选 | 官方用户入口/候选 | 说明 |
| --- | --- | --- | --- |
| Codex | .agents/skills | ~/.agents/skills | 按当前 Build skills 与安装版本核验 |
| Claude Code | .claude/skills | ~/.claude/skills | 产品的权限/显式调用扩展另验 |
| Cursor | .agents/skills 或 .cursor/skills | ~/.agents/skills 或 ~/.cursor/skills | 本地、远程与云同步范围不同 |
| OpenCode | .agents/skills 或 .opencode/skills | ~/.agents/skills 或 ~/.config/opencode/skills | skill 读取仍受权限控制 |
| Pi | .agents/skills | ~/.agents/skills | 显式调用语法为 /skill:dj，不能假设都是 /dj |
| Antigravity 桌面 | .agents/skills | ~/.gemini/config/skills | 桌面与 CLI 原生目录分别处理 |
| agy | .agents/skills | ~/.gemini/antigravity-cli/skills | 正文展开不保证所有 references 被允许读取 |

以上目录已于 2026-10-27 按官方文档复核，仍需对安装版本确认，不把它们写成通用全局规则路径。各链接见 [官方目录](references/official-sources.md)。不自动改 AGENTS.md/GEMINI.md、不承诺所有产品每轮自动触发。

## 采用验证

分别检查：文件可读 → 客户端发现名称/描述 → 正文与按需参考实际读入 → 正确使用接口。安装成功、一个 OK 回复或一个成功退出码，都不能证明规则被采用。

行为场景包含：工具名与会话标题冲突、同名候选、只有历史没有 live receiver、引用类型混淆、preview 后改规则、操作台账查回、无回复权限、自身消息回流、发送超时、原生权限 pending、正文被截断。模型应沿用明确目标，不能新建进程冒充已有会话；未知投递先核对，不能换幂等键重发。

安装器在隔离项目验证，不据此启动所有工具的模型测试。当前优先 Codex/Cursor；采用时记录 Skill 路径、正文摘要、实际工具调用与证据。模型权限拒绝时保留未读/未执行状态，不借另一个工具绕过。

## 接口与 Skill 的分工

模型使用发现结果的精确引用，检查 preview 的解析摘要并提交同一 preview_id。服务独立校验字段、权限、句柄、revision 与幂等；不能只写一句“模型要仔细”。错误给字段路径和确定的下一步操作，Skill 教模型读取结构而不是猜报错文本。正常主路径无额外审批，只有当前授权或用户意图确实缺失时才询问；DJ 自己不提自然语言澄清问题。

## 客户端接线

Codex、Cursor、Claude Code、OpenCode、Pi 和 Antigravity 的目录与配置方式见[客户端接线参考](../skills/dj/references/clients.md)。Pi/shared 使用 DJ CLI，不假设客户端内置 MCP；DJ CLI 调用已有服务，不是新建 Agent 进程。凭据与准确目标由可信配置面接线，接收方先用 whoami 核对绑定。安装 Skill 本身不创建目标或订阅；实际采用情况见[当前状态](status.md)。部署顺序见[完整流程](startup-to-reply.md)。
