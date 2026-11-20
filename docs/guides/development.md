# 开发与打包

## 目录与语言

- `packages/rack/`：独立 Eliscript 插件装配包，含自己的源码、构建配置和测试。
- `src/`：Eliscript 业务、接口、适配器、存储和宿主代码。
- `tests/`：分层测试与 `cases.json` 用例目录。
- `tools/`：构建、打包和验证工具。
- `skills/dj/`：随包交付的 Skill 和引用资料。
- `docs/specs/`：当前产品行为；`docs/archive/`：历史研究与施工记录。
- `docs/index.html`、`docs/pages/`：站点及浏览器实时编译的 Eliscript 源码，不提交生成 JS。
- `.local/`：本机工具链、编译产物、运行包和验收证据，不提交凭据或真实会话资料。

维护单套当前实现，不添加旧字段别名、兼容路由或旧行为开关。开发顺序按项目 `AGENTS.md`：当前功能阶段全部业务实现 → 必要集成功能验收 → 关键保护性测试。

## 固定工具链

Bun 固定为 1.4.4，目标 macOS arm64。Eliscript 编译器与运行库使用同一份 npm 0.1.3 正式发布包。`bun.lock` 绑定归档完整性，`config/toolchain.lock.json` 固定发布源提交、已安装文件摘要及 stage3 回执。`tools/build.eli` 校验这些值后才编译项目。

从干净源码检出直接执行：

```sh
bun install --frozen-lockfile
bun run build:tools
bun run build
```

构建生成 `.local/build/manifest.json`，绑定当前输入与 `dist`、`dist-tests`、`dist-tools` 输出。修改输入后先重新构建；验证和打包不自动接受陈旧产物。重型构建、性能和高内存程序使用当前开发环境的资源保护，不修改宿主全局工具版本。

## 验证

按变更影响选择已有用例；测试场景和启用状态以 `tests/cases.json` 为准，不把历史矩阵全部转成当前任务。

```sh
bun run test:unit
bun run test:integration
bun run test:system
```

Rack 和服务装配的定向验收也可消费已构建产物：

```sh
bun test dist-tests/packages/rack/tests dist-tests/tests/integration/composition.test.mjs
```

这些入口消费已构建产物。真实 IM/Agent 与性能组需要明确的账号、目标和运行范围，不能因为改文档、README 或站点而执行。消息发送结果未知时先查原操作，不为验证重发。验收层次与证据边界见[验收说明](../acceptance.md)。

## 运行包

```sh
bun run package:directory
```

打包器检查当前 manifest，生成全新目录包，不覆盖已有包、不启动服务。包内含 `LICENSE`、第三方 `licenses/`、运行说明、Skill 与文件摘要；私有配置、真实数据和测试不进入包。完整结构见[目录包说明](../../packaging/runtime.md)。

## 文档维护

README 面向首次使用者，保留定位、功能、开始方式和必要链接。使用指南记录当前行为；操作 schema 以 `src/application/operations.eli` 和运行时帮助为准。旧构建编号、方案讨论和逐轮验收明细只放历史资料，不在每份文档重复堆积。更改文件位置时更新引用并检查链接，不把整理文档当作新的功能或验收完成证据。

DJ 自有代码与文档使用[1PL](../../LICENSE)，第三方依赖保留各自许可证。

## 组订阅定向回归

0028 的用例位于 tests/integration/groups.test.eli 与 tests/unit/groups.test.eli，覆盖真实Core/SQLite组选择、重启、pull成员隔离、额度等待和恢复、明确未发送换成员与unknown防重、订阅目标结构的数据保留；纯选择和原生额度证据由后置单测保护。已有many-subscribers、fixed-routes、antigravity-input及必要的存储批量写用例按影响复用，不扩大为全工具、全IM和性能矩阵。
