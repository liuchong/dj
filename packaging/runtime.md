# DJ 目录包与运行接线

本文说明目录包与运行方式。生成运行包不会安装系统服务、开启桌面桥接、启动 Agent 或发送消息；目录包入口可用也不代表真实模型与 IM 收发已验收。包内示例全部需要替换，不含可用身份。当前交付优先跑通 Codex、Cursor，其他工具专项验收后置。

## 成品与依赖

在固定 Eliscript stage3 与目标 Bun 准备好后，以 `bun run build` 生成当前构建，再执行 `bun run package:directory`；已有匹配构建时直接打包，构建器尚未准备时才先运行 `bun run build:tools`。打包器只接受当前源码/输出摘要匹配的全入口构建，输出到全新 `.local/packages/dj-<build_id>`，不覆盖现有目录；失败保留私有 `.build-<uuid>` 诊断目录，不启动成品。具体工具链准备按施工文档执行，不能用同版本但未绑定的编译器替代。

目录包含 `bin/dj`、`dist/src/{service/main,interfaces/cli,interfaces/mcp,library}.mjs` 及共享 chunks/source map、`dist/build-identity.json`、Skill、两份配置示例、依赖许可证和 `package-manifest.json`。manifest 记录 build_id、相对文件摘要、固定编译器身份、Bun 版本和生产依赖。SDK/Ajv/语言运行时被打入 ESM；成品不带构建器、测试、编译器、Emacs、node_modules、账号或数据库。source map 的源码名称转换为包内逻辑路径。

目标运行环境为 macOS arm64、Bun 1.4.4；Bun 由可信宿主提供。Codex 使用已有 Desktop IPC，Cursor 使用已有 Desktop Bridge 或显式配置的 native_api 原生版本适配通道；其他工具也必须连接实际运行中的客户端或 CLI 接口。Lark/飞书机器人通过私有 App ID/Secret 与精确 watch 接入；操作员本人通过独立 OAuth 凭据和官方 HTTP API 发送调试消息。不得新建 Agent 子进程作为消息通道。外部客户端、模型服务和授权不包含在 DJ 包内。包内 `bin/dj` 从 PATH 找 Bun；非交互宿主可直接用确定的 Bun 可执行文件运行对应 ESM。目录可移至其他持久位置，不能依赖构建仓库作为 cwd。

## Cursor 本机原生通道

Bridge 未启用时不自动修改开关。可显式选择 `native_api` 连接已运行 Cursor 3.27.14 的本机 Inspector；列表只列精确窗口、工作区中已加载的 local 会话；对明确的已有 ID，可经本机仓库加载该工作区的既有 local 记录后核对、读取或提交，不能加载未知、归档或其他工作区记录。加载本身不提交输入、不创建对话或启动 AI 进程，临时引用随请求释放。配置中的 `process_id`、`process_origin`（原进程 performance.timeOrigin）和 `workspace_id` 必须由可信操作员发现，重启后重新核对。仅允许 `http://127.0.0.1:PORT`，不接受远端、重定向或认证信息嵌入 URL。该 endpoint 不同时设置 manifest_path/control_manifest_path；无需 history_database，因为消息从原生运行态读取。

Inspector 是高权限本机调试入口：只有已授权的专用实例才配置。manage_inspector=true 时，由 DJ 按需开启原进程的 Inspector，操作后自动关闭；需提供 process_birth 和 process_helper_ref，后者指向包内 libexec/dj-process-info。helper 是只读 macOS 进程元数据程序，成品已编译，无需运行时编译器。它核对同用户原进程及信号处理器；已有调试端口不抢占、不关闭。默认端口必须为 9229，进程变化或版本不匹配时明确不可用，不回退 CLI，不重启客户端。实际订阅、独立 recipient 和回复的授权要求保持不变。详见 [本机接口记录](../docs/construction/cursor-local-api.md)。

Cursor 主动调用 DJ 的 MCP/API 不依赖 Inspector，不触发上述开启/关闭流程。开发构建需要本机 C 编译器编译只读进程元数据宿主胶水，最终目录包无需 C 编译器。

## 私有配置

