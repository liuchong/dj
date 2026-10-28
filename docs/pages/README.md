# DJ Pages

入口是 `docs/index.html`；页面的 Eliscript 源码、CSS、SVG Logo 与漫画均在本目录。

## 本地预览

在仓库根运行：

```sh
python3 -m http.server 8787 --bind 127.0.0.1
```

打开 `http://127.0.0.1:8787/docs/`。结束后 Ctrl-C 停止服务。不要直接双击 HTML 文件打开，因为浏览器需要通过 HTTP 加载 Eliscript 源文件。

`index.html` 通过明确固定的 `eliscript@0.1.0` 浏览器 SDK 加载 `site.eli`，现场编译并执行。小段原生模块脚本仅用于启动 SDK 与报告加载失败；场景切换、键盘导航、示例复制、动效控制均在 Eliscript 中实现。编译得到的 JavaScript 只存在于浏览器内存，不生成或提交 JS 文件，不需要离线构建。SDK 从 jsDelivr 加载，首次交互需要联网；加载失败或脚本禁用时，正文、默认示意及文档链接仍可阅读。

## 内容与资源

- `site.eli`：纯本地的订阅路由演示和页面交互，不连接 DJ、IM 或 AI 实例，不收集账号与消息。
- `site.css`：响应式版式与动效；支持 `prefers-reduced-motion` 和手动暂停。
- `assets/dj-mark.svg`：README 与站点使用的双唱盘、交叉通道与分流箭头 Logo；`assets/dj-logo.svg`：横幅视觉；`assets/social-card.svg`：分享预览。
- `assets/dj-carnival.png`：采用旧路边摊磁带封面的泛粉柔焦、粗网点、套色偏移与褪色纸张质感；保留豹纹外套与金色吊带装束的漫画 DJ、碟机、机器人与观众；DJ 面朝机器人欢呼，与观众组成群像，以上方小镜面球、局部反光与小音箱保留舞厅气氛，背景适当留白。人物台词由 HTML 排版，保持可读、可选择。

所有站点资源使用相对路径，支持 GitHub Pages 的项目子路径；已有 Markdown 技术资料链接到仓库原文。将 GitHub Pages 发布来源设为本分支的 `docs` 后可直接使用入口；本次源码提交不代表已启用或完成远程 Pages 发布。

## 许可证

站点源码、Logo、漫画与文档随项目使用 [1PL](../../LICENSE)。浏览器加载的 Eliscript SDK 依其自己的许可证分发。
