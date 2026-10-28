# 0009 任务巡查施工

基线 a3a2c67；单一 Eliscript 实现。需求与边界见 ../specs/0009-task-inspection.md，不修改接收助手的持久业务规则。

当前流程：IM → ingestion.acceptEvent → routing/matcher → deliveries/routes → 原 AI 会话；会话目录没有统一的任务父子关系。
目标流程：原台账 → tasks.service → 任务/平面来源树；IM /dj 命令 → tasks.commands → 原 message.send → outbound/echo；确定性命令不交给 AI。task_links 保存准确 delivery+parent+child，task_commands 保存原事件和固定回复请求。

- [x] src/tasks/service.eli（新建）：inspectionScope、visibleDelivery、projectTask、listTasks、taskTree、handleOperation，统一权限与有界展开。
- [x] src/tasks/commands.eli（新建）：stageCommand、commandPrincipal、commandText、processCommands、taskOutboundAllowed；原入库事务登记、原出站幂等和发送前配置/身份重检。
- [x] src/service/config.eli serviceConfigSchema/prepareConfig：task_inspection 白名单、账号绑定和重复身份拒绝；src/storage/schema.eli migrate：两张扁平表。
- [x] src/application/{operations,results,help}.eli：task.list/tree/link 当前 schema、返回投影及帮助；src/service/core.eli installHandlers 装配 tasks。
- [x] src/ingestion/service.eli acceptEvent：命令路由 done；src/service/runtime.eli tick：每次最多处理 2 条命令；src/messaging/service.eli acceptOutbound/outboundReady：复用正常外发并重检巡查授权。
- [x] Skill 与使用指南：只显示数据，未知关联不猜，用户隔离。
- [x] 一次集中执行权限/树/IM 命令真实 Core 集成及回归；原回复引用可在原 TTL 内重取，旧授权引用仍拒绝。
- [x] 关键保护性单测（2项）及相关 Desktop 回归（1项）通过。
- [x] 运行包安装、私有管理员配置和真实查询读回；已通过官方 IM 私聊 /dj tasks 入库、确定性处理、正常 outbound 发送和官方 GET 读回，未唤醒 AI。

独立紧急消息：现场已确认私聊已实时入库、match，因原助手 busy 排队，未 accepted 故无 Typing。不得把队列当漏收重放；待原会话自然接受后核对处理/Typing，不代替助手执行消息中的群聊操作。