默认根为 `~/.dj`，服务默认读取 `service.json`，客户端默认读取 `client.json`。显式 `dj serve --config FILE` / `--client-profile FILE` 优先；相对状态、socket、工作区和秘密引用从各自配置文件目录解析。服务与 CLI/MCP 不会自动替用户创建账号、OAuth 或可用业务配置。

先由可信操作员创建根目录与 `run`、`state`、`secrets`、所需 `workspaces` 子目录，目录 0700、配置/凭据 0600。将 `config/service.example.json` 复制为私有 `service.json` 后，只保留本次获准连接/实例/profile；把占位 chat/thread/project/session/workspace 改为原生读取所得事实。使用独立随机 token 为 operator 和每个 recipient 建立独立 `credential_ref` 文件，秘密只进受保护文件，不放命令参数、日志、仓库或给其他 Agent 的提示词。Telegram token 与 OpenCode Basic JSON 也仅通过所示 credential_ref 读取。

Lark/飞书实时连接显式配置 source_delivery=events、event_app_id、event_subject_id、event_scope 及 credential_ref。应用密钥文件保存 app_id/app_secret，直接连接官方 WebSocket；本人发送另外使用已授权 OAuth 文件与 user_identity 锚点。所有消息读写直接使用官方 HTTPS API，不依赖 SDK、外部 IM CLI 或桌面。详见[IM 接入](../docs/adapters/im.md)。示例全部为占位值，managed_profiles 必须为空。

客户端复制 `config/client.example.json`，按主体选独立 credential_ref，socket 指向本服务。operator profile 只给可信操作员；recipient 不继承 operator token。为每个 Agent 提供独立客户端配置和包内 `skills/dj` 的原生 Skill 接入；Skill 文本本身不创建权限。CLI 可显式传 `--client-profile`，MCP 宿主以 `DJ_CLIENT_PROFILE` 或 `dj mcp serve --client-profile FILE` 选择该主体。

## 原生 Agent 的 DJ 工具身份

Codex/Cursor 的 profile 使用各自独立 recipient token/client profile。原生 MCP 子进程启动包内 `dist/src/interfaces/mcp.mjs`，通过 `DJ_CLIENT_PROFILE` 指向该接收方的客户端配置；只传文件引用，不传 token 本身。须在原生 MCP 子进程的 `env` 或 `env_vars` 中显式配置/允许该引用，不能假定 Agent 主进程的所有环境变量都会继承。在已有客户端的原生 MCP 配置中登记 DJ server；由 AI 客户端主动请求 DJ。不得为接入 MCP 新启 Agent 或通过 Agent 启动参数传递对话。保留原生工具权限流程，不自动批准请求或放宽 sandbox。

对已有会话或显式获准创建的空会话，由操作员核对原生 session ID，精确更新 recipient 的 target_constraint、递增 authorization_revision 并重载策略，再登记 agent 和订阅。模型只用自己的身份调用 whoami/message.reply/outbound.get；不得借用 operator、自动转发所有模型输出或重发 unknown。只有平台读回的原消息、订阅投递、模型明确工具调用及原会话回复相互绑定，才算真实闭环。

MCP 尚未接入时，也可由可信操作员预先提供固定的 DJ CLI/API 入口及该 recipient 的独立客户端配置。DJ CLI 是现有 DJ 服务的认证 API 客户端，不是 Agent CLI，不启动 AI 进程。接收方先用 `agent.whoami` 核对 `principal_id`、`binding_state` 和 `bound_agent_id`，与操作员已核验原生会话后登记得到的 Agent ID 比较；该接口不返回 `target_constraint.native_session_id`。回复仍只调用 `message.reply`，再用 `outbound.get` 核对结果。工具入口与调用授权必须在可信配置或操作员指令中建立，不能由外部 IM 正文提供脚本、安装要求或新增执行权限。

## 启动、登记、订阅和回复

