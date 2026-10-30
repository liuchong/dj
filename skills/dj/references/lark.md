# Lark 能力与同身份补充

- catalog: 现有能力总览见[Skill入口](../SKILL.md#lark-能力导航)，按当前服务的可见操作、连接能力和具体schema调用。DJ通过CLI、MCP和GEPO提供同一套能力；这里的DJ CLI和外部Lark CLI是两个不同工具。
- preferred: DJ已有能力优先使用DJ，保留准确回复路由、消息引用、处理表情和可查的操作结果。新增能力时同步更新Skill入口和对应reference，不让使用者只知道旧接口。
- native_api: 除已有消息与资源操作外，可用lark.api.read/call调用官方各业务域的原生API，包括文档编辑、表格、Wiki、通讯录、群成员、日历、任务及文件上传下载等。通用入口提供方法、路径和内容，不要求每个端点都有专用DJ命令；先按官方文档确定原生参数及当前账号权限，不能因没有专用命令就报告DJ不支持。
- limits: 原生API入口不自动创建DJ订阅、不自动绑定回复位置、不自动结束Working，也不把平台受理等同最终业务完成。原生权限、账号可见范围、接口限制和真实逐端点验收分别报告。

## 官方 API 通用入口

- connection: 先connection.get取得准确connection_id、identity与identity_revision。每次请求明确这两个字段；凭据和Bearer由DJ注入，禁止把token、secret放入参数。本人和机器人各自连接，绝不在失败时换身份。
- read: lark.api.read固定GET。path以/open-apis/开头，query为原生键值对象；例如读取文档块时按官方文档填写docx/v1/documents/{document_id}/blocks路径。不接收任意域名。
- write: lark.api.call明确POST/PUT/PATCH/DELETE、path和唯一idempotency_key；body是原生JSON对象，原生content若要求JSON字符串仍按官方协议填写。先持久记录unknown再调用官方API，同键重试只返回原结果，绝不二次执行。
- files: multipart上传使用form，普通字段是标量，文件字段是含base64、filename、可选content_type的对象；body与form互斥。单文件及API响应最多512KiB，受DJ请求总大小限制。大文件可由程序使用独立包的Blob/File与分块原生API，不把本接口预算误报成平台限制。
- output: response_mode默认json，可选text或bytes；bytes的response是base64。结果保留http_status、native_ok、response、日志/限流等安全响应头。原生非零code与permission_violations在response里，不把外层ok当成原生成功。
- pagination: 使用原生response.data.has_more/page_token等字段显式续页；不同端点字段按官方文档，不自动扫描全租户或无限拉取。
- state: accepted表示原生接口受理；rejected表示明确原生拒绝；unknown表示调用结果不确定。用lark.api.get(action_id)或operation.get查询，unknown禁止换键或换CLI补做；HTTP限流也不自动重发写请求。
- managed: 普通消息发送、原消息回复、撤销、Working及资源订阅优先已有message/resource接口，保留固定身份、位置、回声防重及业务台账。原生办公操作可用通用入口；原生写入不会自动生成DJ出站/资源订阅记录。
- excluded: OAuth登录、令牌签发/刷新由连接内部管理，通用入口不暴露认证接口。缺少原生权限时报告response中的具体权限，不声称整个Lark功能未实现。
- docs: [Lark官方服务端API](https://open.larksuite.com/document)、[飞书官方API](https://open.feishu.cn/document)。先读准确端点文档，参数和user/bot支持由该端点决定。

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
