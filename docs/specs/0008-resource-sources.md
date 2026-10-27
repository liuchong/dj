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

resource.watch(resource_ref,idempotency_key)登记并请求平台文件事件订阅，resource.watch.get(watch_id)查询真实状态。必须有resource.subscribe权限；native_unknown不盲目重新订阅，blocked记录实际错误与权限信息。subscribed只表示平台订阅请求成功，event_channel=configured只表示本机配置，均不等于已看到真实新事件。

当前接收已登记文件的drive.file.bitable_record_changed_v1、drive.file.bitable_field_changed_v1、drive.file.edit_v1；经同一官方WebSocket、持久收件箱、Core形成resource.changed。记录变更按每个真实record_id保留action及字段变更，人员引用从原生after_value解析，重复事件不重复通知；删除记录不自动变成需要修复的任务。收到事件后失效相关内容缓存，不凭旧快照冒充当前内容。

平台要求在应用后台开启相应事件，且调用身份须是文档拥有者/管理者并具备原生权限。没有新事件读回前不得宣称实时链路已验收。文档评论中的@有独立平台语义；没有已核对的原生事件时，只提供获准评论读取，不能宣称已覆盖所有文档@通知。

## 触发与任务判断

已授权来源中，命中订阅的原生@条件即可通知AI；DJ不以“是不是AI的任务”、经办人归属或任务类型作额外判断。AI收到上下文后再按其持久规则判断是否处理、何时处理、是否回复。这些规则由AI自行配置，或由用户指挥AI设置订阅时配置；开发侧不代替接收AI作任务决策。人员字段关联仍与真实@分开。

## 目标与回复

AI通过原有subscription.preview/create选择准确目标会话与资源来源；event_kinds显式选择resource.changed，可用people.id/resource.kind/resource.token/resource.table_id/resource.record_id等组合条件。记录或评论归属作为话题保留，资源信封包含resource_ref及topic，AI可继续读取原资源上下文。业务规则由原接收会话维护，开发侧不代建任务、不改原BUG状态，不因资源读取成功就触发历史工作。

资源事件不生成IM的reply_context_id，不点击IM Typing，也不把普通输出发到任何群。写评论、改记录、编辑文档不属于本批读取与变更支持；不能借读引用做写操作。
