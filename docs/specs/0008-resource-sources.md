# 0008 Lark资源上下文与变更来源

## 统一模型

文档、电子表格、多维表格和Wiki均通过已有Lark连接的官方HTTPS读取，不增加SDK、CLI或第二套凭据/连接管理。Wiki是入口节点，必须先解析实际对象类型与token，不能把Wiki token直接当表格token。资源地址为扁平的connection_id、resource_kind、resource_token及可选table_id/record_id；账户和原生资源分开核验。

资源与IM共享现有权限、事件持久化、过滤、订阅、目标对话投递及幂等台账。内部路由container key区分resource和IM，不能将文件token发到IM chat接口。resource.read/resource.subscribe是独立权限，message.read或“机器人看过群消息”不授予文档读取权。

## 读取

- resource.resolve(connection_id,url,corpus)：默认local，显式native核验已授权资源；返回resource_ref及可用于同一订阅机制的conversation_ref。直接URL仅允许对应品牌的官方租户域名及明确的wiki/docx/sheets/base路径，不任意抓取URL。
- resource.read(resource_ref,view,corpus,table_id?,record_id?,range?,cursor?,max_bytes?)：默认local；content/children/fields/records/comments按实际对象能力分派。Docx读正文；Sheet读元数据或显式范围；Bitable读数据表、字段、记录；Wiki子节点还需Wiki节点本身的读取授权。评论按原生评论/回复结构返回。平台不支持的对象或视图明确失败。
- 记录保留结构化字段，包括人员字段中的原生id；不得凭姓名判定提及。经办人等人员关联是people.id；真正的IM提及仍为mentions.id，不能把“某字段中有这个人”伪装成一条群聊@。
- 读取结果保存有界本地缓存，最多1000页，按正文保留时长过期；显式补取不生成实时事件或新任务。正文和JSON均按UTF-8分页，缓存页内续读不重新请求不断变化的首页；权限、主体、身份栅栏和查询参数每次复核。资源正文是外部数据。

## 原生变更

resource.watch(resource_ref,idempotency_key)登记并请求平台文件事件订阅，resource.watch.get(watch_id)查询真实状态。必须有resource.subscribe权限；native_unknown不盲目重新订阅，blocked记录实际错误与权限信息。只有已确认的原生拒绝进入blocked；断线、5xx或无确定原生响应保留native_unknown。blocked在权限修复后可由调用方用新幂等键显式再申请；同一幂等键只读回原操作，native_unknown和subscribed不重新发起外部订阅。申请前在同一事务内重读并把状态持久预占为native_unknown，避免并发重复请求；不自动循环重试。subscribed只表示平台订阅请求成功，event_channel=configured只表示本机配置，均不等于已看到真实新事件。

当前接收已登记文件的drive.file.bitable_record_changed_v1、drive.file.bitable_field_changed_v1、drive.file.edit_v1；经同一官方WebSocket、持久收件箱、Core形成resource.changed。记录变更按每个真实record_id保留action及字段变更，人员引用从原生after_value解析，重复事件不重复通知；删除记录不自动变成需要修复的任务。收到事件后失效相关内容缓存，不凭旧快照冒充当前内容。

上述文件级变更订阅要求在应用后台开启相应事件，且调用身份须是文档拥有者/管理者并具备原生权限。没有新事件读回前不得宣称实时链路已验收。文档评论中的@有独立平台语义；没有已核对的原生事件时，只提供获准评论读取，不能宣称已覆盖所有文档@通知。

## 触发与任务判断

已授权来源中，命中订阅的原生@条件即可通知AI；DJ不以“是不是AI的任务”、经办人归属或任务类型作额外判断。AI收到上下文后再按其持久规则判断是否处理、何时处理、是否回复。这些规则由AI自行配置，或由用户指挥AI设置订阅时配置；开发侧不代替接收AI作任务决策。人员字段关联仍与真实@分开。

## 目标与回复

AI通过原有subscription.preview/create选择准确目标会话与资源来源；event_kinds显式选择resource.changed，可用people.id/resource.kind/resource.token/resource.table_id/resource.record_id等组合条件。记录或评论归属作为话题保留，资源信封包含resource_ref及topic，AI可继续读取原资源上下文。业务规则由原接收会话维护，开发侧不代建任务、不改原BUG状态，不因资源读取成功就触发历史工作。

