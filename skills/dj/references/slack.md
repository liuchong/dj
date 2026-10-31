# Slack

- connection: 先 connection.list/get/probe，核对 platform=slack、workspace、user/bot及身份栅栏；不借用其他连接账号。
- messages: message.list/get/context/history/recover 与 Lark 共用；默认本地缓存，更多上下文显式向原生读取。native_message_id 为 channel:ts，不能截去channel或转数值；thread_id 为根ts。
- subscriptions: subscription.preview/create/update、session.rules.get/update 共用；@、私聊、thread、表情、关键词和正反组合条件都由订阅选择。pushpin 为原生📌名称，keyboard/eyes是工作反馈，不设成触发器。
- replies: message.reply 用通知中的reply_context_id，原连接/身份/话题由DJ固定；普通输出不自动发往Slack。message.send 为显式主动发送。
- actions: message.recall/edit、message.action.get、message.reaction.list/add/remove 可用；平台限制编辑撤回作者，reaction_id=emoji:user_id只能撤当前身份自己的表情。列表可能不含全部反应者。
- completion: delivery.working/complete、message.acknowledge/get 共用；working=keyboard，知道了=eyes。结束或无需回复必须完成处理，DJ持久清理工作表情，不与已阅叠加。
- limits: Socket Mode与HTTP补收分别记录，HTTP默认60秒/页，不保证旧未知thread及离线表情重建；429按Retry-After，缺scope如实返回。未知发送结果先查台账，不重发；不把client_msg_id当exactly-once。
- setup: [仓库配置与权限](https://github.com/liuchong/dj/blob/master/docs/guides/slack.md)；部署时由操作员准备私有app_token和access_token。安装Skill不自动获得Slack权限，不创建Slack应用或自动加群。
