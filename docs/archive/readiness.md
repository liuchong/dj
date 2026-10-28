# 开工准备与依赖固化资料

> 历史资料：保留当时的设计、状态与验收记录，不作为当前使用或施工指令。当前说明见[文档索引](../index.md)和[项目状态](../status.md)。
当前施工接续：S1 已落盘固定包/锁文件、目标 Bun 包、编译器候选产物摘要与固定源输入闭包，详见 config/toolchain.lock.json、compiler-provenance.json、compiler-source-inputs.json。固定源准备在项目私有 `.local/toolchains/eliscript-b1c7741/source`，不修改共享语言检出；记录来源 SHA、逐文件摘要、内部相对链接及补充 Unicode 生成源的独立摘要。它是依赖准备，不是编译器构建通过。

I01 的“写齐”仅表示配置、已知产物身份和重建输入/配方已固化；固定源成品身份闭环与互操作仍归 S3/A01，不能因 npm 同版本或输入已齐而放行旧冻结产物。S3 在资源保护下按 compiler-source-inputs.json 的参数数组，从维护的 Emacs seed 构建、完成 stage2/stage3 同产物链并安装到隔离依赖树，之后才将该树的 bin 放入本次构建 PATH。准备轮次未执行这些命令，不改全局 Bun/Node/Emacs，不跑语言项目整套测试或替代其发布。

先完成全量 S2；S3 再实际落盘 `.local/build/manifest.json`（schema_version/sources/outputs/compiler），每份 sources/outputs 含仓库相对 path+sha256。tools/build-inputs.eli 要求全部维护输入及四生产/19测试/三工具入口（build/verify/package）均被绑定，也绑定 bin、Skill、两份成品配置示例及 packaging 资料；verify 只消费产物、拒绝缺项或陈旧字节，不隐式编译。环境证据另保存 build manifest、锁文件、编译器输入记录与受保护真实 profile 的摘要，不记录秘密值。

日期：2026-10-23；本轮起点 master / 4e06ea8，工作区干净、无 remote。现有 36 份文档已包含施工顺序，本次补齐开工时直接使用的依赖、字段及用例资料。仍处于施工准备：没有编写生产/测试源码、安装依赖、构建、启动 DJ/Agent/IM 或运行产品测试。

唯一施工入口仍是 [plan](construction-plan.md)和根 [TODO](implementation-checklist.md)；本文没有另一套进度 checkbox。[逐操作字段表](operation-catalog.md)落实 I09/I12/I27 的目录输入，[用例卡](case-cards.md)落实 I02/I04–I08 的 manifest/断言。所有 I/A 仍未完成，不能把资料准备等同 I01 的包/lock 已落盘。

## 1. 已准备、将落盘与将验收

| 内容 | 本轮实际准备结果 | 下一阶段动作与完成证据 |
| --- | --- | --- |
| 范围/顺序 | 复用 D01–D18、I01–I30、A01–A20，不增加平台或功能 | 先 S1 全部测试编写，再 S2 全实现，最后 S3 构建/测试/验收 |
| 编译器身份 | 固定源 SHA、关键文档/元数据内容摘要已读取，见第 2 节 | I01 记录实际工具链位置引用/编译产物身份，S3 证明源与成品及互操作 |
| 宿主/第三方依赖 | 已从官方发布元数据选出精确版本和 SRI；无安装或包执行 | I01 创建实际 package/lock、生产/工具/测试配置；冻结传递依赖，不用 latest/范围冒充锁定 |
| MCP 接线 | 选 SDK Server + serveStdio，协议与业务校验分层，见第 4 节 | I27 按同 operationCatalog 投影 tools/list 和 callService，S3 对错误/幂等作一致性验收 |
| 接口字段 | 当前 63 操作的必填/可选/互斥/幂等/revision/结果具备目录与逐行资料 | I09 写 schema 和描述符；I12 权威受理；无另起通用 execute 工具 |
| 测试输入 | fixture、稳定子 ID、参数变体、故障点与机械断言已给出 | I02 转 manifest，I04–I08 写测试而不运行，S3 逐例留证 |
| 真实账号/接收目标 | 未装配本地 profile、未做 OAuth 或连接；凭据值不进入资料，只给安全引用和最小输入清单 | 真实验收前从届时已授权测试 profile 装配，不用工作会话补位；缺资源只影响相关验收 |