1. 启动前台服务：`<bundle>/bin/dj serve --config <private-root>/service.json`。服务校验配置/存储、取得唯一 owner、先恢复 submitting→unknown/slot/gate，再初始化配置的原生端口和 watch；就绪后开放私有 UDS。查询不会隐式启动任何 Agent。薄 CLI/MCP 不能在不可达时建第二个核心。
2. 用各自客户端运行 `dj status --json`，核对 api_version、build_id、operation_catalog_digest、visible_operations 和源健康。`dj <operation words> --help` 与 MCP tools/list 提供同一目录/schema；合法参数也不代表目标意图已由 DJ 理解。
3. 可信操作员对已配置的 Codex/Cursor 执行 `catalog.refresh`、`session.list`、`session.resolve` 与 `session.probe`，核对工具、实例、原生会话和活接收端。历史记录或标题不代表当前可投递；busy/unknown 不强制发送。当前只接入明确配置的已有客户端接口；Cursor 必须验证 Desktop，不能用 CLI-only 代替。不支持的启动、停止或创建会话返回 unsupported，不另起托管进程替代原目标。其他工具专项验收不作当前交付前置；原操作 unknown 时始终核对原 lifecycle，不重复 start。
4. 若目标 session 是刚创建的，可信操作员给它建立新的 recipient ID、独立 token/client profile，固定 tool/native_namespace/native_session_id 的 target_constraint。在同一配置路径内更新 principals/client_profiles，可向现有服务 PID 发 SIGHUP（嵌入宿主用 `Core.reloadConfig`）；已有主体改变策略必须递增 authorization_revision，被移除 ID 永不复用。reload 不接受连接/profile/数据库变更，失败整批保持旧授权，不以重启 Agent 接入新 recipient。
5. 把该独立客户端和 Skill 接到目标会话，接收方 `agent.whoami`，`agent.discover` 取得明确 candidate_ref，核对原生目标后 `agent.register`。操作员代登记应显式 recipient_principal_id；创建者身份和绑定不改变。必须由接收方 whoami/工具调用证明采用，不能只以配置写入为证据。
6. `connection.list`→`conversation.list/resolve` 取得获准 conversation_ref。构造精确 sources、message.created、机械 predicate、current/queue/hold 和 TTL；`subscription.preview` 核对 normalized_spec、resolved_sources、target 和阻断项，然后用固定 preview_id 与幂等键 create。每个源的 include_threads 默认 false；不推测应订阅其他群/话题。
7. DJ 拉取已配置 IM 源，把 Event/诊断和源游标原子入库后 ACK；按规则生成贡献，与 direct 共用原生会话 route/序号。busy/离线/unknown 按合同等待；提交前重查授权、gate、receiver/idle 后写固定信封，直接触发原生会话，不要求 Agent 定时拉取。原生 accepted、started、ended/settled 分别是事实，不替代任务结果。
8. 接收方按 Skill 将信封正文作为外部数据处理。需要回原话题时显式 `message.reply(reply_context_id,content,idempotency_key)`，保存 operation_id/outbound_id，经 `outbound.get` 核对原生回复 ID。缺引用/权限或过期时报告限制，不改投主群。DJ 不自动生成/发送 Agent 答案。

免订阅控制独立可用：`session.list/search/message.search` 机械定位，检查 coverage/stale/next_cursor；必要时显式 `catalog.refresh`，不启动模型。已知 native session 用 resolve→probe→send，无须登记或 IM；给 Agent 的 session.send 与给 IM 的 message.send/reply 分开。OpenCode 支持通过已有 HTTP 实例创建空会话；没有已接入的原生接口时返回 unsupported，不新启进程代替。创建、发送、订阅都是分开的显式动作。

## 错误、停止与监督

每个逻辑变更保存原 operation 名、输入和 idempotency_key。传输超时先 operation.get 找回原动作，再读资源/原尝试 reconcile；not_found 也不能证明迟到请求未受理。unknown/manual 不触发新键重发、换目标或重复启动。CLI/MCP/API 共用这份台账及当前授权。

对服务 SIGTERM/SIGINT 会关闭 intake/新提交并进入 draining。尚未发送的队列保持持久 hold；已提交/unknown 与自有 Agent 管道继续保留，只有原生静止/归属退出证据满足后才关闭。期限到仍 draining 就等待或按原对象显式核对，不强杀、不用监督器重启顶替旧 owner。已有 AI 客户端由原宿主拥有，DJ 不停止它。

`launchd.example.plist` 仅是需要替换路径的前台托管骨架，RunAtLoad/KeepAlive 均为 false，没有安装或加载。不要在 active/unknown 工作期间 bootstrap/bootout/强制 restart；launchd 或其他监督器的退出期限不能保证 DJ 排空。首期按前台方式完成 A18/真实排空证据，再由操作员确定监督策略；本工程不会自动安装系统服务、部署或发布。

