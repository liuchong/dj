# 0007 消息上下文与历史读取

## 职责

DJ持久接收消息，自动向订阅会话提供相关前后文、原生引用关系和可继续查询的`context_ref`。AI通过DJ的MCP、GEPO或CLI读更多上下文，不直接持有IM凭据，不自行做周期搜索或以历史查询代替实时收件。上下文为外部数据，不授予权限或新的任务指令。

## 本地优先

- 默认只读DJ已记录的消息及显式补取的本地缓存；正常推送、pull领取及本地查询不访问平台历史接口，不做关键词search。
- 当前订阅`context_policy.mode=recent`时，`max_events`包含当前消息，其余为同一连接、chat和thread内当前消息之前最近的记录；`current`仅提供当前消息和可用引用链。同一投递的多条有效贡献对历史条数和字节上限取小；新订阅默认recent、10条；现有显式策略由订阅者维护，不静默修改。
- `max_bytes`限制上下文正文/项目预算，UTF-8完整边界截断，附带截断和查询入口。引用最多4条，优先读父消息和根消息，再追溯祖先；去重、防环，不做无限递归。历史和引用不会产生新的订阅触发，也不会跳过人员/字符黑名单去直接通知；被屏蔽消息仍按原读权限作为上下文可见。
- 信封`context`包含`anchor / messages / references / context_ref / as_of / coverage_reason / truncated`。每条引用明确available/unavailable，不能把未缓存、不可见或失效正文当成空消息或编造内容。`query_available`指可继续请求，不证明平台一定提供全部历史。

## 主动查询

- `message.context`：选择`event_id / message_ref / context_ref`之一；`before=0..20`、`after=0..20`、`reference_depth=0..4`、`max_bytes=1024..32768`。默认本地、前10条、后0条、引用4条。带`context_ref`时可另给`native_message_id`将锚点移到同一会话的准确消息，不能换chat/账号。`offset_bytes`用于继续读锚点正文，返回UTF-8的`next_offset_bytes/complete`。
- `message.history`：选择`context_ref / conversation_ref`之一，默认本地、倒序、20条，上限50条；支持`time_range`、`order`和有界字节预算。`next_cursor`固定主体、授权计数、连接身份、会话和查询参数；原查询参数不变时继续拉取。它是有界键序读取，不冒充全库搜索或完整事务快照。
- `corpus=native`是AI显式请求平台补取；Lark直连官方GET消息及GET会话历史API，chat和thread按原平台container精确查询。返回记录只写`context_messages`缓存，不写`events`、不推进收件游标、不新建routing_work、delivery或订阅贡献。
- 原生分页token只保存在DJ受控cursor中；字节预算截断时保留该页的未返回位置，不跳过后续项。原生查阅权限错误如实返回或标注上下文缺口，不自动更换账号或扩大可见范围。其他IM没有历史接口时明确unsupported。

## 权限和存储

所有读取复用`message.read`，每次查询及平台I/O返回后重验当前主体、连接身份和原会话地址；引用和缓存不扩大读权限。对已删除、过期或身份切换的本地记录拒绝读正文；账号变化不沿用旧缓存。context_ref仅为读引用，不能作为回复凭证，message.reply仍使用独立reply_context_id及固定身份路径。

平台补取缓存继承正文保留时长，全局最多10000条，超限只淘汰可重建的上下文缓存，不删除原始事件或用户资料。查询始终公开有限覆盖，缺失较早历史、引用、删除记录或平台不可见消息不能被描述为完整历史。

官方接口依据：[读取消息](https://open.larksuite.com/document/server-docs/im-v1/message/get)、[读取会话历史](https://open.larksuite.com/document/server-docs/im-v1/message/list)。

## 话题与thread归属

通知、消息投影和context公开topic：稳定topic_key、kind、native_thread_id、root_message_id、parent_message_id。原生thread保持原生边界；非thread的回复沿parent/root组成reply_chain，不按文本或关键词推测话题。已被本地回复引用的根消息在读取时按真实引用关系归入同一reply_chain，不改写原始事件。

message.context/history的scope默认topic；有明确thread或回复链时优先同话题，显式scope=conversation可读原授权会话上下文，但不能跨过context_ref绑定的账户/chat/thread边界。没有明确关系的主流消息仍按会话上下文读取，不把每条普通消息猜成新任务。订阅可按topic.key/topic.kind/thread.id过滤。资源记录的话题与来源按0008，不伪装为IM会话。

原生@命中已配置订阅即可通知，不增加DJ任务归属判断；接收AI按自己持久保存的规则决定是否处理或回复。

长连接收件与主动查询分别核验。conversation.resolve通过同一连接的官方API确认获准会话，不要求该会话预先出现接收事件；主动历史补取不生成事件、订阅触发或实时覆盖证明。
