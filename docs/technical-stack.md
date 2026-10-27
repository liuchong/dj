# 技术选型：Eliscript 与轻量本地运行时

日期：2026-10-23；设计基线 2a7d747。用户指定前期使用 Eliscript。本文据当前源码与官方资料作设计选择，尚未创建依赖文件、构建产物或服务；选择不等于兼容验收通过。

## 采用方案

| 层 | 首期选择 | 理由与边界 |
| --- | --- | --- |
| 维护源码 | Eliscript `.eli`，编译为标准 ESM | 核心、服务、CLI、MCP、适配器和后续测试均使用同一语言；不另写一套 JS/TS 业务实现 |
| 服务宿主 | Bun 1.4.4 为拟验收基线 | 内置网络、子进程与 SQLite 接口减少依赖；当前本机只有 1.4.0 的版本读回，未升级或验证 1.4.4 |
| 编译工具链 | Eliscript 0.1.0 源码快照 `b1c7741365545d5a048079d64f863524cf7117e2` | 实际核对的完整 SHA 见下文；不能仅依赖版本字符串或可变分支。运行成品不启动 Emacs/编译器 |
| 持久化 | `bun:sqlite`，SQLite WAL + synchronous=FULL + foreign_keys=ON | 单文件、事务与唯一约束支持既有台账；数据库及 WAL 位于同一本地持久目录，不放网络文件系统 |
| 内部控制协议 | HTTP/1.1 + JSON，经 Unix domain socket | CLI/MCP 连接同一服务；默认没有 TCP 公网监听，不把内部协议称为远程 MCP |
| 外部模型接口 | 薄 CLI + MCP stdio 代理 + Skill | 与常驻收件分离；MCP 不承担主动唤醒 |
| MCP 实现依赖 | 官方 `@modelcontextprotocol/server` v2 稳定线，协议 2026-07-28 | 使用其协议/stdio 能力，业务仍在 `.eli`；旧宿主单独适配，不混用 v1 初始化 |
| 参数验证 | Ajv 8 的 JSON Schema 2020-12 模式 | 同一操作目录投影到服务、CLI help、MCP；禁止类型转换、删除额外字段及验证器静默补默认 |
| IM / Agent 协议 | Bun fetch/流读取/子进程，少量有界协议编码 | 首批见 release-scope；不把 Agent SDK 的模型循环引入 DJ |
| 配置与凭据 | 版本化 JSON 配置 + 受保护的文件凭据引用 | 状态/秘密目录 0700，秘密文件 0600；凭据值不进配置示例、模型消息或仓库 |
| 服务管理与交付 | 前台 `dj serve`，由 macOS launchd 监督；目录式发布包 | 不自行脱离后台；首期不依赖容器、Redis、消息队列集群或外部数据库 |
| 嵌入面 | 同一 ESM 核心模块，宿主显式提供端口 | 首期不承诺 C/Rust ABI、浏览器服务、Native/WASM 服务或 Node 运行兼容 |

