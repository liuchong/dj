# Codex 原生工具宿主接收端

Codex 的 follower socket 可向原对话投递。创建、改名，以及 follower socket 缺失时的定点确认与投递，需要在 **已经运行的 Codex 原生 Node 工具宿主** 显式加载本包的 `control.mjs`，调用 `activateCodexControl`。这不是另一个 Agent、CLI、App Server 或第三方控制程序；接收端每次调用现有 App Tools 原生管道，平台仍检查真实签名与调用来源。普通终端进程被拒绝时不能伪造身份、改签名或关闭鉴权，也不要给没有 SIGUSR1 处理器的 App 发送该信号。

加载完整运行包中的 `connectors/codex/control.mjs` 或 `connectors/codex/mcp.mjs`。推荐的长期接线方式是将 Codex 的 `[mcp_servers.dj]` 配置为运行 `connectors/codex/launch-mcp.sh`（通过 App 自带签名 `cua_node` 启动 `mcp.mjs`）：该进程作为已运行 Codex App Server 的原生 stdio MCP 子进程运行，不受单轮会话 `exec_command` 卸载影响，同时向本地 DJ HTTP MCP 代理请求，并在进程内运行单锁控制接收端。

传入实际工具请求的 `request_meta` 和经本机进程元数据确认的 Codex App `owner_pid`、`owner_birth`。多实例时还要传准确 `pipe_path`。原生管道验证调用进程的签名和来源，普通外部终端或脱离原 App Server 的进程不能代替。不要把请求元数据、token 或完整 manifest 放进通知、业务规则或 Git。`mcp.mjs` 会在缺少静态请求元数据时按内存态与本地 `caller-context.json`、`<owner_pid>.json` 及 `~/.codex/state_5.sqlite` 候选线程自动发现有效调用会话；返回的 `manifest_path` 是供操作员合入原 Codex `agent_endpoints[].control_manifest_path` 的私有引用。

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

接收端公开 probe/read/send/create/lookup_create/rename。probe 经原生接口读回调用会话，验证当前宿主确有可用的调用权限。创建请求发出前记录 unknown，未知结果不重建。

长期保活可使用 `mcp.mjs` 嵌入接收端，或在原生工具宿主调用 `control.superviseCodexControl({ request_meta: nodeRepl.requestMeta })`：由当前宿主或程序化发现提供有效 `x-codex-turn-metadata`，并周期性通过原生 `read_thread` 校验证明调用权限。同一 Codex App PID 仅使用单把内核文件锁 `<owner_pid>.lock` 协调唯一主接收端（不再使用双锁主备槽位），其余竞争进程阻塞等待接管或随宿主退出。当所有接收端均因 App 长时间无加载会话而离线时，DJ 服务侧可通过 `dj-codex-loader` 安全唤醒已运行 App 中的既有线程恢复原生控制。

退出后新的授权宿主可原子发布同一 PID 的新登记，每次登记有独立 socket，旧文件和旧宿主关闭均不会覆盖新接收端。DJ 核对 PID、出生标识、socket 和原生会话后恢复原队列。没有活 follower 或授权宿主时，实例查询如实显示离线，已有会话仍可按 `offline: hold` 入队。升级或卸载时调用 `receiver.close()`，关闭并清理该登记的 socket。PID 对应的共享指针由下一次登记覆盖。
