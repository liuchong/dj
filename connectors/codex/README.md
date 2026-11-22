# Codex 原生工具宿主接收端

Codex 的 follower socket 可向原对话投递。创建、改名，以及 follower socket 缺失时的定点确认与投递，需要在 **已经运行的 Codex 原生 Node 工具宿主** 显式加载本包的 `control.mjs`，调用 `activateCodexControl`。这不是另一个 Agent、CLI、App Server 或第三方控制程序；接收端每次调用现有 App Tools 原生管道，平台仍检查真实签名与调用来源。普通终端进程被拒绝时不能伪造身份、改签名或关闭鉴权，也不要给没有 SIGUSR1 处理器的 App 发送该信号。

在宿主的 Node 工具中加载完整运行包 `connectors/codex/control.mjs`（Node 工具要求时先添加正式包的 node_modules 目录）。传入原工具本次 `request_meta` 和经本机进程元数据确认的 Codex App `owner_pid`、`owner_birth`；多实例时额外传入精确 `pipe_path`。不要把 request_meta、token 或完整 manifest 放进通知、业务规则或 Git。返回的 `manifest_path` 是供操作员合入原 Codex `agent_endpoints[].control_manifest_path` 的私有引用。

```javascript
const { pathToFileURL } = await import('node:url');
const control = await import(pathToFileURL(`${packageRoot}/connectors/codex/control.mjs`).href);
const receiver = await control.activateCodexControl({
  request_meta: nodeRepl.requestMeta,
  owner_pid: 实际已核实的Codex主进程PID,
  owner_birth: 本机进程助手返回的出生标识
});
nodeRepl.write({manifest_path: receiver.manifest_path});
```

以上为原生宿主加载示例，不是仓库手写 JS 实现；业务与打包源都为 Eliscript。创建仅接受调用方明确给出的首条 `content`，工作区必须是该原生客户端实际列出的本地项目目录；没有首条消息时返回 `native_creation_requires_content`，不捏造占位任务。创建与首条输入由原生接口一起受理，生命周期的 `initial_input_state=native_queued` 和 `initial_input_receipt_key` 表示原生受理，不另建重复投递；随后通过准确新会话读回输入与状态。创建不登记 Agent、不建立订阅，不运行隐藏子智能体。

接收端公开 probe/read/send/create/lookup_create/rename；鉴权、帧大小、超时、原生 ID 和私有 socket/manifest 都受限。最多保留 128 个创建键；请求发出前保留 unknown，未知结果不重建。宿主退出、原生管道失效或进程改变时能力不可用，既有通知 socket 保持独立。升级或卸载时先调用返回的 `receiver.close()`；仅删除本接收端自己拥有的 inode。Codex 主进程重启后，由当前获准的原生工具宿主重新注册。DJ 从已配置接收端所在的私有目录按当前主进程寻找新登记，校验 PID、出生标识与 socket 后接手原队列，无需更新旧 PID 文件路径。当前 App 未暴露 follower socket 且尚未注册时，DJ 保留队列并报告接收端不可用。
