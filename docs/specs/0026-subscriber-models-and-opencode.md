# 0026 — 订阅者模型信息与 OpenCode 原生接入

## 订阅者元数据

所有工具共用同一份 `subscriber` 结构：准确 session_key、tool、surface、native_namespace、native_session_id、instance_id、instance_epoch、workspace_ref 及 model_selection。tool 是工具适配器，不是模型供应商。模型选择包含 provider_id、完整 model_id、variant、reasoning_effort、status、source、observed_at；未暴露的字段为 null，status 为 unknown。不通过品牌名、默认配置或模型目录推断对话当前选择。

原生会话观察优先；订阅者可在 subscription.preview 的 spec.subscriber_model 提供自己的 provider_id/model_id 与可选 variant/reasoning_effort。该信息经正式 preview/create/update 持久保存，并标为 subscriber_report，不能冒充原生已核实值。保存与回传不包含密钥、URL、密码或完整原生配置。一次订阅不会修改固定搭档的模型。

会话目录持久保存最新原生观察，订阅记录保存提交时 subscriber 快照。agent 查询返回准确会话的 subscriber；每次推送或拉取开场通知通过 recipient 返回会话和模型参考。推送使用本次提交前 probe 的原生模型；无法核实时明确 unknown，不能把旧值当当前值。订阅者报告按原实例 epoch 保存，报告时间不刷新成当前时间；报告及过期观察带 stale=true。实例更换后不能沿用旧实例的报告。模型信息仅供分派选择参考，不构成创建、切换模型或扩大权限的授权。

## OpenCode

只实现当前官方 `/api/*`：info、location、project、session、active、message、inbox、prompt、model。旧路径返回 HTML 也必须拒绝，不保留旧协议或托管启动回退。

配置的 service_file 指向 OpenCode 原生私有登记文件；每次重新读取并验证同用户、PID、loopback listener 与 /api/info 的 PID/版本，密码只在内存使用。静态 base_url/credential_ref 可用于明确配置的接口；生产优先原生 service_file，以接续服务重启后的端口和凭据。目录、projectID 与准确会话 ID 一并核对。

桌面端可配置 desktop_registry_path、window_id、server_key，对接已经安装的本机桌面控制入口。先从原生窗口和服务器列表选择唯一目标，再执行创建或注册；后端历史不冒充桌面已打开。无桌面入口时只声明后台会话能力，不假造桌面证明。不使用 UI 点击、Inspector 或启动参数投递。

创建先解析原生 location，按需核验明确指定的 model_selection（供应商、完整模型 ID 和 variant），再创建空会话。桌面创建经原生 host API 注册 Tab；部分成功保留原 ID，不自动再创建。发送保留原会话模型，用 prompt 的 text/delivery 和确定性 id；既有忙时输入走 steer，不中断工具。持久 inbox 接受不等于模型完成；未知结果先查询 inbox/历史确认，未找到不自动重发。消息及会话列表使用正式 cursor.next，缺省 next 是末页，不使用旧 header/before 游标。

## 验收边界

本阶段先完整业务实现，再定向集成功能验收，最后关键保护测试。验证订阅→正式 SQLite 持久记录→推送/拉取 recipient→分派参考，以及当前 OpenCode 已有服务发现、准确桌面会话、创建和连续收发。保留现有业务订阅、规则与退订；只使用独立调试会话和订阅，结束后收回测试资源，不改现有搭档模型。

官方协议依据：[服务发现](https://github.com/anomalyco/opencode/blob/v2.3.0/packages/client/src/service-probe.ts)、[会话协议](https://github.com/anomalyco/opencode/blob/v2.3.0/packages/protocol/src/groups/session.ts)、[消息分页](https://github.com/anomalyco/opencode/blob/v2.3.0/packages/protocol/src/groups/message.ts)。版本为本次核验基准，不是 DJ 的多协议开关。

本批定向集成回归通过（34 项及 3 项既有 todo），保护回归通过（36 项及 3 项既有 todo）；不重复全套或性能验收。真实 OpenCode 后台服务在核验期间由 2.2.7 更新为 2.3.0；两处 CLI 与 /api/info 均确认 2.3.0。原调试桌面对话跨后台服务更换后仍完成订阅、SQLite 持久记录、通知 recipient 模型回传和实际模型回应；原生桌面 renderer 同一 ID 读回确认。真实用例为 tests/integration/opencode-live.test.eli，必须显式提供 DJ_OPENCODE_ENDPOINT_FILE；可通过 DJ_OPENCODE_TEST_SESSION 复用准确既有调试对话，不启动 Agent 进程。
