# macOS 服务控制器

- optional: 控制器完全可选；默认目录包不带原生宿主，显式 --with-controller 打包后可独立安装。它的存在与退出不改变核心服务的安装或运行方式。当前只实现 macOS；公共状态模型与平台适配分层，Windows/Linux 后续单独接入。
- install: 先安装 DJ 用户级服务和私有 client.json，再用目录包的 dj controller install；使用当前 Bun，不下载依赖或启动 AI。安装到系统 Applications/DJ Control.app，登录项 dev.dispatch-junction.controller；不得覆盖不同归属的同名 App。
- launch: 可从 Dock 的 App 启动器、Finder 应用程序目录或 Spotlight 打开 DJ Control；菜单栏使用项目Logo的透明单色系统模板，App入口保留彩色Logo。打开App只显示状态图标，点击图标展开原生控制面板，再次点击收起；也可使用收起按钮或Esc，面板不会因失焦自动关闭；重复打开不创建多个后端。
- status: 每3秒及打开菜单时刷新；运行中必须有 service.status 的 ready 证据。进程存在、认证失败、未安装和启动/停止过渡分别显示，不能把异常当作已停止。
- start_stop: 启动恢复原 DJ launchd 登录项；停止禁用并卸载它，避免 KeepAlive 立刻重启。只操作当前用户 dev.dispatch-junction.local，不访问或修补业务数据库，不重发 unknown。
- quit: 退出菜单栏控制器不停止 DJ；再次打开 App 或下次登录恢复菜单。控制器自身的登录项与 DJ 服务分离。
- boundary: 菜单控制属于本机管理员操作，不是新的 MCP 业务权限，不以控制器绕过 IM 平台权限或 AI 原会话身份边界。
