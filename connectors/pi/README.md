# Pi 已有进程接收扩展

该入口由 Pi 原生 Extension API 加载，调用随包 Eliscript 实现；不启动 Pi/RPC 子进程，不发送终端按键，不切换会话或模型。扩展工厂只注册生命周期处理器；收到 session_start 后才在 Pi 自己的进程中创建私有 HTTP-over-Unix-socket 接口，session_shutdown 时清理自己创建的资源。

## 安装和使用

1. 使用当前 DJ 运行包，保持 connectors/pi/extension.mjs 与 dist/src/connectors/pi.mjs 的相对布局。需要 Pi 0.80.3 和 Node.js 22.19+；当前代码依据该版本原生 Extension API，其他版本需核对。
2. 在专用 Pi 工作区的 .pi/settings.json，或用户明确选择的 ~/.pi/agent/settings.json 中，将运行包的 connectors/pi/extension.mjs 实际路径追加到 extensions 数组。保留其他项，不复制凭据到设置文件。此步骤不由 DJ 自动执行。
3. 由使用者在已有 Pi 中按原生流程 reload；不为接入重开替代 CLI，不通过启动参数携带消息或会话。Pi 显示 DJ receiver 的私有 manifest 路径；也可由可信操作员在 ~/.dj/pi-receivers 中查看文件名。
4. 在 DJ 私有 agent_endpoints 配置已有端点：tool=pi、ownership=existing、instance_id/endpoint_ref 为操作员分配标签、native_namespace=pi-local、manifest_path 为该 manifest、directory 必须等于 Pi 当前 cwd、workspace_ref 为固定工作区标签。不要读取或转发 manifest 内的 token 给模型。
5. DJ 通过 session.resolve/probe 或 agent.discover(scope=live) 核对当前原生 session ID，再直发或登记订阅。单个 manifest 只代表一个当前已有会话，不是 Pi 的全部历史目录。Agent 仍须使用独立 recipient profile 调用 DJ 的 CLI/MCP/GEPO；扩展不会代它回复 IM。

最小端点形状：

```json
{
  "tool": "pi",
  "ownership": "existing",
  "instance_id": "pi-dj-local",
  "native_namespace": "pi-local",
  "endpoint_ref": "pi-dj-local",
  "manifest_path": "pi-receivers/ACTUAL-MANIFEST.json",
  "directory": "workspaces/ACTUAL-WORKSPACE",
  "workspace_ref": "pi-dj-workspace"
}
```

相对路径以 DJ 私有配置根为准，directory 需替换成当前 Pi 的真实工作区；配置中的占位值不能直接使用。每个接收会话独立 recipient 与 target_constraint，不能复用 operator token。

## 边界

- socket 所在目录为当前用户私有 0700，socket/manifest 为 0600；每次会话生命周期使用独立 token/epoch，接口只提供 probe/messages/submit，拒绝 Origin、目标漂移和非空闲提交。
- 每次 submit 通过原生 sendUserMessage 进入当前会话；accepted 表示接收 API 接受，不表示模型完成或 IM 已回复。网络/原生调用结果不明时保持 unknown，不自动重发。
- 消息只读取当前分支的有界近期原生条目，最多 128 项/512KiB，coverage 明确 partial；使用原生条目 ID，不编造完整历史或合成原生 ID。
- 不提供创建会话、启动/停止用户进程、修改模型、工具授权或审批接口。正常消息经过原 Pi 工具策略，扩展不增加其权限。
- reload、切换会话或进程结束后，旧 manifest/epoch 不能继续使用。DJ 不自动改绑；操作员重新核对端点和原会话，保留未知投递的屏障。
- 代码/本地组合验证不代表已经安装进当前 Pi 或完成真实模型/IM 验收；没有接收端时先交付实现和说明，不等待或启动替代进程。
