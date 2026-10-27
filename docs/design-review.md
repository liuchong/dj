# 整体设计审阅与处置

日期：2026-10-23。基线：master / 6c504c3。范围：基线全部 23 个 Markdown 文件，重点为需求、组件边界、状态/权限、流程、CLI/MCP、Skill 与资料声明。由当前 Agent 完成设计审阅；没有调用独立审阅者、运行产品、连接真实服务或编写实现。

用户本轮明确的约束：DJ 是无 AI 的、高效的网关/订阅转发组件，不能调用大模型或寄望自动理解；面向调用方模型优化正确使用。下表行号仅指基线，不冒充修订后当前行号。

| ID | 优先级 | 基线问题与位置 | 本轮设计处置 | 后续验收 |
| --- | --- | --- | --- | --- |
| R01 | P1 | requirements.md L32/L40 没明确谁理解自然语言，还将语义分类/摘要列未来候选 | 新组件契约将无 AI 固定为产品边界，理解与答案归调用方；全套文档同步 | T25 |
| R02 | P1 | operations.md L36–L39/L84：preview 无固定句柄，create/update 可提交另一份 spec | 类型化 preview_id 固定规范化 spec、主体/版本；提交只接票据并检查漂移 | T28 |
| R03 | P1 | operations.md L17/L43–L48：提及按 operation_id 查询却无操作入口，出站只有受理返回 | 补 operation.get 与 outbound 查询/核对/安全控制，明确原子台账、超时 not_found 竞态 | T29/T34 |
| R04 | P1 | domain-model.md L28 与 security 调用身份：自报与真实所有权核验之间缺启动绑定契约 | 可信主体 target_constraint、独立 recipient、原子登记；DJ 不猜当前会话 | T26/T33 |
| R05 | P1 | domain-model.md L17/L65、delivery-storage.md L48：同目标多订阅只合并身份，未定义策略/授权/TTL 冲突 | Contribution 独立版本/权限/过期；queue 优先、上下文取小、短 TTL 不抹长贡献 | T30 |
| R06 | P1 | workflows.md L56：暂停承诺“尚未提交”但未定义与网络写出竞态 | submitting 事务为提交点，先后原子决定；之后不保证撤回 | T31 |
| R07 | P1 | domain-model.md L55/L67：空 all 与“编辑/删除默认不触发”冲突；截断正文的否定匹配无定义 | selector.event_kinds 明确范围；三值判定与不完整正文规则，不确定不触发 | T32 |
| R08 | P2 | architecture.md L51 与 storage 仅有容量上限，缺高效路由/计算预算 | 索引候选、编译规则、结果复用、分批续算、公平队列及待测性能基准 | T27 |
| R09 | P2 | operations.md L43、Skill 依模型拼原生地址，错误信息缺字段和确定下一步 | conversation_ref 等有类型句柄，严格 schema、field_errors/effect_state/固定 next_actions | T26 |
| R10 | P2 | 领域 ReplyContext 定义与 Skill 过期处理：未定签发时点/无回复权限/刷新接口 | 提交前签发、绑定 recipient，允许 null；首轮不自动刷新/主动发送兜底 | T33 |
| R11 | P2 | delivery-storage.md L60/L66：人工结案无工具定义，跨 IM hop_count 无可靠来源链 | operator-only resolve 只不重发；首轮撤销跨平台 hop 保证，按可证 ID 抑制回声 | T13/T35 |
| R12 | P2 | workflows.md L60：恢复使用未定义的 prepared 状态 | 改为规范中的 ready/deferred/blocked，submitting 恢复 unknown | T11/T31 |
| R13 | P1 | storage 保留与删除可见性未覆盖 queued 原文、外部正文与可信头隔离 | 删除 tombstone 影响旧正文与提交前输入，正文严格结构化编码 | T36 |
| R14 | P2 | operations.md 历史查询共用只读 Event，但没有防止占用源去重键 | 新 MessageSnapshot/message_ref 与 live Event 分离，查询不触发也不吞 live | T37 |

以上问题均已在相应现行设计中修订，不能解释成运行时修复或产品测试通过。没有引入通用 AI、语义路由、模型自动修参或额外审批流程；Skill 与接口共同减少模型误用，服务仍承担确定性验证。

## 仍然保留的真实限制

- 格式有效、权限允许但选错用户意图的目标，DJ 无法理解并纠正；调用方须核对摘要与预览。
- 厂商 idle 唤醒、lookup、私有接口兼容和源 CLI 重放仍需要目标版本真实测试，不能由本轮文档审阅补证据。
- 技术语言、发布/嵌入 ABI、首个接入组合与远程部署范围仍按 decisions.md 的 O 项处理；不伪造实现选型结论。
- CPU/内存/吞吐数字只是明确的待测目标，T01–T37 没有运行；文档检查与产品验收分开。

后续选型补充：上述语言、发布/嵌入面和首批组合现已在 [技术选型](technical-stack.md)与[首批范围](release-scope.md)收敛；剩余的是精确依赖、兼容与性能实证。原审阅结论作为 6c504c3 基线记录保留，当前接续以 status.md 为准。

