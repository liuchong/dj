# 0024：已发送消息的回复与 Lark 话题创建

## 行为

`message.reply` 接收 `content`、幂等键，以及严格三选一的 `reply_context_id`、`outbound_id` 或 `native_anchor`。已认证调用方可沿原通知回复，或用已被平台 accepted、且仅有一个原生消息 ID 的出站消息作为锚点。Lark 还支持 `native_anchor={conversation_ref,native_message_id}`，以现有群消息为锚点。操作使用锚点固定的目的地和账号。出站台账的查看范围单独校验。

Lark 可设置 `reply_in_thread=true`，调用官方消息回复 API 创建或续接话题。已有话题默认沿原话题，false 不把它移回群主流。普通群可先 `message.send` 发简讯，再对其 accepted outbound 回复详情。话题形式群直接发送主消息时由平台生成话题根。仅有 thread_id 的 Lark destination 仍不是独立可发送锚点。

返回的 outbound 投影包含 `reply_to_outbound_id`、`native_reply_to`、`reply_in_thread` 和平台证实的 `native_parent_id`、`native_root_id`、`native_thread_id`。发送 accepted 后方可将本条作为下一次回复锚点。话题消息仍可按 outbound_id 编辑、撤回及操作表情，使用实际话题位置校验。

## 一致性与身份

- 所有回复共用原 outbound/attempt/receipt、发送前持久化与幂等机制，CLI/MCP/GEPO 不另建发送通道。
- outbound 锚点检查当前主体的回复权限、账号身份栅栏和原 accepted 单消息事实。读取出站台账单独检查查看权限。原锚点若继承订阅回复上下文，后续继续携带并复核原身份、有效期和 pull 领取约束。
- native_anchor 沿会话引用固定的连接原生回读消息，核对原生消息 ID、群、话题及原作者，检查来源范围和读取、回复权限。接线和出站提交复核身份版本与接入权限，禁发和退订使用已核实的原作者，即使对应消息从未入库。原生回执缺少位置时可回读一次新消息。回执或读回仍无法确认要求的位置时，保留 `unknown`。
- 新发送独立检查收件人禁收状态；force_send 不从父消息继承，仅在本次用户明确要求时单条豁免。入站订阅、业务规则和既有退订状态不变。
- 请求创建话题但官方回执未给出有效 thread_id 时保留 unknown，不伪造成功或自动重发。非 Lark 的显式话题创建参数返回 unsupported，既有 Slack 话题回复不变。

## 能力说明

`message.send/reply` 的 content.type 支持 text 和 Lark 专用 markdown，后者直连官方 post/md 标签，不经过 CLI/SDK 或另建发送通道。message.edit 允许同类型的 text/post Markdown 修改，不转换类型。Markdown内容保留原文，退订后缀、收件人检查、身份与台账共用；其他平台的显式 markdown 请求返回 unsupported，不静默降级。

中文链接优先使用可读标题与完整编码的绝对URL，路径/查询/fragment分别保留语义，合法百分号不重复编码。DJ不猜测锚点、不修改目的URL；Skill给出new URL(raw).href及Markdown尖括号目标示例。原生读回核对内容不冒充客户端点击验收。

图片、文件和卡片发送不因通用 OpenAPI 存在而冒充已实现。message.reply_context 可在原有效期内重取引用，不能延长有效期。操作帮助和 Skill 必须区分产品缺口、参数错误、账号权限、身份冲突与收件人禁收。

官方依据：[话题概述](https://open.larksuite.com/document/uAjLw4CM/ukTMukTMukTM/reference/im-v1/message/thread-introduction)、[回复消息](https://open.larksuite.com/document/server-docs/im-v1/message/reply)、[消息内容及post/md](https://open.feishu.cn/document/server-docs/im-v1/message-content-description/create_json?lang=zh-CN)。

## 回归入口

`T40.topic-replies.integration` 使用真实Core、SQLite和官方HTTP协议替身，覆盖user/bot、主消息与话题创建/续接、原生位置变化后的编辑撤回、Markdown原文与编码URL、幂等、unknown、来源有效期、禁收和单条force_send。`T40.native-topic-reply.integration` 覆盖无 DJ 投递或出站的原生锚点、父消息/根消息/话题位置读回、幂等和退订拦截。`T38.message-actions.unit` 保护互斥参数和原生 Markdown 编码。

构建后可定向运行：`bun test dist-tests/tests/integration/message-actions.test.mjs dist-tests/tests/unit/message-actions.test.mjs dist-tests/tests/integration/recipients.test.mjs dist-tests/tests/integration/mention-replies.test.mjs dist-tests/tests/integration/lark-api.test.mjs`。这属于本地集成及保护性回归，不冒充真实Lark客户端点击或全平台功能验收。
