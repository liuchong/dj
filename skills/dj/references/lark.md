# Lark 能力与同身份补充

- catalog: 现有能力总览见[Skill入口](../SKILL.md#lark-能力导航)，按当前服务的可见操作、连接能力和具体schema调用。DJ通过CLI、MCP和GEPO提供同一套能力；这里的DJ CLI和外部Lark CLI是两个不同工具。
- preferred: DJ已有能力优先使用DJ，保留准确回复路由、消息引用、处理表情和可查的操作结果。新增能力时同步更新Skill入口和对应reference，不让使用者只知道旧接口。
- limits: resource.resolve/read支持文档、Wiki、表格、多维表格的读取及已实现视图，resource.watch登记平台变更；不表示DJ已实现任意文档/表格编辑、群成员管理、文件上传或所有Lark办公功能。缺少所需功能时可按下面规则使用Lark CLI，不伪造DJ操作名或已实现能力。

## 功能不足时使用 Lark CLI

- condition: 当前DJ接口不能完成所需操作时，AI可以在原任务授权内使用Lark CLI补充，无需仅为换工具重复申请许可。工具补充不扩大收件人、内容或操作范围。
- identify: 先从connection.get/probe或通知的reply_route确定原计划使用的准确连接、租户、账号与user/bot身份，再核对Lark CLI当前配置和实际认证身份；不靠显示名、环境默认值或“都是我的账号”推断。

- user: 原计划使用本人连接时，保持同一Lark租户、同一真实用户账号，使用本人身份；不得改用机器人。
- bot: 原计划使用机器人连接时，保持同一Lark租户、同一应用机器人账号，使用机器人身份；不得改用本人或另一机器人。

- account_ids: 应用作用域不同的open_id不能直接比较；使用同一应用下的ID或已核实的账号关联确认同一真人。账号未能核实时不凭昵称发送；缺少同身份凭据就说明具体缺口，不自动换账号。
- destination: 原消息回复仍沿原连接、chat、message/thread关系；CLI不会替你恢复DJ的reply_context路由。先还原并核对原目的地，不能把话题回复变成群主流消息或发给另一个人。
- uncertain: DJ已提交或返回unknown的写操作不能换CLI盲目重发。先operation.get、outbound.get或message.action.get核对；只有确认原操作未执行，或这是独立的补充动作时才执行，避免重复发送/撤回/编辑。
- tracking: CLI操作不会自动写入DJ出站台账，也不会自动结束delivery的Working。对已有DJ通知，处理结束仍调用delivery.complete；仅在真实DJ操作记录存在时引用其operation_id/outbound_id，不能伪造DJ accepted或已确认状态。
- implementation: 这是AI调用方的工具补充方式。DJ服务本身继续直连官方WebSocket和HTTPS API，不引入Lark CLI、SDK或子进程作为内部收发实现；不让AI另建收件轮询替代DJ服务。
