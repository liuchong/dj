# Codex 原生工具宿主接收端

Codex 的 follower socket 可向原对话投递。创建、改名，以及 follower socket 缺失时的定点确认与投递，需要在 **已经运行的 Codex 原生 Node 工具宿主** 显式加载本包的 `control.mjs`，调用 `activateCodexControl`。这不是另一个 Agent、CLI、App Server 或第三方控制程序；接收端每次调用现有 App Tools 原生管道，平台仍检查真实签名与调用来源。普通终端进程被拒绝时不能伪造身份、改签名或关闭鉴权，也不要给没有 SIGUSR1 处理器的 App 发送该信号。

加载完整运行包中的 `connectors/codex/control.mjs` 或 `connectors/codex/mcp.mjs`。推荐的长期接线方式是将 Codex 的 `[mcp_servers.dj]` 配置为运行 `connectors/codex/launch-mcp.sh`（通过 App 自带签名 `cua_node` 启动 `mcp.mjs`）：该进程作为已运行 Codex App Server 的原生 stdio MCP 子进程运行，不受单轮会话 `exec_command` 卸载影响，同时向本地 DJ HTTP MCP 代理请求，并在进程内运行单锁控制接收端。

## 安装与配置（推荐）

1. **DJ 服务配置（`~/.dj/service.json`）**：
   - 在 `service` 启用 `mcp_http_port`（如 `53270`，仅绑定 `127.0.0.1`）。
   - 在 Codex 的 `agent_endpoints[]` 中配置：
     - `history_database`：指向同一用户的 `~/.codex/state_5.sqlite`。
     - `control_manifest_path`：指向私密接收端目录的 `<pid>.json` 引用（运行中 `mcp.mjs` 会按真实桌面主进程 PID 原子发布 `<owner_pid>.json`）。
     - `receiver_loader_ref`：指向包内 `libexec/dj-codex-loader`（支持冷启动及全闲置卸载后的安全唤醒）。
     - `process_helper_ref`：指向包内 `libexec/dj-process-info`。
2. **准备 `0600` Bearer token 文件**：
   - 在 `0700` 私密目录（如 `~/.dj/secrets`）写入单行普通调用身份的 Bearer token 纯文本，设置权限 `0600`（如 `~/.dj/secrets/mcp-codex.token`）；不要把 token 写入日志、Skill、仓库或提示词。
3. **生成并合并 Codex 客户端 `[mcp_servers.dj]` 配置**：
   - 运行：
     ```sh
     dj skill config --target codex --client-profile PRIVATE_PROFILE --mcp-url http://127.0.0.1:PORT/mcp
     ```
   - 将返回的 `[mcp_servers.dj]` TOML 片段合并到 `~/.codex/config.toml`（替换旧直连 `url` 与 `http_headers` 写法），把 `--token-file` 占位符改为上一步创建的 `0600` 文件真实路径：
     ```toml
     [mcp_servers.dj]
     command = "<DJ_CURRENT>/connectors/codex/launch-mcp.sh"
     args = ["--url", "http://127.0.0.1:PORT/mcp", "--token-file", "~/.dj/secrets/mcp-codex.token"]
     env_vars = ["CODEX_APP_TOOLS_PIPE_PATH", "CODEX_MCP_NODE_PATH", "CODEX_HOME"]
     ```
4. **生命周期、单锁切换与生效边界**：
   - **单锁协调**：同一 Codex 主进程 PID 仅使用单把 `<owner_pid>.lock`（无 `.standby.lock` / `receiver_standby_full`）；若 `codex app-server` 启动多个会话级 `mcp.mjs`，只有持锁进程对外提供控制 socket，其余阻塞候补或随其所属宿主退出。
   - **自动调用线程发现**：`mcp.mjs` 在缺少静态请求元数据时按内存 `_meta["x-codex-turn-metadata"]`、`caller-context.json`、`<owner_pid>.json` 与 `~/.codex/state_5.sqlite`（非归档最新线程）候选顺序经 `read_thread` 实测确认可用调用线程。
   - **冷线程轮换唤醒与捕获**：当所有已加载会话长时间闲置卸载后，DJ 在 `probeWith` 投递路径由 `dj-codex-loader` 轮换唤醒未归档冷线程并在 `mcpServerStatus/list` 拉起窗口内同步捕获 `mcp.mjs`，紧随提交正文触发 `turn_input` 重建持久驻留，无需手工在对话中运行后台脚本。
   - **老会话缓存说明**：修改 `~/.codex/config.toml` *之前*已经运行过的旧对话仍沿用当时缓存在 `codex app-server` 内的旧 MCP 客户端池；新建会话、触发冷线程，或待旧会话闲置卸载/重启桌面客户端后即切至新代理。

## 短时手工诊断（`control.mjs`）

以下仅用于在已运行原生 Node 工具宿主内执行短时手工诊断，不建议再作为长期保活方案；传入实际工具请求的 `request_meta` 和经本机进程元数据确认的 Codex App `owner_pid`、`owner_birth`。多实例时还要传准确 `pipe_path`。原生管道验证调用进程的签名和来源，普通外部终端或脱离原 App Server 的进程不能代替。不要把请求元数据、token 或完整 manifest 放进通知、业务规则或 Git。`mcp.mjs` 与 `control.mjs` 返回的 `manifest_path` 是供操作员合入原 Codex `agent_endpoints[].control_manifest_path` 的私有引用。

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
