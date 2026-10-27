# Cursor 的受限创建连接器

该扩展运行在已有 Cursor Desktop 的扩展宿主中。它只通过固定原生命令 `composer.createNew` 请求创建空对话；不提供任意命令、进程启动、prompt、模型设置、授权修改、注册或订阅接口。具体命令参数为当前原生实现的版本相关接口；失败或未被原生 Bridge 读回时不得报告创建成功。

默认关闭。仅在专用工作区中显式设置 `dj.cursorControl.enabled=true` 和非空 `dj.cursorControl.workspaceRef`。仅在已信任的本地工作区启用；每次调用前重检信任、enabled、workspaceRef与目录。只接受当前单一工作区；多根工作区拒绝启用，不选择默认目录。配置变化须重新加载扩展。未设置时不建立监听或写台账。

连接器在 `~/.dj/cursor-control` 写入0600 manifest及有界创建台账，socket位于私有run目录。manifest的路径作为该Cursor endpoint的 `control_manifest_path`，同时配置精确 `directory`、`workspace_ref`、`window_id` 和原生 `manifest_path`。控制连接器与原生Bridge都必须是同用户的活接收端；凭据只在私有manifest中，不通过argv传递。

请求仅支持 `createSession` 与只读 `lookupSession`，绑定workspace_ref及creation_key。每个创建键派生固定原生ID，调用命令前先持久化issued；重放、超时或重启后均不再次调用命令。台账最多128项，不自动逐出旧键；单次最多一个原生命令在途。需要清理时先确认对应动作终态，不能删除不确定记录来重试。

DJ仍执行session.create的主体授权、工作区白名单、实例epoch和幂等检查。命令返回只代表调用结束；只有原生Bridge在同一实例epoch和window_id下列出相同ID，DJ才记ready。只有连接器台账而无原生会话时保持unknown，reconcile只读核对，不重建。创建不自动发送首条输入。

构建主程序后运行 `bun dist-tools/tools/package-cursor.mjs` 生成独立VSIX连接包及摘要。打包不会安装扩展、修改客户端、开启连接器或创建会话；安装和专用工作区配置须另获明确授权。该连接器仅处理原生创建缺口，不替代已有Bridge的消息投递与状态读取。
