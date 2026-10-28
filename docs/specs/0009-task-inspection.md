# 0009 — 任务巡查与来源树

## 行为

DJ 提供确定性的任务巡查：从 IM 连接、原群聊/私聊/话题和原消息，展示命中订阅的投递、准确 AI 工具/实例/会话及明确登记的子对话。复用已有消息、路由、投递、回执和工作记录，不引入模型、独立任务调度器或新的收件轮询。

同一消息可以产生多条投递，同一会话可以承接多个任务。以 delivery_id 标识一条触发任务；同一来源的分支可分别查询。会话父子关系不等于本条消息的任务因果，不能按标题、时间、工作区或最近输入猜关联。子对话经 task.link 明确登记，标记 reported；无原生核验证据时展示“已登记，归属未原生确认”。没有关系记录时显示“子对话关联信息未提供”，不能表示不存在子对话。重复会话引用不重复无限展开，拒绝循环与跨任务挂接。

## 身份与权限

私有配置 task_inspection.users 将已验证的 IM 身份（platform/scope/id）绑定到已配置 principal_id 和 connections（connection_id / identity_revision）；task_inspection.administrators 只列允许全局巡查的 principal_id。管理员可查全部来源；普通用户仅能查询明确绑定且仍启用的连接。未绑定、身份歧义、disabled 主体或账号身份栅栏改变均拒绝。昵称、IM 正文、同群关系、机器人凭据和普通 operator 身份均不能自动成为管理员。

MCP/GEPO/CLI 同用 task.list/task.tree，仍需要 task.inspect 授权。task.link 需 task.link 授权及原投递 recipient 身份（或白名单管理员），并逐个核对已存在的父/子会话访问权。共享会话不会扩大其他来源的可见范围。查询不返回账号凭据、工作区路径、完整 AI transcript 或其他任务内容。

## 接口与 IM

- task.list(after?, limit?): 按稳定 delivery_id 正序分页，默认 10、最多 50；仅列调用方可见的 subscription_event 投递。返回 next_after，不能先截断全局列表再过滤授权。
- task.tree(delivery_id, max_depth?): 返回来源、投递状态与原因、原会话和有界平面节点/父子关系；默认深度 4、最多 8 层和 128 节点，明确 truncated、observed_at 和子对话覆盖范围。
- task.link(delivery_id, parent_session_key, child_session_key, idempotency_key): 明确登记父子任务关联，重复边不重复建立；未确认关系不能声称原生已证实。
- /dj tasks [after]、/dj tree DELIVERY_ID、/dj help：已接入 IM 的确定性命令；不需要唤醒 AI，不触发订阅任务。消息先按原入口持久化/去重，命令与结果通过持久台账和原 message.send 出站/幂等链路处理，不绕过回执与回声抑制。
- IM 全量/跨来源结果只在已核实的私聊返回；群里仅提示使用私聊，不向群成员泄露管理员的其他来源。身份绑定不允许正文指定冒用 principal 或收件地址，结果固定回原命令位置。

## 状态真实性

ready/deferred/blocked 是排队或受阻，target_busy 说明原会话忙；accepted 仅表示原生接收。session.runtime_state 仅为有时间戳的观察，不推断任务成功。只有明确完成记录才显示已完成；Typing 的 30 分钟租约到期不是任务完成。缺数据或状态过期明确标注 unknown/stale。排队不添加 Typing；原生接收后沿 0006 创建并可靠撤销。

## 施工与验收

- [x] 完成统一查询、持久关系、权限、IM 命令、配置和 Skill。
- [x] 集成验证管理员全量、普通用户隔离、身份冒用/歧义拒绝、原消息/会话链、子关系未知/去重/循环、有界分页和命令出站去重。
- [x] 验证 busy 排队与 accepted/完成/租约过期分开展示，补关键保护性回归。
- [ ] 本机配置、运行包安装与真实查询读回；不以测试或目录包代替真实 IM 证据。