源码/编译器或重型测试未来按本任务资源保护规则调度，先单跑未知重负载；不因当前物理内存足够就任意并发。测试语料遵守正文/索引配额并单列构建/备份/版本空间，开跑前再核对实际余量；不清理其他项目腾空间。满盘故障采用隔离配额/受控存储错误，不实际写满主机卷，受控错误也不冒充真实文件系统满盘证据。

## 2. 精确依赖选择及来源

本节为 2026-10-23 的只读准备快照：先读取官方文档，再通过官方 npm registry 的 JSON 元数据请求取得版本/依赖/SRI。网页读取 registry 失败后使用只读 HTTPS 请求，没有执行 npm/bun install、下载/运行包或更新任何宿主。SRI 是发布方元数据，不是本轮已对下载内容验算的结果，也不是实际 bun.lock。

| 组件 | 选定身份 | 归属与边界 |
| --- | --- | --- |
| Eliscript | 源 SHA b1c7741365545d5a048079d64f863524cf7117e2，package 版本 0.1.0 | 编译期工具链；当前源工作区为该 SHA 且干净。编译输出/运行时闭包尚未实测 |
| Bun | 1.4.4、macOS arm64 | 保持既定宿主；不自动升级本机，不凭 npm 包版本推断 SQLite |
| @modelcontextprotocol/server | 2.3.1 | 唯一直接 MCP 服务依赖；不加 client、HTTP 框架或模型循环 |
| ajv | 8.20.0 | 直接依赖，显式 Ajv2020，单一业务 schema；禁止 coerce/remove/default |
| @modelcontextprotocol/core | 2.3.1 | SDK 传递依赖，与 server 的精确依赖一致 |
| zod | 4.6.7 | SDK/core 的传递依赖，满足其 ^4.2.0；不成为第二套 DJ 业务 schema |
| fast-uri | 3.1.0 | Ajv ^3.0.1 的兼容选择；本轮 latest 为 4.2.3，不可直接代入此范围 |
| fast-deep-equal | 3.1.3 | Ajv 传递依赖 |
| require-from-string | 2.0.2 | Ajv 传递依赖；不暴露为 DJ 执行任意字符串的能力 |
| json-schema-traverse | 1.0.0 | Ajv 传递依赖 |

两项直接生产包的已读依赖图：server 2.3.1 → core 2.3.1、zod ^4.2.0；core → zod ^4.2.0；Ajv 8.20.0 → fast-uri ^3.0.1、fast-deep-equal ^3.1.3、require-from-string ^2.0.2、json-schema-traverse ^1.0.0。表内选择共 8 个生产包，不包含 Eliscript 可能需要的运行时闭包；闭包随实际编译输出固化，不能提前声称只有八个运行包。

