# AI 收到的通知为何不再是一行 JSON

原先 DJ 将完整信封 JSON.stringify 后作为原生会话的 text。API 能正确传输，但人和 AI 看到的文字是一大串 JSON，规则中的真实换行显示为反斜杠 n。

现在原生会话的 text 使用 MDP 元数据及 Markdown 原文块。notification 中列出投递、消息来源、回复引用和允许动作，content.text 指向 body_1；对应原文块直接显示收到的文字。instructions、持久规则和引用上下文也按同一方式展示。用户原文如果本就写了字面的反斜杠 n，DJ 不擅自解码它。

原文不会被转为新指令，不影响既有规则优先级。DJ 不替接收者改写持久规则，也不把通知布局、XML 或 JSON 规定为最终回答模板。回复仍需 AI 明确调用原回复接口，普通最终输出不会发到 IM。

各 AI 工具的原生 API 仍有自己的 JSON 外壳；这与会话里实际读到的文本不同。DJ 的 CLI/MCP/GEPO 返回和压缩审计快照保持结构化原对象。展示稿不用于反解审计内容。

详见 [0011 规格](../specs/0011-readable-notifications.md) 与 [通知元数据 MDS](../specs/0011-notification.schema.mdp)。
