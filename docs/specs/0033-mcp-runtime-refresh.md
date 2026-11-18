# 常驻 MCP 代理的安装更新

## 职责

MCP 是同一 DJ 服务的薄代理。服务与安装包更新后，既有 stdio 连接不能继续用旧操作目录调用新服务。不得取消摘要、权限、参数或结果校验来掩盖目录不一致。

## 实现

- `bin/dj` 保存调用入口的稳定安装路径。MCP 协议外壳保持连接，每次请求通过该路径解析当前物理包，加载当前包的操作目录、客户端和结果校验器。
- 目录投影和结果校验属于 `interfaces/mcp-runtime`；安装路径解析属于 `interfaces/mcp-runtime-loader`；stdio 生命周期属于 `interfaces/mcp`。业务操作仍只在 Core 执行。
- 空闲时每两秒检查安装路径，变化后发送 MCP 标准 `notifications/tools/list_changed`。请求本身立即检查，不等待检查周期。每个请求固定使用一次取得的实现，进行中的操作不切换实现。
- 当前包不可读取、服务未就绪、显式摘要固定值不符时准确失败。不回退旧包，不重试业务操作，不重放消息；未知结果按原操作记录查询。
- 直接从构建目录启动时使用该构建的实现。首次部署这一机制以前已启动的代理需要由客户端重新连接一次；之后稳定入口的常驻代理随安装更新刷新。

## 验收

同一个 MCP 子进程在稳定路径切换前后读到相应目录并收到变化通知；旧工具被移除后立即拒绝；新请求使用当前实现，业务错误、幂等和输出校验继续生效。实际服务更新后核对稳定入口的 MCP 与 CLI 状态一致。

## 能力、权限与规则效果的发现

`service.status`返回`visible_operations`和`unavailable_operations`。后者只含公开操作名、所需action、当前未暴露原因和统一目录help，不读取他人配置。原因分为`operator_required`与`grant_required`；工具目录先执行operator身份约束，再计算授权范围，不能把带connection.manage grant的普通agent展示成管理员。工具可见仍须在请求时核验具体资源与原生能力。

MCP初始化instructions、当前工具description、CLI/GEPO帮助及Skill同步说明：自然语言`session.rules`不执行订阅或过滤；`message.filter`限制触发，`message.recipient_policy`限制出站及自动/手动新增表情。后者现为operator接口，普通调用方应发现准确限制，不借用管理员凭据、不谎报已生效。既有收件人退订的自动登记和所有用户业务规则保持独立。

定向验收使用隔离SQLite和真实stdio MCP：普通agent与operator分别发现目录，MCP与API返回相同权限元数据；隐去的策略接口直接调用仍拒绝，operator可读策略；普通agent增加同名grant也不突破身份边界。结果schema和工具help另有保护性单测。本次2项集成、1项单测共56条断言通过，不运行全套或性能测试。