| 发布对象 | npm dist.integrity（仅元数据已读） |
| --- | --- |
| @modelcontextprotocol/server@2.3.1 | sha512-e59MfWuSssj6DoQ96JCTqdW1AXT5/XtnTl0WWd6MU1Ka434fFUGGosCLJbGNySDhHGvxQWoRWK137FXYFkYNWw== |
| @modelcontextprotocol/core@2.3.1 | sha512-laVmIhPGpWi7rG9q+0UigblRN0Hws/Yjlb6qLFtVqryXVLkc4h+yN8z731POD2LnAGQlFe7/tXhUm7Bi0YB91g== |
| zod@4.6.7 | sha512-g8W2D2kU6a8untc053fX1uVBKzM7yqAxW/3zwk83+6RyF2+SKOuV+c0wBDhUwzV1PaGapmZH+rmcUzPf+3CGwg== |
| ajv@8.20.0 | sha512-Thbli+OlOj+iMPYFBVBfJ3OmCAnaSyNn4M1vz9T6Gka5Jt9ba/HIR56joy65tY6kx/FCF5VXNB819Y7/GUrBGA== |
| fast-uri@3.1.0 | sha512-iPeeDKJSWf4IEOasVVrknXpaBV0IApz/gp7S2bb7Z4Lljbl2MGJRqInZiUrQwV16cpzw/D3S5j5Julj/gT52AA== |
| fast-deep-equal@3.1.3 | sha512-f3qQ9oQy9j2AhBe/H9VC91wLmKBCCU/gDOnKNAYG5hswO7BLKj09Hc5HYNz9cGI++xlpDCIgDaitVs03ATR84Q== |
| require-from-string@2.0.2 | sha512-Xf0nWe6RseziFMu+Ap9biiUbmplq6S9/p+7w7YXP/JBHhrUDDUhwa+vANyubuqfZWTveU//DYVGsDG7RKL/vEw== |
| json-schema-traverse@1.0.0 | sha512-NM8/P9n3XjXhIZn1lLhkFaACTOURQXjWhV4BA/RnOv8xvgqtqpAX9IO4mRQxSx1Rlo4tqzeqb0sOlruaOy3dug== |
| @oven/bun-darwin-aarch64@1.4.4 | sha512-zW/hxwc8sJAILGwB5eTC4i48ouGXf0V4lrxmEOk3JIE6JkYVW1TZh1E2pIempqsezgW1sckTIIDudFON8bJ2Mw== |
| eliscript@0.1.0（候选包） | sha512-qxOrfE9yxhJlTG/tFYuPTKeTe7XsaBKhc2kd+mmvve2oGSPCGxksfn+EIVxMU4qlJ5pTX6aZPEPWWffXticrGQ== |

Eliscript npm 0.1.0 元数据没有 gitHead，故它的 SRI 不证明与固定源 SHA 相同；当前选择仍以固定源为准，不能仅凭同版本字符串把 npm 包设为已经核验的编译器。I01 保存源身份、实际编译器产物摘要及二者关系，S3 的 T38 再证明可用性。当前读取的源内容 SHA-256 如下（不是编译产物 hash）：

| 固定源相对文件 | SHA-256 |
| --- | --- |
| docs/project-configuration.md | 1b918e4ef36bda789f15806e9b7acf128e70d9990a18c44dcfae88ba17413917 |
| package.json | 26d8283a9b4cae2dbc1aa381de214180a43c73caa28d3d455992ac20dc1ee6dc |
| docs/javascript-interop.md | 1f7490a7ebcc369dc82edb8edf311a4334ddf79bdd9df37116f005f3981f30f7 |