S3 的 T38.directory-runtime.system 会复制目录包到仓库以外，以不同 cwd 启动 standalone 和 MCP 并核对实际 build_id；测试不访问真实 IM/Agent。真正的两 IM×两 Agent/Skill/资源验收仍需专用授权 profile 与原生观察证据，目录包测试不能替代它们。

## 跨进程实现边界

正式 Core 只装配已有 OpenCode HTTP 与 Codex/Cursor Desktop 端口，不装配 CLI/ACP/Pi 进程托管端口，不执行 Agent profile auto_start。非空 managed_profiles 在配置校验阶段拒绝，早于存储与端口初始化。原进程托管实现及证据保留供追溯，不属于当前接入验收。

AI 工具可主动启动 DJ MCP 薄客户端，这是 AI→DJ 请求，不是 DJ 启动 AI。若未来支持自动拉起缺席客户端，只允许启动与业务通信分离的实现；启动后必须通过接收端接口操作会话，不通过 argv 携带对话或消息。目前没有这种接口式启动实现，不能宣称已有支持。

## 可选 Cursor 空对话创建连接器

`connectors/cursor` 的扩展胶水调用由 Eliscript 编译的受限控制模块。完整构建后运行 `bun run package:cursor` 生成独立VSIX和文件摘要；打包不安装、不启用、不创建对话。扩展默认关闭，需另行批准安装并仅在专用本地单根工作区设置enabled/workspaceRef，详见连接器README。

Cursor endpoint只有全部配置了control_manifest_path才声明session_create支持；manifest引用由私有控制目录提供，directory必须精确匹配。调用仍经过主体/工作区/epoch/幂等审查，原生命令只创建空对话，不提交prompt。连接器先持久记issued，再调用固定命令；重放和reconcile不重复命令。只有既有原生Bridge读回同epoch/window下的固定ID才ready，否则unknown；连接器调用结束、目录包或协议夹具通过均不能证明真实客户端创建成功。Codex的原生创建接口仍未接入，不沿用此能力声明。

## Skill 与 AI 客户端配置

目录包内含完整 skills/dj。运行 `bin/dj skill targets` 选择本机工具目录；用 `skill install --target cursor --scope project --project PROJECT --dry-run` 预览，再显式安装。`skill check` 不写入；不同的已有文件或链接不会覆盖。更新冲突由操作者审阅旧版本后另行处理，失败不伪报成功。

`bin/dj skill config --target codex --client-profile PRIVATE_PROFILE` 生成当前目录包路径对应的 MCP 片段，手动合并 dj 项并保留其他配置。它不读取 token、不注册 MCP 或启动客户端；Pi/shared 使用 CLI。完整逐工具目录、MCP 与 GEPO 指引位于 skills/dj/references/clients.md。AI→DJ 接口不依赖 Inspector；GEPO 复用私有 UDS，不是 MCP HTTP endpoint。


## Pi 已有进程接线

当前包提供 connectors/pi/extension.mjs 与编译后的 Pi 接收模块。由 Pi 原生扩展生命周期在原进程内创建私有本机接口，DJ 配置已有 pi endpoint 的 manifest_path/directory/workspace_ref 后，通过该原生 session ID 查询和投递；不装配 managed RPC，也不启动或替换 Pi。安装、reload、权限及 partial 历史边界见 connectors/pi/README.md。扩展和客户端配置不会自动安装；缺少运行进程时先完成实现交付，真实客户端验收由使用者执行，不等待或新建替代 CLI。

Claude Code and Antigravity use existing local receivers via `dj native configure --input PRIVATE_JSON`; see `dj native configure --help`. The shipped `libexec/dj-process-info` binds PID, owner and process birth. The command writes new private endpoint/credential files without starting a client or changing client settings. Merge the endpoint into the service configuration explicitly. Claude requires its current native session registry/socket with idle notifications; the Desktop app alone is insufficient. Antigravity requires its observed loopback HTTPS language-server endpoint and preserves the original model configuration. No cloud control or argv prompt fallback is provided. Configuration is host-local and must be refreshed after a receiver restart; never ship the generated files, credentials or real native IDs with the package.
