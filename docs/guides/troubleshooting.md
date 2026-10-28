# 故障排查

先使用自己的客户端 profile，不借用其他对话或操作员凭据。以下命令中的 ID 和文件名替换为实际值；完整参数以对应 `--help` 为准。

## 服务无法连接

```sh
dj status --client-profile PRIVATE_PROFILE --json
```

检查服务是否运行、profile 是否指向同一个私有 socket、配置与目录权限是否正确。macOS 服务的 label 为 `dev.dispatch-junction.local`，检查方式见[常驻服务](macos-service.md)。不要另起一个相同状态目录的服务来绕过原实例。

## 已收消息，但没有通知 AI

依次核对：

1. `connection.list` 的身份及 `connection.probe` 的源健康与事件覆盖。本人能在客户端看到，不等于某种开放事件已授权。
2. `subscription.get` 的状态、准确目标、来源选择器和 predicate。省略来源表示获准范围的全部对话；原生 @ 与正文里打出的名字不同。
3. `message.filter.get` 的触发策略。黑名单消息仍可入库、读取，但不会直接触发通知。
4. `agent.probe` / `session.probe` 的真实 receiver、实例与会话。只有历史记录不代表已有活接收口。
5. `delivery.get` 的状态和错误。`ready` 是排队，`blocked/deferred` 需读原因，`unknown` 必须先核对原提交。

已有客户端重启后，实例与会话缓存可能暂时属于不同进程代际。调度器收到同一原生会话、实例和工作区的新原生核验，并确认当前实例提交门已开放后，会在提交事务内刷新会话缓存。不会创建新会话或绕过关闭的门；确认刷新前也不会提交输入。检查时不要仅凭 `instance_stopping` 文案认定客户端正在退出，还要比对实例、门与会话的进程代际。

根据需要用 `message.context/history` 读取本地上下文；不要靠反复重放、平台历史轮询或换会话试发判断实时接线是否正常。

## 请求超时或结果未知

保留原操作名、幂等键与输入，调用 `operation.get`，再读取返回的 delivery/outbound。`not_found` 不足以证明从未执行；`unknown` 不换键重发，也不换目标或入口重做同一动作。只有已证未送达且可重试的对象才走相应 retry。

## @ 了但没有文字回复

通知成功不要求 AI 必须回复。接收对话按自己的规则决定是否处理、是否属于已有任务和何时调用 `message.reply`；DJ 不转发普通输出。使用信封的 `reply_context_id`，身份和原位置由 DJ 固定；不要改用 `message.send` 绕过缺失引用。平台接受回复和人已阅读是不同状态。

## 处理中表情没有消失

处理结束、无需回复或失败时，接收方应以原 delivery 调用 `delivery.complete`。查询清理状态，只有官方读回确认后才算清理完成；不要依赖 AI 最后一条自然语言回复来撤销表情。详见[处理中表情](../specs/0006-working-reactions.md)。

## 规则或回复格式奇怪

读取 `session.rules.get` 的 `text` 与 SHA256。保存正文和读取原文应一致；JSON 显示的转义不是正文丢失。不要对整段文本重复序列化，也不要自动把字面 `\n` 反转义。`conversation_rules.text` 是会话保存的规则，外层 `external_message` 是 DJ 组装的投递信封；后者不要求 AI 用 JSON/XML 作为最终回复。具体输出约定由原会话维护。

## Skill 安装冲突或工具不可见

`skill install --dry-run` 先检查目标目录；不同内容或链接冲突时保留原内容，不强制覆盖。`skill check` 只证明文件一致；MCP 配置、客户端实际加载及当前对话身份需要分别确认。参考[客户端接线](../../skills/dj/references/clients.md)。

## Cursor / Pi 的特殊情况

- Cursor native_api 只连接已核验的本机实例。客户端重启或升级后，旧 PID、出生信息、origin 和 workspace 不再作为当前事实；不要通过启动 Agent CLI 替代原目标。
- Pi 接收扩展必须实际加载在原 TUI 内；临时加载不代表重启后仍在。按[扩展说明](../../connectors/pi/README.md)处理。

## 私聊没有立即唤醒

原消息已命中订阅但投递为 `deferred / target_busy` 时，说明原助手仍在执行上一项任务。消息保持原序排队，不创建替身、不重复提交、不打断原任务。排队阶段没有 Typing；它只在原生接收后表示已交给助手。可通过 `task.list` / `task.tree` 或已配置身份的 IM 私聊 `/dj tasks` 检查等待原因；`accepted` 与业务完成仍需分开核对。
