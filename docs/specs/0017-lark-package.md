# 0017 独立 Lark 包与 DJ 原生 API 接线

## 目标与边界

把Lark官方基础能力抽成独立Eliscript包；DJ的Lark IM层只组织连接身份、消息语义及m×n订阅分发。通用入口覆盖官方各业务域的方法、路径、JSON、multipart上传及二进制下载，不再以“没有专用DJ命令”判定能力缺失。不维护另一套第三方SDK或CLI请求栈。

这不是对数千原生端点逐一封装、逐一实机验收的声明。原生权限与身份支持、接口受理、业务效果和DJ集成测试是不同证据；缺权限须返回平台原始错误，不捏造支持或验收范围。

## 分层

| 层 | 文件／入口 | 责任 |
| --- | --- | --- |
| 官方协议包 | `packages/lark/src/{http,client,wire,index}.eli` | 官方域名、身份凭据、传输和有界编解码，无DJ依赖 |
| Lark IM适配器 | `src/adapters/im/lark-http.eli`、`lark.eli`、`lark-events.eli` | 消息映射、应用级表情预算、事件连接、历史与HTTP补收 |
| 多账号路由 | `src/connections/manager.eli` | 单一扁平注册表选择准确连接；user/bot独立实例、同一实现 |
| DJ API业务 | `src/lark/service.eli` | 当前连接身份复核、原生API参数、写台账与结果查询 |
| 统一接口 | operations/results/help、CLI/MCP/GEPO、DJ Skill | 同目录、同schema和同一业务实现，不逐协议复制 |

已有HTTP能力改为调用独立包；WebSocket帧实现移动到包内，不留旧副本。事件订阅及持久化留在IM层，不把DJ数据库、过滤器或AI决策塞进SDK。

## 统一操作

- `lark.api.read`：GET，明确connection_id、identity_revision及/open-apis/相对path，可传原生query、安全headers、response_mode。
- `lark.api.call`：POST/PUT/PATCH/DELETE；明确同样连接字段和idempotency_key，body或form二选一。form文件包含base64、filename及可选content_type。
- `lark.api.get`：按action_id读取原调用台账，亦可用operation.get按原幂等键读取。

API响应保留http_status、native_ok、response及日志/限流等安全响应头；原生code、msg、permission_violations原样位于response。bytes模式response为base64。DJ响应上限512KiB，输入受统一请求大小限制；独立包可接收Blob/File及更大显式预算。分页按原生端点字段显式请求，不隐式遍历全部来源。

通用入口的连接级原生能力以该账号平台实际权限为边界，IM watches与订阅是收件/触发范围，不是办公API资源授权。普通消息及原话题回复优先高级message/resource接口，保持固定回复身份/位置、回声防重和出站台账；原生API调用不会自动登记订阅、DJ outbound或结束Working。OAuth/令牌接口仅由连接内部使用，不向AI暴露凭据管理入口。

## 写入与生命周期

首次写调用先在operations持久登记unknown，随后才请求平台。明确成功为accepted，原生拒绝为rejected，传输/5xx不确定结果保持unknown；同键不会再次执行原生请求，不盲目重试或切账号。accepted只证明平台受理，不证明最终文档、审批或任务业务完成。close取消本连接HTTP；停机与身份变动仍由现有所有权、身份栅栏及统一写批次保护。

## 验收与交付

先完整业务实现，再集中集成功能验收，最后补关键保护测试。测试使用本机隔离原生HTTP服务与真实SQLite Core，验证包、身份、通用接口和持久台账组合；不向真实群发测试消息，不重跑全部工具/性能矩阵。常用消息与资源路径复用定向现有回归。服务安装后仅进行安全只读原生API检查，明确与模拟端点证据的差别。

- [x] 独立包、IM接线与统一操作实现
- [x] 集成验收和关键保护测试通过
- [x] 已安装服务与Skill更新

当前集中验收：最终构建的42项定向功能/契约检查通过，另有表情收件与轮询定向回归通过。原生本机HTTP＋SQLite验证上传下载、账号隔离及未知写结果重启防重；已安装服务的user、bot两条连接均经通用入口读取官方群列表，获得HTTP 200与code=0。Skill安装副本已核对，现有接收对话已确认读回新入口。没有对所有官方端点逐项实机验收。

## 官方依据

核对日期：2026-10-30。使用官方服务端OpenAPI资料；路径中的v1/v2等是上游协议要求，不是DJ多版本实现。

- [官方服务端API目录](https://open.larksuite.com/document)
- [飞书服务端API目录](https://open.feishu.cn/document)
- [上传文件](https://open.larksuite.com/document/server-docs/im-v1/file/create)
- [通用错误码](https://open.feishu.cn/document/server-docs/api-call-guide/generic-error-code)