Bun 接口依据 [SQLite](https://bun.com/docs/runtime/sqlite)、[HTTP/UDS](https://bun.com/docs/runtime/http/server)、[fetch](https://bun.com/docs/runtime/networking/fetch)、[子进程](https://bun.com/docs/runtime/child-process)。MCP 选型依据 [SDK v2](https://ts.sdk.modelcontextprotocol.io/v2/)；校验选型依据 [Ajv schema](https://ajv.js.org/json-schema.html)及[选项](https://ajv.js.org/options.html)。这些资料证明可选接口存在，不证明 DJ 已经接通。

## Eliscript 能力与使用约束

只读核对的源码身份为 `b1c7741365545d5a048079d64f863524cf7117e2`，当时工作区干净；实现前必须核对编译器产物哈希和源/产物对应关系。当前 package.json 为 0.1.0，声明 Bun >=1.4.0、Node >=24；这是语言工具链要求，不是 DJ 支持所有这些宿主的承诺。

已读当前 README、项目构建配置、互操作与正式语法文档，并检查编译入口。其 ESM 输出、项目图构建、显式包导入和 JS 宿主互操作足以支持此设计方向；没有在本轮编译 DJ 探针或重跑语言验收。早期语言提案不能替代当前编译器/互操作测试，也不能凭“Emacs Lisp 兼容”推出 Bun 文件、网络或子进程 API 自动可用。[EL01–EL04](references/official-sources.md#eliscript-runtime)

- 业务规则与状态转换保持普通 Eliscript 数据和显式依赖；Bun/数据库/厂商对象留在宿主端口，不渗入规则 AST。
- JS 库通过显式互操作导入；异步调用显式等待、捕获失败和取消。不得在 `.eli` 的字符串里藏一整段手写 JS 服务或测试程序。
- wire JSON 的 false/null/缺失必须保真，不能用 Lisp 的真假值判断代替字段类型检查。按当前互操作合同转换，并在 T38 验证；同理精确区分空数组、空列表、对象和字符串。
- 字节预算使用 UTF-8 编码后的长度；不拿宿主 UTF-16 长度冒充字节数。64 位数据库序号在 wire 投影为十进制字符串，不经浮点数舍入；revision 使用有界安全整数，达到上限停止变更并诊断。
- 同一份操作 schema 是唯一字段目录。Ajv 预编译后复用，`coerceTypes=false`、`removeAdditional=false`、`useDefaults=false`；明确缺省由业务规范化步骤添加。SDK 的 schema 适配必须保留互斥、未知字段和字节校验语义。
- 依赖导入和接口编译若存在真实缺口，记录准确能力与失败边界；不能自动改写成另一语言实现，也不能把补语言能力视作本轮授权。

## 本地控制与凭据通道

内部 wire 固定为 `POST /v1/operations`，请求对象为 api_version（字符串 1）、operation 和 arguments；arguments 就是统一业务输入，不再引入第二套操作字段。响应沿用统一 envelope。请求体默认最多 256 KiB，版本/未知字段/类型不符先拒绝；协议错误与领域错误分开映射，不执行任意方法名或 URL。健康状态同样通过 service.status，只有存储/恢复完成后才开放普通业务。

服务名 local 由受保护 client profile 解析为 socket 引用；CLI/MCP 在传输认证头携带从受保护文件读取的凭据，服务核验预配摘要并解析主体，Principal 不进入 arguments。路径权限与服务认证同时生效；正文、日志和错误均不回显凭据。首期不提供 TCP 回退，也不把这个内部 HTTP 入口当作远程 MCP。多个入口仍使用同一主体、幂等键和台账。

## 单进程与存储模型


`bun:sqlite` 是同步驱动，短事务仍可能因磁盘同步阻塞事件循环；WAL 不会把它变成异步接口。所有网络操作必须在事务外；事务只处理有界页，查询预编译，读取分页。默认 busy_timeout=0，锁冲突由服务异步退避，不在 SQLite 内长时间等待。checkpoint 由服务低负载时调度，测量其停顿与 WAL 大小；不能无限延后或悄悄改 NORMAL 换取指标。

依据 [SQLite WAL](https://sqlite.org/wal.html)和 [synchronous](https://sqlite.org/pragma.html#pragma_synchronous)选择 FULL，保障合同以文件系统确实兑现同步为前提。启动读回 journal_mode/synchronous/foreign_keys 和实际 SQLite 版本；要求包含 WAL-reset 修复（首期 >=3.51.3），不凭 Bun 版本推定内嵌版本。未满足时 storage_unavailable，不启收件。备份使用一致性快照/SQLite backup 能力，不在运行中只复制主文件遗漏 WAL。

性能沿用组件契约，增加事件循环延迟、提交/fsync 和 checkpoint 停顿记录。若单进程无法通过 T27/T40，就说明该版本未达标，先修有据可查的瓶颈，再决定是否隔离存储进程；不能宣布当前已经达标，也不预先增加第二套存储架构。

## 组件与构建布局

以下为模块级方向，不是当前树；精确文件、符号、三个构建配置和输出路径以 [施工手册](construction/plan.md)及[构建接线](construction/contracts.md#5-编译配置与退出接线)为准，本轮不创建它们。

```text
src/core/                 领域、规则、策略与状态转换
src/application/          同一业务操作执行层和 schema 目录
src/catalog/              工具/实例/会话快照、增量索引与机械查询
src/lifecycle/            显式启动/创建/停止及动作核对
src/storage/sqlite.eli    Store 端口、版本迁移和事务
src/delivery/             有界调度、回执、恢复与出站
src/host/bun/             文件/时间/网络/子进程的显式实现
src/adapters/im/          lark.eli / lark-events.eli / lark-wire.eli / telegram.eli
src/adapters/agent/       opencode-http.eli / pi-rpc.eli
src/interfaces/cli.eli    命令投影和服务客户端
src/interfaces/mcp.eli    stdio 薄代理
src/service/main.eli      装配与前台服务
src/library.eli           无启动副作用的 ESM 核心入口
tests/                   Eliscript 单元、集成、系统与 opt-in 真实验收
```

ESM 核心契约草案：`createCore(ports, config) -> Core`；`Core.execute(principal, operation, args) -> Future<Result>`；`Core.start() / stop() -> Future<LifecycleResult>`。导入模块不监听、不建库、不拉消息；宿主显式装配 Store/ImPort/AgentPort/时钟/调度/凭据与审计端口。一个状态目录只能有一个核心调度所有者；嵌入模式与 standalone 不可同时操作同一状态。

构建时使用受锁定编译器进行多入口 ESM 构建并保留 source map。发布包包含生成 ESM、必要 runtime/锁定生产依赖、Skill、配置说明和版本/哈希清单；源码与生成物区分，生成物不手改。不默认做单二进制打包，避免先引入原生依赖和资源定位问题。编译器若只在构建期使用，就不随成品常驻。未来仓库需忽略 dist、状态和本地秘密；本轮没有创建这些目录或忽略规则。

## 已决定与待验证

已决定：Eliscript、ESM/Bun、SQLite、UDS、本地 stdio MCP、文件凭据、单所有者与首批协议。尚待实现阶段固定：全部 npm 精确版本/完整性哈希、编译器产物、SDK schema 适配方法、各原生工具的兼容档案和性能实测。它们是所选方案的验收证据，不是重新悬置技术方向。

当前完整流程见 [启动到回复](startup-to-reply.md)，具体首批平台与退出条件见 [首批范围](release-scope.md)。

开工准备已将第三方包选择具体化为 server 2.3.1、Ajv 8.20.0 及兼容的传递依赖/SRI，见 [准备记录](construction/readiness.md#2-精确依赖选择及来源)。本机 Bun 仍是1.4.0，目标仍1.4.4，未升级；Eliscript源身份已固定，但npm同版本包缺gitHead，不假装编译器产物同源已经证明。实际package/lock与工具链可用性仍待I01/S3，不把元数据查询当安装或运行通过。

## 统一查询与控制的追加选型

新增 catalog/lifecycle 仍使用同一 Eliscript/Bun 核心和 SQLite；会话元数据走普通索引，正文候选采用 FTS5 trigram 加原文精确复核。启动核对其可用性，短串/不支持路径严格有界并公开覆盖限制，不安装外部搜索引擎。查询/刷新不扫描任意用户目录、不依赖模型；输入队列从登记目标扩为 TargetRoute，使免订阅直发与订阅共用可靠性。profile 启动和空会话创建通过独立生命周期台账处理，不增加调度 AI 或 IM 操作界面。字段/预算以 [控制契约](agent-control-plane.md)为准。

复审后统一采用 catalog_seq 逻辑版本/稳定键扫描，不持有跨客户端翻页的 SQLite 读事务；查询计划、授权过滤、FTS 候选推进和版本保留配额都进入 T57/T59/T60。lifecycle 与 delivery 共用持久实例 gate，profile slot 要有已证退出才可重启。Core.stop 与服务监督策略必须表达仍 draining 的结果，不以退出进程/关闭活跃 RPC 管道冒充安全停止；OpenCode/Pi managed 进程均计入归属与停机验收。
