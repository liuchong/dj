# 官方资料目录

查阅日期：2026-10-23（北京时间）。范围是本轮设计实际参考的相关官方规范、产品集成、控制、MCP、Skill 与 IM 资料，不是对各厂商整站的镜像或穷尽清单。记录链接和独立摘要，不复制整篇文档。后续实现应记录安装版本、明确协议版本，并把必要源代码/发布资源固定到实际 release 或 commit。

状态：**已访问**=官方页面或官方仓库文档可读取；**正文受限**=官方入口存在但本轮浏览结果没有可读正文。已访问不代表执行过命令、验证过账号或兼容所有发布版本。GitHub 的 main 链接是可变资料定位符，不是假装已固定的依赖。

<a id="mcp"></a>
## MCP 与基础协议

| ID | 官方资料 | 用途与适用边界 | 状态 |
| --- | --- | --- | --- |
| MC01 | [MCP 2026-07-28 规范](https://modelcontextprotocol.io/specification/2026-07-28) | 本轮新接口的明确版本基线 | 已访问 |
| MC02 | [规范发布与变更](https://blog.modelcontextprotocol.io/posts/2026-07-28/) | 无状态核心、每请求能力、MRTR、扩展与弃用变化；不照搬旧初始化 | 已访问 |
| MC03 | [Tools](https://modelcontextprotocol.io/specification/2026-07-28/server/tools) | 工具发现、参数、结构化结果与错误 | 已访问 |
| MC04 | [Transports](https://modelcontextprotocol.io/specification/2026-07-28/basic/transports) | 传输边界；选择 stdio/HTTP 时继续查其绑定规范 | 已访问 |
| MC05 | [Authorization](https://modelcontextprotocol.io/specification/2026-07-28/basic/authorization) | HTTP 授权；不把 stdio 身份与 HTTP OAuth 混用 | 已访问 |
| MC06 | [Resources](https://modelcontextprotocol.io/specification/2026-07-28/server/resources) | 可选只读上下文，不能据此承诺模型唤醒 | 已访问 |
| MC07 | [安全最佳实践](https://modelcontextprotocol.io/docs/2026-07-28/tutorials/security/security_best_practices) | 代理身份、token、状态句柄和本地服务边界 | 已访问 |
| MC08 | [2025-11-25 规范](https://modelcontextprotocol.io/specification/2025-11-25) | 旧宿主适配的明确版本，不能与新核心拼接 | 已访问 |
| MC09 | [官方资料索引](https://modelcontextprotocol.io/llms.txt) | 规范版本、SDK、调试、传输与扩展的后续入口 | 已访问 |
| RPC01 | [JSON-RPC 2.0](https://www.jsonrpc.org/specification) | 请求 ID、响应、通知与协议错误；不定义 Agent 唤醒 | 已访问 |

MC01 的可变 latest 入口本轮解析到该日期版本。实现时记录实际 SDK 支持，不能仅靠网页 latest 决定客户端协议。旧 2025-06-18 子页面的若干路径本轮不可访问，未作为当前规范证据。

<a id="skills"></a>
## Agent Skills

| ID | 官方资料 | 用途与边界 | 状态 |
| --- | --- | --- | --- |
| SK01 | [Agent Skills Specification](https://agentskills.io/specification) | SKILL.md、name/description、目录与可选资源格式 | 已访问 |
| SK02 | [为 Agent 接入 Skills](https://agentskills.io/client-implementation/adding-skills-support) | 发现、渐进披露、激活、冲突与信任 | 已访问 |

共同格式不保证共同安装目录、刷新时机或额外工具权限；各产品的 Skill 文档分别见下列目录。厂商扩展元数据不能升级为跨产品必需字段。

<a id="codex"></a>
## Codex / OpenAI

| ID | 官方资料 | 用途与边界 | 状态 |
| --- | --- | --- | --- |
| CX01 | [Codex App Server](https://learn.chatgpt.com/docs/app-server) | 线程、回合、事件、审批；公开托管控制基线，不涵盖桌面私有 IPC | 已访问 |
| CX02 | [Build skills](https://learn.chatgpt.com/docs/build-skills) | Skill 格式、发现、项目/用户目录与分发 | 已访问 |
| CX03 | [Codex MCP](https://developers.openai.com/codex/mcp) | CLI MCP 配置与接入；本轮重定向至 Learn 的 extend/mcp 页面 | 已访问 |
| CX04 | [CLI reference / Developer commands](https://developers.openai.com/codex/cli/reference) | 原生命令、运行方式与版本相关参数 | 已访问 |

历史 developers.openai.com/codex/skills 入口本轮重定向到 CX02。直接猜测的 Learn docs/mcp 返回 404，已改用 CX03，不保留失效链接作为有效入口。公开 App Server 和已有桌面 owner IPC 的保证分别记录。

<a id="claude"></a>
## Claude Code

| ID | 官方资料 | 用途与边界 | 状态 |
| --- | --- | --- | --- |
| CL01 | [Cross-session messaging](https://code.claude.com/docs/en/cross-session-messaging) | 会话发现、inbox、接收控制与版本条件 | 已访问 |
| CL02 | [Channels](https://code.claude.com/docs/en/channels) | 运行会话接收外部推送；需显式启用与满足产品策略 | 已访问 |
| CL03 | [Headless](https://code.claude.com/docs/en/headless) | 非交互工作、会话继续和输出；不等于 existing attach | 已访问 |
| CL04 | [Skills](https://code.claude.com/docs/en/skills) | 本地技能、作用域、正文和厂商扩展 | 已访问 |
| CL05 | [MCP](https://code.claude.com/docs/en/mcp) | 服务配置、作用域、工具与通道入口 | 已访问 |
| CL06 | [Settings](https://code.claude.com/docs/en/settings) | 原生配置优先级与权限；不自动修改配置 | 已访问 |

CL02 是有条件的宿主能力，普通 MCP 连通不表示 Channels 可推送。CL01 的 hold/refuse、非交互会话和平台版本条件应在安装版本上复核。

<a id="cursor"></a>
## Cursor

| ID | 官方资料 | 用途与边界 | 状态 |
| --- | --- | --- | --- |
| CU01 | [CLI ACP](https://cursor.com/docs/cli/acp) | 公开 stdio 会话与提示控制、权限回调 | 已访问 |
| CU02 | [Headless CLI](https://cursor.com/docs/cli/headless) | 非交互执行与结构化输出 | 已访问 |
| CU03 | [SDK Bridge](https://cursor.com/docs/sdk/bridge) | 官方 SDK 的 Connect/protobuf 服务与进程管理；不同于实验 Desktop Bridge | 已访问 |
| CU04 | [MCP](https://cursor.com/docs/mcp) | MCP 配置、传输与工具 | 已访问 |
| CU05 | [Agent Skills](https://cursor.com/docs/skills) | 项目/用户目录、远程与云端分发边界 | 已访问 |

旧 context/mcp、context/skills 本轮分别重定向至 CU04/CU05。SDK Bridge 支持 SDK Agent 不能证明原来打开的桌面会话由它接管。

<a id="opencode"></a>
## OpenCode

| ID | 官方资料 | 用途与边界 | 状态 |
| --- | --- | --- | --- |
| OC01 | [Server](https://opencode.ai/docs/server/) | HTTP、会话、prompt_async、事件与已有服务连接 | 已访问 |
| OC02 | [ACP Support](https://opencode.ai/docs/acp/) | ACP 接入候选，与 HTTP 是独立协议面 | 已访问 |
| OC03 | [MCP servers](https://opencode.ai/docs/mcp-servers/) | 本地/远程 MCP 配置和工具 | 已访问 |
| OC04 | [Agent Skills](https://opencode.ai/docs/skills/) | 可发现路径、格式和读取权限 | 已访问 |

S2 接线时再次读取 OC01：Messages 表明确 `prompt_async` 使用与 message 相同的请求体，允许 messageID，返回 204；消息详情可按 ID 查询。代码据此绑定 dispatch/messageID 并只采用正向接受证据，不推断原生幂等或未送达。该页未证明当前目标服务的具体 ID 字符校验、原生版本或实际送达；这些保留 A16/A20 核验。

HTTP API 不能单独解释桌面当前 Tabs；共享历史与窗口归属需独立证据。

<a id="pi"></a>
## Pi

| ID | 官方资料 | 用途与边界 | 状态 |
| --- | --- | --- | --- |
| PI01 | [RPC Mode](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/rpc.md) | 长期子进程、JSONL、背压、命令与运行生命周期 | 已访问，另核对官方 raw 正文 |
| PI02 | [RPC Commands](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/rpc-commands.md) | prompt、steer、follow_up、命令 disposition | 官方 raw 正文已访问 |
| PI03 | [JSON Event Stream](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/json.md) | 原生事件、agent_end/agent_settled 区别 | 官方 raw 正文已访问 |
| PI04 | [SDK](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/sdk.md) | 进程内集成候选；与 RPC 隔离模式分开 | 已访问 |
| PI05 | [Skills](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/skills.md) | 共同格式、发现与 /skill:name 显式调用 | 已访问，另核对官方 raw 正文 |

Pi 的可编程 RPC 不意味着任意已经打开的普通 TUI 可附着。本轮未找到需要依赖的内建通用 MCP 客户端保证，因此 DJ Skill 的可移植最低入口保留 CLI；未来 MCP 桥接须另行验证。

<a id="antigravity"></a>
## agy / Antigravity

| ID | 官方资料 | 用途与边界 | 状态 |
| --- | --- | --- | --- |
| AG01 | [Headless mode](https://www.antigravity.google/docs/cli/headless/) | stream-json 连续输入、回合结果与进程结束 | 已访问 |
| AG02 | [Resume](https://www.antigravity.google/docs/cli/commands/resume/) | 指定会话恢复、桌面历史导入与新进程边界 | 已访问 |
| AG03 | [Agent skills](https://www.antigravity.google/docs/skills/) | App、CLI、项目和用户级目录分别核对 | 已访问 |
| AG04 | [Rules](https://www.antigravity.google/docs/rules/) | 规则作用域和原生入口；与 Skill 安装不同 | 已访问 |
| AG05 | [MCP](https://www.antigravity.google/docs/mcp/) | 各形态服务配置与工具入口 | 已访问 |
| AG06 | [Remote Control](https://www.antigravity.google/docs/remote-control/) | 官方远程控制的范围与条件；本轮未启用、未作为已接管证据 | 已访问 |
| AG07 | [官方 CLI 仓库](https://github.com/google-antigravity/antigravity-cli) | 独立 CLI 的安装、发布和资料定位 | 已访问 |

桌面 language_server 私有 RPC 的发现与原生存储解析属于版本敏感研究，不因以上官方文档而变为公开稳定接口。agy stream-json 不是 ACP。

<a id="acp"></a>
## ACP

| ID | 官方资料 | 用途与边界 | 状态 |
| --- | --- | --- | --- |
| AC01 | [v1 Initialization](https://agentclientprotocol.com/protocol/v1/initialization) | 能力与版本初始化，认证前提 | 已访问 |
| AC02 | [v1 Session Setup](https://agentclientprotocol.com/protocol/v1/session-setup) | 新建/加载会话、MCP 配置交接 | 已访问 |
| AC03 | [v1 Prompt Turn](https://agentclientprotocol.com/protocol/v1/prompt-turn) | 输入、更新、工具请求与回合结果 | 已访问 |

本轮官方导航将 v1 标为 Latest，v2 标为 Draft；未把草案方法混入 v1 适配。ACP 不提供通用的任意现有终端进程接管保证。

<a id="im"></a>
## IM

| ID | 官方资料 | 用途与边界 | 状态 |
| --- | --- | --- | --- |
| IM01 | [Telegram Bot API](https://core.telegram.org/bots/api#getting-updates) | 更新接收互斥、游标、消息与回复 | 已访问 |
| IM02 | [Slack Socket Mode](https://docs.slack.dev/apis/events-api/using-socket-mode/) | 动态 WebSocket、事件信封与确认 | 已访问 |
| IM03 | [Slack Events API](https://api.slack.com/apis/connections/events-api) | HTTP/Socket 接收及订阅定位 | 已访问；本轮重定向至 docs.slack.dev/apis/events-api/ |
| IM04 | [Discord Gateway](https://docs.discord.com/developers/events/gateway) | intents、心跳、session/sequence、resume 与事件范围 | 已访问 |
| IM05 | [飞书消息概述](https://open.feishu.cn/document/uAjLw4CM/ukTMukTMukTM/reference/im-v1) | 消息事件、接收权限、消息操作的官方入口 | 正文受限 |
| IM06 | [飞书事件订阅方式](https://open.feishu.cn/document/server-docs/event-subscription-guide/event-subscription-configure-/request-url-configuration-case) | 事件接收配置官方入口 | 正文受限 |


## 维护方式

每次修改受影响协议时检查相应条目的重定向、版本和相关正文，再更新实际访问日期；不为日期刷新无关资料。失效入口标明替代或限制，不用第三方转载冒充官方规范。官方网页与原始研究都不能覆盖 DJ 自身的授权与状态语义。

<a id="eliscript-runtime"></a>
## Eliscript、宿主与技术选型补充

本节于 2026-10-23 新增。EL 条目是对下述固定 commit 的本地源码/文档只读核对，链接用于持久定位；没有把线上网页访问或语言测试当作已完成。曾尝试的站点 getting-started.html 不能读取，故不列为有效资料。其他条目本轮实际读取官方正文；npm 精确补丁版本与兼容实测仍待实现阶段锁定。

| ID | 官方资料 | 用途与适用边界 | 状态 |
| --- | --- | --- | --- |
| EL01 | [Eliscript README](https://github.com/liuchong/eliscript/blob/b1c7741365545d5a048079d64f863524cf7117e2/README.md) | ESM、工具链、发布包与能力入口；不是 DJ 编译验收 | 固定本地源码已读 |
| EL02 | [JavaScript interoperation](https://github.com/liuchong/eliscript/blob/b1c7741365545d5a048079d64f863524cf7117e2/docs/javascript-interop.md) | 包导入、宿主对象与 false/null/undefined 保真 | 固定本地源码已读 |
| EL03 | [Project configuration](https://github.com/liuchong/eliscript/blob/b1c7741365545d5a048079d64f863524cf7117e2/docs/project-configuration.md) | 多入口、源码/产物边界、构建与缓存 | 固定本地源码已读 |
| EL04 | [0.1.0 正式语法](https://github.com/liuchong/eliscript/blob/b1c7741365545d5a048079d64f863524cf7117e2/docs/emacs-compatible-syntax.md) | 当前显式扩展与宿主边界；不从旧提案推断当前支持 | 固定本地源码已读 |
| RT01 | [Bun SQLite](https://bun.com/docs/runtime/sqlite) | 内置同步驱动、事务与 WAL 接口；实际内嵌 SQLite 版本另查 | 已访问 |
| RT02 | [Bun HTTP server](https://bun.com/docs/runtime/http/server) | HTTP/1.1 与 Unix socket 的本地控制入口 | 已访问 |
| RT03 | [Bun child processes](https://bun.com/docs/runtime/child-process) | 参数数组、管道、流及退出；不使用 shell 拼正文 | 已访问 |
| RT04 | [Bun fetch](https://bun.com/docs/runtime/networking/fetch) | 网络流、取消与 UDS 客户端；不等于任意 Agent SDK | 已访问 |
| DB01 | [SQLite WAL](https://sqlite.org/wal.html) | 本地持久存储、checkpoint 与 WAL-reset 修复版本 | 已访问 |
| DB02 | [SQLite synchronous](https://sqlite.org/pragma.html#pragma_synchronous) | FULL/NORMAL 的耐久性差异，启动需读回设置 | 已访问 |
| SC01 | [Ajv JSON Schema](https://ajv.js.org/json-schema.html) | draft 2020-12 模式选择与严格输入契约 | 已访问 |
| SC02 | [Ajv options](https://ajv.js.org/options.html) | 禁止类型转换、移除字段及验证阶段补默认 | 已访问 |
| MC10 | [官方 TypeScript SDK 仓库](https://github.com/modelcontextprotocol/typescript-sdk) | v2 稳定线与 v1 分支区分；SDK 可用于 Bun | 已访问 |
| MC11 | [SDK v2 文档](https://ts.sdk.modelcontextprotocol.io/v2/) | 2026-07-28 基线、stdio 服务和 schema 接线入口 | 已访问 |


## 统一 Agent 控制面追加资料

追加于 2026-10-23。OC01、PI01/PI02 本轮再次读取，用于会话列表/创建、显式启动、RPC 当前会话读取及 new_session 边界；没有运行原生命令或连接任何已有接收器。以下两项为新增官方资料，索引/控制面方案是 DJ 设计选择，不是官方对 DJ 的保证。

| ID | 官方资料 | 用途与适用边界 | 状态 |
| --- | --- | --- | --- |
| OC05 | [OpenCode CLI](https://opencode.ai/docs/cli/) | serve、现有实例连接和会话命令入口；不证明桌面当前 Tab | 已访问 |
| DB03 | [SQLite FTS5 trigram](https://sqlite.org/fts5.html#the_trigram_tokenizer) | 字面子串候选索引、短串限制、原文复核与有界扫描设计 | 已访问 |

## 施工与测试资料补充

施工文档轮次于 2026-10-23 读取下述官方正文；没有运行 Bun 测试、构建 DJ 或安装依赖。EL03 的同一固定源码快照项目配置和 package bin 声明亦作只读复核，用于 schemaVersion=2/entries/sourceRoot/outDir 和 eliscript-build 命令接线；没有刷新编译器版本或声称当前编译通过。

| ID | 官方资料 | 用途与适用边界 | 状态 |
| --- | --- | --- | --- |
| RT05 | [Bun Test runner](https://bun.com/docs/test) | .test.mjs、bun:test、明确文件选择；用于测试实施，不代表 Eliscript 互操作已验证 | 已访问 |
| RT06 | [Bun Test Reporters](https://bun.com/docs/test/reporters) | 原生 JUnit/逐例结果与报告文件参数，分段计时由薄 fixture 补充 | 已访问 |

## 开工准备补充资料

2026-10-23 施工准备轮次重新读取 MC11，并读取以下官方资料；npm registry 网页访问失败后改用只读 HTTPS JSON 元数据请求，不安装/执行包。包名/精确版本/SRI/依赖图与逐包URL归档于 [依赖准备](../archive/readiness.md)，SRI属于发布元数据而非已下载校验。只读重核固定 Eliscript 源身份/内容摘要，并查询本机版本/基础资源，没有产品测试、源码改动或账号连接。

| ID | 官方资料 | 用途与适用边界 | 状态 |
| --- | --- | --- | --- |
| MC12 | [SDK v2 packages](https://ts.sdk.modelcontextprotocol.io/v2/get-started/packages.html) | server包/子路径与传递依赖边界，不引入MCP client/HTTP框架 | 已访问 |
| MC13 | [SDK schema libraries](https://ts.sdk.modelcontextprotocol.io/v2/advanced/schema-libraries.html) | fromJsonSchema/validator绑定及高层校验边界；DJ保持单一业务schema | 已访问 |
| MC14 | [SDK low-level Server](https://ts.sdk.modelcontextprotocol.io/v2/advanced/low-level-server.html) | 自有tools/list/call分派、参数校验与serveStdio工厂；用于统一错误接线选择 | 已访问 |
| MC15 | [SDK stdio](https://ts.sdk.modelcontextprotocol.io/v2/serving/stdio.html) | Server工厂、stdout/stderr、EOF/关闭归属；不将代理退出视为DJ停止 | 已访问 |
| PK01 | [npm官方精确包元数据](https://registry.npmjs.org/@modelcontextprotocol%2fserver/2.3.1) | SDK/Ajv及其依赖、Bun arm64、Eliscript候选的发布元数据；其余逐包精确URL见readiness | HTTPS JSON已读取；网页工具受限 |
| RT07 | [Bun installation](https://bun.com/docs/installation) | 目标宿主/平台及固定版本安装入口；本轮未安装或升级 | 已访问 |

<a id="lark-user-sources"></a>
## Lark 用户收件的历史准备记录

以下保留 2026-10-23 的查阅记录，不是当前接入方式。正式路径见[IM 适配](../adapters/im.md)与[0001](../specs/0001-lark-realtime-subscriptions.md)，直接连接官方 WebSocket/HTTPS，不使用 CLI 或 SDK。

当时核对安装 CLI 1.0.76 的 event list/schema 与 chat/thread list、reply、auth login、config init help；仅静态查询，没有登录或读取账号。新版本在线 CLI 文档的选项可能比当前多，当时核对以固定安装版本为准；例如本机未证支持的 page-all 不能套入循环。

| ID | 官方资料 | 用途与适用边界 | 状态 |
| --- | --- | --- | --- |
| IM07 | [官方 CLI IM Skill](https://github.com/larksuite/cli/blob/main/skills/lark-im/SKILL.md) | user 列表/话题/回复、正文和 enrichment 边界；本机 help 是选项落地证据 | 官方正文已读，本机只读核对 |
| IM08 | [Lark chat history](https://open.larksuite.com/document/server-docs/im-v1/message/list) | 用户历史读取的权限/分页入口；DJ 内部增量读取依据，不开放公共 native 查询 | 国际页面返回壳；官方搜索摘要及本机 CLI 合同可读，真实权限待测 |
| IM09 | [Lark user authorization overview](https://open.larksuite.com/document/server-docs/getting-started/authen-v1/build-login-free-system-) | user_access_token 需用户授权，App 凭证不等于用户身份；CLI device flow 另核本机 help | 官方搜索正文可读；未执行 OAuth |
| IM10 | [Lark receive message](https://open.larksuite.com/document/uAjLw4CM/ukTMukTMukTM/reference/im-v1/message/events/receive) | 区分机器人消息事件与用户读取；CLI event list 的 IM auth_types 仅 bot，不声称无条件支持 user 推送 | 官方事件说明/CLI 静态合同；没有用户事件实证 |

这一轮曾提出有界轮询，现已被正式实时规格取代；不得据此恢复轮询接线。历史准备细节见[归档资料](../archive/readiness.md)，各官方资料的读取日期和权限局限仍按表内记录保留。

## S1 原生协议与存储用例资料

2026-10-23 再读 OC01、PI01–PI03、RT01，作为原生对端用例输入；未启动对端或运行测试。新增资料如下，归属 I05/I06，运行证明仍在 S3。

| ID | 官方资料 | 用途与适用边界 | 状态 |
| --- | --- | --- | --- |
| DB04 | [SQLite VACUUM INTO](https://www.sqlite.org/lang_vacuum.html#vacuum_with_an_into_clause) | 一致性快照备份/WAL与中断边界；DJ的Store.backup为可信内部端口，不新增公共操作 | 已读取 |
| DB05 | [SQLite max_page_count](https://www.sqlite.org/pragma.html#pragma_max_page_count) | 限制单个隔离测试库触发SQLite FULL；不填满主机卷、不声称卷ENOSPC实证 | 已读取 |
| DB06 | [SQLite UPSERT](https://sqlite.org/lang_upsert.html) | 2026-10-24读取；显式主键冲突目标的DO NOTHING只处理对应唯一性冲突，不接管NOT NULL/CHECK/外键失败；用于insertIfAbsent去重合同，运行边界仍由T40验证 | 已读取 |
| DB07 | [SQLite ON CONFLICT](https://sqlite.org/lang_conflict.html) | 2026-10-24读取；区分UPSERT与OR IGNORE等广义冲突算法，避免把非法数据静默当成已存在 | 已读取 |
| DB08 | [SQLite cache_size](https://www.sqlite.org/pragma.html#pragma_cache_size) | 2026-10-24读取；连接级数据库页缓存建议上限，负值为KiB且按需分配；不同于驱动Statement查找缓存。官方默认不替代当前Bun连接实测，不据WAL总大小自动调参 | 已读取 |
| DB09 | [SQLite cache_spill](https://www.sqlite.org/pragma.html#pragma_cache_spill) | 2026-10-24读取；允许事务中溢写脏页，默认开启；阈值与cache_size共同约束，需实际事务/WAL证据再评估，不能直接关闭来掩盖内存增长 | 已读取 |
| DB10 | [SQLite connection status](https://www.sqlite.org/c3ref/db_status.html) / [counter meanings](https://www.sqlite.org/c3ref/c_dbstatus_options.html) | 2026-10-24读取；连接级pager hit/miss/write/spill的原生定义；未获得实际计数时不将WAL长度代称spill计数 | 已读取 |
| DB11 | [SQLite loadable extensions](https://www.sqlite.org/loadext.html) | 2026-10-24读取；扩展通过当前连接提供的API表访问SQLite；能否加载须以固定运行时验证，不能为诊断暗换数据库引擎 | 已读取 |
| RT10 | [Bun SQLite handle](https://bun.com/reference/bun/sqlite/Database/handle) | 2026-10-24读取；handle是内部句柄数组索引，不能当作sqlite3指针传入FFI；文档不替代固定Bun运行时能力验证 | 已读取 |

OpenCode/Pi 的本期原生字段及失败断言落实在 tests/integration/agent.test.eli，存储用例在 tests/integration/storage.test.eli；这些路径表示源码位置，不能作为厂商支持或运行通过的证据。

I06/I07 续写时重新读取 [IM01 getUpdates](https://core.telegram.org/bots/api#getupdates)、[sendMessage](https://core.telegram.org/bots/api#sendmessage)和[ReplyParameters](https://core.telegram.org/bots/api#replyparameters)，用于持久处理后推进offset与精确回复的测试输入。另只读固定本机 CLI 的 `im +messages-reply --help`、`im +messages-send --help`，核对 profile/as user、message-id/reply-in-thread与纯文本参数；未执行发送、dry-run、登录或账号查询。它们是协议/帮助证据，源收件/单条回复/429未送达分类仍须由最终实际运行验证。

I08 资源字段只读核对本机 macOS SDK 的 libproc.h/sys/resource.h，并读取 [Apple XNU resource.h](https://raw.githubusercontent.com/apple-oss-distributions/xnu/main/bsd/sys/resource.h)；确认 resident size、physical footprint 和进程出生时间是不同字段。在线 Libc/include/libproc.h 定位返回404，函数声明依据本机官方 SDK，不把失败链接当已读正文。没有调用 proc_pid_rusage 或运行资源测试。

编译器准备复用已定位的 Eliscript 本地固定 SHA b1c7741365545d5a048079d64f863524cf7117e2，未更新/切换共享检出；读取 bootstrap-runtime.el、bootstrap-seed.el、backends/bootstrap.el、compiler-build.eli 与 release-cli.eli，固化 Emacs seed→自举→目录包的重建输入。隔离树只复制固定源与已绑定摘要的生成源；未运行编译器、发布器或上游测试。实际 source closure 见 config/compiler-source-inputs.json，不把准备记录当新的语言发布证明。

## S2 原生身份与成品接线资料

2026-10-23 读取以下官方文档及锁定 SDK 的本地类型声明，用于实现合同。没有运行原生工具、Bun.build、SDK 或测试。

| ID | 官方资料 | 用途与边界 |
| --- | --- | --- |
| PI04 | [Pi RPC commands / get_entries](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/rpc-commands.md#get_entries) | session append 顺序、稳定 entry ID、since/leafId；用于正文目录，不将数组位置造为原生 ID。实际固定 Pi 兼容性留 S3 |
| RT08 | [Bun bundler](https://bun.sh/docs/bundler) | 多 ESM 入口、root/naming/splitting 与 packages=bundle；目录成品选择不等于已构建 |
| RT09 | [Bun build plugins](https://bun.sh/docs/bundler/plugins) | build plugin onResolve 将生产语言 runtime 绑定到固定源码成品；不把 npm 同版本当来源身份 |

锁定的 server 2.3.1 本地声明显示 setRequestHandler 使用方法名字符串、Server.projectCallToolResult 适配结果、serveStdio 返回 handle；DJ 按此接线，未套用 v1 的 schema 参数形状。实际 stdio/版本/structuredContent/EOF 行为仍由 A19 证明。
# 性能定位补充来源

- [Bun CPU profiling](https://bun.com/docs/project/benchmarking)：脚本CPU profile及输出选项。
- [Bun 1.4 profiling](https://bun.com/blog/bun-v1.4)：框架工作进程可通过BUN_CPU_PROFILE及目录环境变量采样。于2026-10-23核对；诊断采样不能替代完整压力测试或真实部署资源证据。

- [RFC 9562 UUIDv7及opacity](https://www.rfc-editor.org/rfc/rfc9562.html#section-5.7)：U1–U3采用48位Unix毫秒时间与74位随机字段的布局；§6.9/§6.12用于区分实体标识与授权秘密。当前设计不使用计数器，旧ID保持opaque；标准布局不证明具体数据库页命中或本产品吞吐。

## 真实验收刺激身份补充（2026-10-25）

| ID | 官方资料 | 用途与边界 | 状态 |
| --- | --- | --- | --- |
| IM11 | [Telegram Bot-to-Bot communication](https://core.telegram.org/api/bots/bot-to-bot) | 区分同群mention/直接回复、普通群消息及私聊的不同启用条件；用于选择真实刺激与独立观察身份，不证明现有测试资源已配置 | 已访问，未实际发送或修改平台设置 |

旧FAQ与新Bot API/MTProto说明存在表述差异，真实验收按实际版本、明确角色/开关与可关联原生消息实证，不据网页推定目标已获授权或互通。

| PI06 | [Pi v0.80.3 session format](https://github.com/earendil-works/pi/blob/v0.80.3/packages/coding-agent/docs/session-format.md)、[SessionManager](https://github.com/earendil-works/pi/blob/v0.80.3/packages/coding-agent/src/core/session-manager.ts) | 固定a23abe4a695df8b69b613f73e9fdda2a8af894d4：原生JSONL v3/header/tree与append、首次assistant前可未flush；仅作为PO设计依据，非真实session/PID或模型执行证明 | 已读取固定tag |
