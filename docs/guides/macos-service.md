# macOS 常驻服务

DJ 可以作为用户级 launchd 服务持续运行。它使用当前用户的私有配置，不注册系统级 daemon，也不自动安装或启动 AI 客户端。

## 前提

- macOS arm64；已准备好目录包和 Bun 1.4.4。
- 已按[安装指南](../delivery.md)完成受保护的服务、客户端和凭据配置。
- 下列命令假定 `dj` 已在 PATH。服务必须使用明确的 Bun 和目录包路径，不能依赖交互 shell 的 PATH。

## 配置

1. 将目录包移到持久位置，例如 `~/.dj/releases/RELEASE`；可用 `~/.dj/current` 指向当前目录。`RELEASE` 是实际目录名。
2. 创建 `~/.dj/run`、`state`、`logs`、`secrets` 等配置需要的目录，权限 0700；配置与凭据权限 0600。
3. 复制包内 `packaging/launchd.example.plist` 到 `~/Library/LaunchAgents/dev.dispatch-junction.local.plist`。
4. 编辑 plist，替换所有 `REPLACE_WITH_*` 占位值。Bun 可执行文件、目录包入口和 `service.json` 必须是真实的绝对路径；不要在 plist 字符串里写 `~` 或 `$HOME`，launchd 不执行 shell 展开。

| 配置 | 说明 |
| --- | --- |
| `Label` | `dev.dispatch-junction.local` |
| `ProgramArguments` | Bun、包内 `dist/src/service/main.mjs`、`--config`、私有 `service.json` |
| `RunAtLoad` / `KeepAlive` | 示例默认关闭；确认要持续运行时显式设为 `true` |
| `WorkingDirectory` | 私有根目录；如配置使用相对路径，仍按配置文件所在目录解析 |
| `StandardOutPath` / `StandardErrorPath` | 可设到私有 `logs` 目录；不要将凭据和原始消息写入诊断日志 |

不要复制其他机器的 PID、工作区、原生 endpoint 或凭据。保持 `managed_profiles` 为空，AI 工具接入使用已有进程接口。

## 启动与检查

在终端中执行：

```sh
launchctl bootstrap "gui/$(id -u)" "$HOME/Library/LaunchAgents/dev.dispatch-junction.local.plist"
launchctl print "gui/$(id -u)/dev.dispatch-junction.local"
dj status --json
```

`launchctl` 中看到进程不等于业务就绪。确认 DJ 返回 `ready`，再核对相应连接和 Agent receiver。

## 停止与升级

```sh
launchctl bootout "gui/$(id -u)/dev.dispatch-junction.local"
```

等待 DJ 排空已提交工作并释放租约。不要强杀已有 AI 客户端，也不要在旧进程仍持有状态目录时拉起第二个 DJ。升级前备份私有配置和数据库，停止旧服务后切换目录包，再 bootstrap 并检查新 build_id。真实消息、规则、身份和幂等台账需要保留，不能当作编译临时文件删除。

没有配置 launchd 时，可前台运行 `dj serve --config PRIVATE_SERVICE`，使用 SIGTERM/SIGINT 请求停止。服务生成与系统安装是独立步骤，打包本身不会修改 launchd。
