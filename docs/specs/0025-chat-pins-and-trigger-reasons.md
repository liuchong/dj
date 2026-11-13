# 0025 — 对话 Pin 与触发原因

消息菜单中的 Pin/置顶到对话，与添加 `Pin`（📌）表情是两种独立动作。新增前者，不替换已有 @、私聊、表情、引用及话题规则；不让 DJ 判断业务任务。

## 接入

Lark 通过官方 `GET /open-apis/im/v1/pins` 获取 Pin 操作；使用当前连接原身份，user/bot 共用实现、独立断点。依据官方消息 API 目录，当前未列出 Pin 新增的推送事件，因此本能力明确是 HTTP 增量补收，不伪造 WebSocket 事件。与群顶部公告、收藏消息、置顶整个聊天窗口区分，本批接入消息菜单中的 Pin。

扫描已配置或已从消息/群发现中获知、且平台授权可读的群和私聊。`pin_poll_seconds` 默认 15 秒（可配 2..3600），这是单群下一轮的等待，不承诺所有群 15 秒内送达；与普通消息共用连接读取预算，独立调度，分页和补正文不阻塞普通收件。覆盖及最后成功时间由连接 `poll_fallback.pin_poll` 显示，权限/网络失败保留原生错误并退避。

每连接先持久保存启用时间，单群保存固定毫秒时间窗口、分页 token、待取正文项及完成水位。只观察启用之后的新增 Pin；首次启用前已有 Pin 不自动补发任务，正常重启保留水位并接续离线缺口。窗口重叠 120 秒，按 connection/identity_revision 与原生 chat/message/operator/create_time 去重。分页、事件入箱及断点在同一事务内提交，失败不推进断点。每轮最多读取一条旧消息正文。移除 Pin 不触发，重新 Pin 使用新原生创建时间触发；接口无法观测已在两次查询之间添加又移除的短暂 Pin，不宣称完整动作日志。

原文优先取当前身份下未过期的本地消息，缺失时按准确 message_id 取官方正文，不按关键词寻找。未能确认消息或来源时保留待处理，不冒充已收到事件。

## 事件与订阅

- `message.pinned`：新的对话 Pin，保留原消息作者、正文、原生 thread、引用和 mentions 作为上下文；`pin.operator` 是动作发起者，`pin.action_time` 是原生毫秒创建时间，`message_source_time` 为原消息时间。原文中的 @ 不作为一次新提及，不冒充 `message.created` 或表情。
- `message.reaction.added` + `reaction.emoji_type=Pin`：原有 📌 表情，保持独立。
- `trigger.kind` 对 Pin 取 `pin.operator.kind`；人员/字符过滤仍同时检查原作者与动作人。人类 Pin 机器人消息不会因为原作者是机器人而被“机器人不触发”误挡；机器人的 Pin 动作仍遵守全局规则。Pin 自身不因原文是 DJ 已发消息而被当成消息回声。
- 新订阅省略 event_kinds/predicate 时默认包含 Pin；显式订阅由调用方追加 `message.pinned` 和普通 `any` 分支，不自动修改既有订阅或提示词。可组合 `pin.operator.id/kind/is_self`、群、作者、正文与正反条件。删除这条分支即可关闭此触发。
- Pin 的回复保持接收连接原身份与原消息位置；不从旧正文的 mentions 重新挑选出口，不向 Pin 操作人另开私聊。仍通过固定 reply_context_id 回复。

## 统一原因

事件查询、上下文和给 AI 的推送/拉取通知提供 `trigger_reasons: [{code,label}]`。这是机械识别的原生动作/关系，一条消息可以有多项原因，不代表每一项都单独命中了订阅。实际命中的订阅仍看 `matched`，自定义关键词/组合规则没有原生关系原因时用 `subscription_rule`，不编造关键词。

| code | 含义 |
| --- | --- |
| mention | 消息包含原生 @；当前身份或跨出口目标看 mentions/reply_route，包括主动 @ 自己 |
| direct_message | 私聊 |
| reaction_pin | Pin/📌 表情标记 |
| reaction | 其他表情，中文说明包含原生 emoji_type，动作人看 reaction.operator |
| chat_pin | 消息菜单中的 Pin/置顶到对话，动作人看 pin.operator |
| thread_reply | 相关原生话题的新回复，依据看 interaction.basis |
| quoted_reply | 引用/回复当前身份的消息 |
| resource_mention / resource_change | 资源提及或变更 |
| subscription_rule | 由其他订阅规则筛选，具体订阅看 matched |
| direct_input | DJ API 定向输入，不是 IM 事件 |

标记类事件只报告当前标记原因，不把原文旧 @、旧私聊或旧引用报告成新动作。原因不能授权外发、强制新建任务或替代规则；MDP 展示保留清楚的中文说明，结构化 API 保留稳定 code。

## 官方依据与验收

[Pin 列表](https://open.feishu.cn/document/uAjLw4CM/ukTMukTMukTM/reference/im-v1/pin/list)、[消息 API 与事件目录](https://open.feishu.cn/document/uAjLw4CM/ukTMukTMukTM/reference/im-v1)。原生操作人类型、毫秒时间和分页字段按官方接口核对；DJ 内部仍直接 HTTPS，不依赖 SDK 或 CLI。

验收使用正式 Core、SQLite 与官方 HTTP 协议替身覆盖启用边界、分页、重启、去重、重 Pin、双身份、旧正文、过滤、通知及原因；官方只读样本与模拟链路分别记述，不创建真实群 Pin 冒充接收验收。

本批定向验收：21 项通过、1028 条断言，覆盖上述接入、身份、退订及通知边界；未重复运行全套或性能矩阵。另以本机两条既有连接只读调用官方 Pin 列表均成功，本人私聊 Pin 列表亦成功；没有人为在业务群新增 Pin 或发送验收消息，真实新增 Pin 的自然样本另行观察。
