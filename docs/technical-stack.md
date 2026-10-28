# 技术栈

| 层 | 当前选择 | 位置与约束 |
| --- | --- | --- |
| 业务语言 | Eliscript `.eli`，编译为标准 ESM | `src/`、`tools/`、`tests/`；不另维护 JS/TS 业务实现 |
| 服务运行时 | Bun 1.4.4，macOS arm64 | `package.json` 与 `config/toolchain.lock.json` 固定身份 |
| 编译器 | 固定 Eliscript 源与已核验 stage3 产物 | `config/compiler-source-inputs.json` 及构建器 `bindCompiler` 校验；仅同名版本不足以通过 |
| 存储 | `bun:sqlite`、WAL、`synchronous=FULL`、外键开启 | 同步事务、持久台账、事件/投递去重和崩溃恢复 |
| 本地通信 | JSON HTTP-over-UDS | CLI、MCP 薄代理与 GEPO 连接同一常驻 Core，不默认开放公网端口 |
| MCP | `@modelcontextprotocol/server` 2.3.1 | 当前安装 SDK 提供协议与 stdio，业务权限和 schema 由 DJ 执行 |
| 业务校验 | Ajv 8.20.0、JSON Schema 2020-12 | 操作目录共用；不强转类型、不删除未知字段、不静默补值 |
| Lark 接入 | Bun WebSocket / fetch 与有界 protobuf 编解码 | 官方 WebSocket/HTTPS 直连，不使用外部 SDK、CLI 或 IM 桌面客户端 |
| Agent 接入 | 已有进程的 IPC/socket/loopback API | 不以新 Agent 子进程、argv 参数或云端控制代替原会话 |
| Pages | HTML/CSS/SVG 与 Eliscript 浏览器 SDK | 维护 `.eli` 源码，浏览器现场编译；不提交生成 JS |

## 源码与运行包

构建输出与维护输入由 `.local/build/manifest.json` 绑定。目录包把运行依赖打入 ESM，并包含只读 macOS 进程元数据 helper；使用者不需要编译器、Emacs、构建仓库或 node_modules。构建和打包步骤见[开发指南](guides/development.md)。

目录包附带项目 `LICENSE` 和第三方 `licenses/` 清单。DJ 的 1PL 不替代第三方依赖自己的许可证。

## 数据与凭据

服务默认读取私有 `~/.dj/service.json`，客户端使用独立 profile；相对路径从各自配置文件目录解析。目录权限 0700，配置和凭据 0600。凭据、真实消息、会话标识与账号资料不进入仓库、公开示例或模型提示词。

数据库、WAL 和受保护备份位于本地持久目录；配置、数据和运行包可分别备份，升级保留真实身份、规则和幂等台账。

## 协议参考与实际能力

官方规范、SDK 能力、DJ 已装配功能和真实验证分别记录。引用更新的规范不代表所有扩展已经实现，也不据此添加项目自己的历史兼容层。业务操作的当前机器可读定义位于 `src/application/operations.eli`，对外支持与限制见[能力范围](release-scope.md)。