公开来源：[SDK 包](https://registry.npmjs.org/@modelcontextprotocol%2fserver/2.3.1)、[core](https://registry.npmjs.org/@modelcontextprotocol%2fcore/2.3.1)、[zod](https://registry.npmjs.org/zod/4.6.7)、[Ajv 包](https://registry.npmjs.org/ajv/8.20.0)、[fast-uri](https://registry.npmjs.org/fast-uri/3.1.0)、[fast-deep-equal](https://registry.npmjs.org/fast-deep-equal/3.1.3)、[require-from-string](https://registry.npmjs.org/require-from-string/2.0.2)、[json-schema-traverse](https://registry.npmjs.org/json-schema-traverse/1.0.0)、[Bun arm64 包](https://registry.npmjs.org/@oven%2fbun-darwin-aarch64/1.4.4)、[Eliscript 候选包](https://registry.npmjs.org/eliscript/0.1.0)。实施锁定不能依赖可变 latest。

## 3. I01 落盘配方

以下 JSON 只在文档中给出，尚未生成实际配置。未来 package 设置 private=true；直接生产依赖精确为 server 2.3.1、ajv 8.20.0，传递依赖按上表锁入 bun.lock。不开 postinstall、prepare、pretest、watch 或 CI 自动验证；必要依赖准备不得夹带测试。编译器从可信工具链 profile 取得固定版本入口，不把机器路径写入仓库；npm 候选未证同源时不冒充已经固定的 devDependency。

eliscript.json：

```json
{"schemaVersion":2,"sourceRoot":".","entries":["src/service/main.eli","src/interfaces/cli.eli","src/interfaces/mcp.eli","src/library.eli"],"outDir":"dist"}
```

eliscript.tools.json：

```json
{"schemaVersion":2,"sourceRoot":".","entries":["tools/build.eli","tools/verify.eli","tools/package.eli"],"outDir":"dist-tools"}
```

eliscript.tests.json 的 entries 精确列出 test-plan.md 的 19 个 .test.eli 文件，不用 glob、不把 support 文件单独当测试入口；outDir=dist-tests、sourceRoot="."、schemaVersion=2。三个输出目录均被忽略，不能直接运行未编译 `.eli` 或在 package 脚本中插手写 JS 业务。

| script | 准确目标命令 |
| --- | --- |
| build | bun dist-tools/tools/build.mjs --scope all |
| build:tools | 使用 package 脚本指定的项目隔离固定源入口，ELISCRIPT_BOOTSTRAP_MODULE_DIR 指向该源 dist/bootstrap；编译 eliscript.tools.json |
| build:test | bun dist-tools/tools/build.mjs --scope all（完整来源绑定构建的别名） |
| test / test:unit | bun dist-tools/tools/verify.mjs --suite unit |
| test:integration | bun dist-tools/tools/verify.mjs --suite integration |
| test:system | bun dist-tools/tools/verify.mjs --suite system |
| test:e2e | bun dist-tools/tools/verify.mjs --suite e2e --real |
| test:performance | bun dist-tools/tools/verify.mjs --suite performance |

S2 已写入 buildEntries。S3 先按固定源配方重建 stage3 并选择目标 Bun PATH，再运行 build:tools 生成构建器；build --scope all 核对完整 stage3 回执、formal source 与准备输入、产物字节后重建生产/测试/工具三个图，防止工具图与源码脱节。manifest 绑定配置、锁、输入记录、全部 .eli 与输出摘要；构建期间源码变动即不出验收回执。verify 只消费既有产物，不隐式构建。S3现已实际完成固定源stage3与完整图构建；完整业务验收仍未通过，当前结果见status。

## 4. MCP 与 Ajv 接线决定

官方 SDK 文档说明，高层工具注册会在 handler 前检查参数，低层 Server 允许程序自己处理 tools/list 与 tools/call，且 serveStdio 可以接收返回 Server 的工厂。DJ 需要统一业务错误与受理顺序，因此采用低层 Server 作为薄代理，而非依赖高层默认参数报错。[低层 Server](https://ts.sdk.modelcontextprotocol.io/v2/advanced/low-level-server.html)、[schema 接线](https://ts.sdk.modelcontextprotocol.io/v2/advanced/schema-libraries.html)。这是 DJ 的选择，不是宣称 SDK 已与 Eliscript 实测通过。

runMcp 的明确接线：

1. 从受保护 client profile 认证连接现有 DJ，service.status 取得 api_version/build_id/operation_catalog_digest/visible_operations；客户端编译目录摘要不符则 incompatible，不擅自混用 schema。
2. SDK 的 Server 声明 tools capability；tools/list 只从同一 operationCatalog 和当前授权投影工具名、描述、严格 inputSchema/outputSchema/annotations。工具集合没有自由 action。
3. tools/call 的合法协议壳进入 handler，按固定工具名映射回 operation，原样转给 callService。业务参数校验、typed ref、幂等重放和副作用前置检查仍由权威 executeOperation 执行；错误转为统一 envelope + isError，不被 SDK 默认文本报错提前替换。
4. 非 JSON-RPC/错误方法/arguments 根类型不是对象等协议壳错误由 SDK 处理，不能冒充成功业务调用。返回结果对同一 outputSchema 检查；若客户端收到非法或截断结果且无法证明受理状态，标结果未知并按原键查询，不能换键重发。
5. serveStdio(factory) 管传输，日志只 stderr；EOF 关闭代理和自身 UDS 资源，不关闭 DJ、不退订。宿主断线后已受理动作依然查原台账。

业务 Ajv 使用 ajv/dist/2020.js、strict=true、allErrors=true、coerceTypes=false、removeAdditional=false、useDefaults=false；结构校验后再做 UTF-8 字节/引用/授权等业务校验。RFC3339/字节约束由共享业务校验明确执行，不把 maxLength 当 max_bytes，不为格式校验额外拉另一套 schema 库。SDK 自带 schema 依赖用于协议层，不是 DJ 第二个字段目录。T26/T55/T70 应包含错误参数仍返回同一业务 envelope、摘要不符拒绝以及代理 EOF 后台账仍在的用例。

## 5. 配置和真实验收输入清单

| 输入类别 | 必须提供的安全引用/事实 | 缺失时的机械行为 |
| --- | --- | --- |
| 本地服务 | service_id、私有 socket/状态目录、schema_version、文件权限/持久存储策略 | 配置失败/owner 冲突/存储不支持则不启 intake，不建影子库 |
| 调用主体 | operator、独立查询/发送主体、各 recipient 的 credential_ref、grants/target_constraint | 缺身份拒绝；自报 ID 不赋权，缺绑定不阻止已获准目录查询 |
| 最小接收方 grants | 已选 IM 来源 read/search、自己 subscription.manage、固定 reply、自己的 operation/delivery/outbound inspect；需要控制时窄 manage | 不合并 operator 权限；无 reply 时不发可用 reply_context |
| Agent 目录/目标 | 可信 endpoint_ref/profile_id、namespace、精确 session/epoch/工作区引用 | 只历史不当 receiver；无证就 unknown/offline，不试发或自动创建 |
| managed profile | 固定 argv/资源/工作区/凭据引用、auto_start/resume/停止策略 | 不接受模型自由 argv/cwd/endpoint；query/send 不隐式 start |
| 两 IM | Lark 国际版 user OAuth 凭据、Telegram bot credential_ref、允许 chat/thread 及收件所有权 | 既有 webhook 拒绝接管；原生 API；源 ACK/replay 限制如实公开 |
| real 组 | DJ_TEST_REAL=1、DJ_TEST_PROFILE 引用、测试对话/工具归属与外发/费用范围 | 缺任一条件保持未执行/blocked，不能自动用开发者当前会话或新建账号 |

准备资料不要求现在读取凭据或给任何人发消息。未来配置示例使用不可执行的逻辑引用，秘密另存；真实目标和原始回执只存受保护本地证据，不写仓库。正常路径不增加重复确认，只有缺必要身份/范围时由对应操作明确拒绝。

## 6. 开工状态与剩余证据

本轮可完成的是资料：精确包选择、字段表、用例卡及接线规则。I01 仍要求实际 package/lock/工具链记录落盘，I02–I08 仍要求测试代码写齐，I03/I09–I30 仍要求生产实现；这些不是文档阶段可以勾掉的工作。

未来 S3 才证明：编译器产物对应固定源、Bun 内嵌 SQLite 版本/模式/FTS5、SDK/Eliscript/Ajv 互操作、原生 idle/lookup/安全停止、真实四组合/Skill 采用及性能。证据不足时只阻塞依赖项，不放宽首期完成条件。下一施工步骤仍按根 TODO，不能从本文跳过全测试编写直接写某个方便的模块，也不因依赖元数据已读而启动 Goal。


<a id="local-layout"></a>
## 7. 当前默认部署与 Lark 原生接线

当前正式接线以[规格 0001](../specs/0001-lark-realtime-subscriptions.md)及[IM 接入](../adapters/im.md)为准。服务根通过可信 OS home 解析到 `~/.dj`，显式配置优先；客户端只能使用宿主分配的独立 profile，不能借用 operator。

Lark 正常收件使用 events：应用密钥获取官方 WebSocket 地址，持久化后 ACK，Core 负责去重与订阅过滤。本人 HTTP 操作使用已授权 OAuth 凭据与明确的应用/用户锚点；机器人 HTTP 操作使用应用 token。SDK、外部 IM CLI、历史轮询和 AI 巡检均不得替代正常实时收件。应用事件可见范围与个人全部收件箱不是同一事实。

凭据放在当前用户所有的受保护文件中，只在配置保存 credential_ref；配置与操作投影不含秘密。原生缺权限时保留真实错误码与缺口，不猜 scope、不换身份。常驻服务名称、原始会话目标及消息范围按操作员当前授权确定。