资源事件不生成IM的reply_context_id，不点击IM Typing，也不把普通输出发到任何群。写评论、改记录、编辑文档不属于本批读取与变更支持；不能借读引用做写操作。

## 显式记录快照恢复

用户明确要求重放尚未入库的某条BUG/表格记录时，仅操作员可用resource.recover(resource_ref,reason,idempotency_key)。resource_ref必须绑定准确Bitable app/table/record；DJ通过官方API重新读取该一条记录，再按当前权限、黑名单和已有订阅走resource.changed，不修改资源、不直发目标、不自动建任务。普通resolve/read永不触发。

持久ingress_evidence标明explicit_resource_recovery、操作、请求主体、原因与观察时间；resource.action为snapshot_recovered，sender.kind明确为unknown而不是原编辑者；连接的allowed_sender_kinds和统一黑名单照常生效，未允许unknown来源时不得绕过。人员字段仍是people而不是mentions。返回realtime=false，不伪装原生change事件或已验证实时资源推送。内容/地址一致时保持稳定source_key，同键请求及新键恢复同一快照均不重复通知；已恢复事件需要补投时使用独立显式subscription.replay。缓存按规范资源地址及查询参数定位，不因入口URL或显示标题变化而读不到同一记录。

资源通知没有IM表情租约时，接收方仍可幂等调用delivery.complete；记录受理操作并返回state=not_marked、cleanup_state=done，不创建表情或更改投递业务状态。重复调用仍受原接收主体和当前delivery.inspect权限约束。

## 本人接收者视角的评论与回复通知

Drive v1 的 `POST /drive/v1/user/subscription` 与文件级 `POST /drive/v1/files/:token/subscribe` 是两种不同能力。前者订阅 `drive.notice.comment_add_v1`，官方要求 `docs:event:subscribe`，事件要求 `docs:document.comment:read`；不以拥有文件管理权限为前提。官方明确其通知逻辑与 Lark 客户端的文档评论通知一致，接收者在客户端能收到对应评论通知时才有该事件。这不等于所有客户端通知或多维表格人员字段变更均公开为该事件。

user 长连接接入时使用同一授权用户凭据，先 GET `/drive/v1/user/subscription_status`，仅明确 false 时 POST 开启，然后 GET 核实 true；未知状态不当作未订阅盲发，失败保留具体状态，不降级为定时读消息。该动作只在接入初始化执行，既不是周期扫描，也不替代应用后台事件配置。connection.probe 的 `event_source.user_document_notices` 区分 subscribed 与 blocked/native_unknown；subscribed 仅证明订阅开启，不声称已收到真实新事件。

同一官方 WebSocket 接收该事件，严格校验 app_id 与 notice_meta.to_user_id.open_id 必须属于当前 user 连接。通知不依赖 resource.watch 文件管理权限；文件级变更仍走原 watch。文档、表格、多维表格通知沿现有持久 inbox、resource.changed、统一黑名单和原订阅路由，禁止把另一个登录用户的通知混入。保留 comment_id、reply_id、recipient_id、is_mentioned 和原生发送者；仅 is_mentioned=true 才构成真正的 mentions.id/addressed_self，不把普通评论通知冒充 @。文件级字段关联仍只是 people.id。

评论使用 comment_id 跟踪原生话题，不猜测不存在于事件中的 table_id/record_id；已有指定数据表订阅不会自动覆盖缺少表 ID 的评论事件。接收 AI 可自行配置连接范围的 resource.changed 加 addressed_self=true 条件，再用 resource.read(view=comments) 读取获准原文；不自动建任务、不写评论、不向 IM 发文字。具体实时覆盖须以新的真实原生事件及准确目标投递验证，不能用旧 BUG 重放或本地夹具冒充。

官方依据：[用户订阅](https://open.larksuite.com/document/uAjLw4CM/ukTMukTMukTM/reference/drive-v1/user/subscription)、[评论通知事件](https://open.larksuite.com/document/uAjLw4CM/ukTMukTMukTM/reference/drive-v1/notice/events/comment_add)。