## 文档一致性检查

最终集中验证本地链接/锚点、JSON 示例、Skill 元数据、旧参数和未定义状态的残留、受影响接口的一致性、需求到验收的覆盖、暂存路径与 diff。实际结果在 status.md 记录；提交签名从 Git 验证，不在文档中预填自己的提交 ID。

## 追加控制面后的整体复审

日期：2026-10-23；基线 master / bd6b8e2（31 份 Markdown）。重点交叉核对统一目录/搜索、免订阅直发、start/create/stop 与原有 IM 订阅、权限、持久队列、CLI/MCP/API 和 Skill。以下位置按基线章节定位，不使用修订后的行号；仍由当前 Agent 审阅，未运行产品、连接真实工具或编写实现。

| ID | 优先级 | 基线问题与位置 | 本轮设计处置 | 后续验收 |
| --- | --- | --- | --- | --- |
| R15 | P1 | agent-control-plane“范围/机械搜索”：全局时间排序与预算内增量返回冲突，sort 值未明确 | search 仅稳定键；list 可索引时间排序；空页带 cursor 仍未完成，组内进度保留 | T59 |
| R16 | P1 | agent-control-plane“快照”：引用快照与后台更新/索引修订的持久边界不清 | catalog_seq 逻辑版本，无跨请求长 SQLite 事务；撤权/删除/版本驱逐显式失效 | T60 |
| R17 | P1 | agent-control-plane“刷新”：未区分半次枚举的未出现与可证明删除 | partial/预算耗尽不得 tombstone；仅明确删除或协议可证完整缺失，覆盖单列 | T61 |
| R18 | P1 | security 权限表、operations filters、storage“多贡献”：仍按 agent_id 授权/去重，未登记直发无管理闭环 | direct 按发送主体查控；扩精确过滤；route+event 去重，登记/注销不清队列/屏障或取消 direct | T62 |
| R19 | P2 | 控制面 scope/get：未登记会话无法按稳定键定点补正文/重取引用，也无只读 receiver 探测接口 | session_keys 过滤、get 的 ref/key 二选一、session.probe；三入口/Skill 同步 | T63 |
| R20 | P1 | Lifecycle 输出/Skill：Pi 初始会话引用、过期 ref 重放及历史 ready 与当前状态未收口 | 持久 initial_session_key/session_key，lifecycle/get 重取引用，历史动作与当前实例分列 | T64 |
| R21 | P1 | start/create/stop 与订阅提交：独立状态无法裁定并发先后，drain 可能死等队列为空 | 共用持久 gate/epoch/submitting 事务；停止拒绝新启用、保留旧队列，只等在途与原生工作 | T65 |
| R22 | P1 | instance.start 单 slot：stopping/unknown/manual 结案后的再启动缺归属栅栏 | 已证退出才释放 slot；manual 不释放；新 incarnation 新 ID/epoch，禁止重复拉起 | T66 |
| R23 | P1 | session.create 到登记/订阅：新会话没有 recipient/工具接线，创建者 whoami 不能代表接收方 | 首期由可信部署面接入独立 recipient/精确约束/Skill 工具，再登记与核对；不改绑创建者 | T67 |
| R24 | P1 | startup-to-reply 停机直接结束 Pi，与 instance.stop“不强停活跃任务”冲突 | 服务停机复用 drain，监督器不连带强杀；期限到仍 draining，强制终止只报中断风险 | T68 |
| R25 | P1 | 全量 RPC 大帧仅写“排空到尾”，缺无帧尾/关联丢失的失败边界 | 排空截止、通道隔离、相关输入 unknown；不杀工具，不在失步流上继续提交 | T69 |
| R26 | P2 | release-scope 对复合 T 场景适用不清；启动配置 instance_id 与 Agent 实例撞名，managed 仍只提 Pi | 统一正向/拒绝/后续矩阵与完整流程；service_id 独立、两 managed profile 接线同步 | T70 |
| R27 | P2 | live 观察到期一律 runtime unknown，覆盖已证进程退出/offline | 仅新鲜度限定状态到期；明确离线/不兼容等待相反原生证据 | T71 |
| R28 | P2 | session.send“current/queue/hold”未区分上下文与投递策略，原生限额变化可能被截短 | 严格 delivery_policy 字段，直发无 IM 上下文；超限拒绝/blocked，不默默截短 | T72 |

14 项均已落实到所属现行契约与直接消费者；加上历史 R01–R14 共 28 项设计处置，新增 T59–T72 场景仍全部待执行。没有扩大首期平台或引入 UI/AI；新会话自动配置工具/凭据没有被偷偷纳入 create。

现阶段设计可继续进入未来的详细施工设计；依赖锁定、Eliscript 宿主互操作、SQLite 查询计划/版本保留成本、原生 idle/lookup/资源归属与安全停止仍需实现阶段实证。尤其不可重连 stdio 与进程监督的停机行为若达不到 T68，就不能发布“无损优雅停止”承诺。没有把这些运行风险伪装为已解决的测试结果。
