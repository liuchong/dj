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

等待 DJ 排空自身尚未确认的传输和写入并释放租约；已有客户端已接收的业务继续由它运行，不等待模型完成、不重发已接收消息。不要强杀已有 AI 客户端，也不要在旧进程仍持有状态目录时拉起第二个 DJ。升级前备份私有配置和数据库，停止旧服务后切换目录包，再 bootstrap 并检查新 build_id。真实消息、规则、身份和幂等台账需要保留，不能当作编译临时文件删除。

没有配置 launchd 时，可前台运行 `dj serve --config PRIVATE_SERVICE`，使用 SIGTERM/SIGINT 请求停止。服务生成与系统安装是独立步骤，打包本身不会修改 launchd。

## 菜单栏控制器

控制器完全可选，不安装也不影响核心服务。开发打包时显式选择 `--with-controller` 才构建原生菜单栏宿主，默认目录包不需要此组件。使用含控制器的目录包，执行 `dj controller install`。它将 `DJ Control.app` 安装到系统 Applications 目录，并登记独立的 `dev.dispatch-junction.controller` 登录项；需要当前用户对系统 Applications 的写权限，不调用 sudo，不创建第二个 DJ，不改账号、订阅或对话规则。前提是原 DJ 服务登录项、私有 client.json 和当前 Bun 运行时已安装。

菜单栏使用原生绘制的 DJ 双唱盘交汇透明底模板，由 macOS 随主题自动着色，状态显示在菜单与悬停提示中；App 启动器继续使用彩色 Logo；打开面板可看服务状态，启动、停止或立即刷新，并可打开配置目录。运行中表示已通过原 UDS service.status 确认 ready；只有 PID 时会显示未就绪。停止使用 launchctl disable + bootout，防止 KeepAlive 或下次登录自动拉起；启动重新 enable 并装载原登录项。正在发送的工作仍遵守原存储恢复边界，不补投 unknown。

退出控制器只退出菜单栏和它自己的状态探测后端，DJ 服务继续运行。可以从 Dock 的 App 启动器、Finder 应用程序目录或 Spotlight 打开 DJ Control，显示菜单栏图标，点击该图标展开非模态控制面板，再次点击同一图标收起，也可用面板的“收起”或 Esc 关闭；App 图标同样来自项目 Logo。登录时也会自动打开。若不需要控制器登录自启，可移除它自己的登录项，不能因此删除 DJ 服务登录项。工具业务逻辑使用 Eliscript，原生 AppKit 宿主只投影菜单和管道事件。详细规格见 [0022](../specs/0022-service-controller.md)。

不再使用控制器时，可先退出它，再只移除控制器自己的登录项和 App：

```sh
launchctl bootout "gui/$(id -u)/dev.dispatch-junction.controller"
rm "$HOME/Library/LaunchAgents/dev.dispatch-junction.controller.plist"
```

随后将系统 Applications 中的 DJ Control.app 移到废纸篓；保留核心服务登录项和 `.dj` 数据。App 启动器的索引由 macOS 更新，不改写其数据库。
