# 真实验收控制器与资源准备

本页是S3真实验收的装配资料，不新增运行通过清单。施工与验收状态仍只维护在[TODO](../../TODO.md)，当前结果见[status](../status.md)。本页按现有测试源码整理；没有启动真实IM、模型工作、Agent进程或服务部署。

## 当前可证事实

- [real.eli](../../tests/support/real.eli) 已实现受保护profile、明确授权、控制器入口归属/摘要、请求关联、输出限额与有限期子进程回收；不是控制器本身。
- [acceptance.example.json](../../config/acceptance.example.json) 中9个driver仍指向缺失的`controllers/authorized-controller.mjs`，6个已有源码入口（资源采样1、OpenCode专用empty 1、双工具direct/native-start 2、Lark刺激/回复观察2），仍须保护装配与真实证据。measure-owned-deployment完成本地固定根采样基础，但仍有下述真实拓扑缺口；15项全部默认未授权、摘要为零，尚未安装或真实绑定。缺口不只是凭据或chat ID。
- Lark user OAuth验证不等于专用chat/thread、另一IM或原生Agent目标已经获准。受控协议集成通过也不证明真实厂商唤醒、Skill采用或原话题回复。
- 真实profile依赖独立观察器、DJ服务及受限client profile。尚未组装这些资源，不将未运行登记为通过。

## 现有控制器协议

调用者固定为`approvedDriver(f,name,payload)`，实现以[real.eli](../../tests/support/real.eli)为准：

1. 在本次显式授权profile中定位drivers[name]，检查`authorized=true`、`kind=test-controller`及`safe_to_terminate=true`。
2. 入口须位于profile根内、非符号链接、当前用户拥有且无组/其他用户访问权限；文件SHA256须等于entry_sha256。argv[0]须为当前测试Bun，argv[1]须精确对应入口。
3. 子进程cwd为profile根，stdin为单个JSON请求：`schema_version=1`、`request_id`、`operation`、`run_id`、`parameters`。这些关联标识由调用者产生。
4. stdout为单个JSON响应，成功时返回相同schema_version/request_id/operation/run_id、`ok=true`及data；不能把另一请求、旧运行或固定模板结果当作本次观测。
5. stdout一般限1MiB，只有measure-owned-deployment限8MiB（最多32进程/602实际采样点），stderr保留至32KiB，子进程120秒截止并在finally等待退出；只允许回收本次自有控制/观察进程。原生工具不是可随意终止的controller子进程。

控制器实现须继续使用Eliscript，部署入口可以是编译产生的ESM；不能以手写固定输出脚本替代。打包、复制到受保护profile根、计算真实摘要及装配argv仍属待完成工作，不能把当前占位引用直接改成已授权。

## 15个操作与原始证明来源

具体parameters及data字段由下面的现有测试调用和断言定义；控制器必须实际执行或观察对应平台动作，不能仅返回这些字段。

| 操作 | 所需动作 / 观察 | 当前消费者 |
| --- | --- | --- |
| busy-target / release-target | 在精确授权的目标上制造并解除本次可识别工作；随后DJ probe须读到真实busy/idle变化；不能影响其他会话 | realRelay及control中的managed drain场景 |
| stimulus-lark / stimulus-telegram | 从授权源账户向精确chat/topic发送本次关联消息，返回真实native_message_id | realRelay四组合及busy变体 |
| observe-reply-lark / observe-reply-telegram | 按真实native_message_ids从原平台读回，核对原chat/thread及reply_to_message_id | realRelay |
| observe-native-start | 从对应工具的原生观察来源核对原会话、observed_delivery_id与native_event_id，区别于DJ自己的accepted台账 | realRelay |
| observe-empty-opencode | 在原运行实例观察新会话确实存在、为空且没有隐式prompt | control T51 |
| observe-direct-input | 原生目标实际收到免订阅直发输入，核对delivery与原生会话关联 | control T49 |
| stop-dj-with-active-target | 对本次明确允许停止的服务验证draining、管道存活与未强杀Agent；不自动停止其他服务 | control T68 |
| observe-skill-adoption | 工具实际发现/读取Skill与参考，并产生可关联的preview/create原生工具调用；另以agent.get交叉核对 | skill T23 |
| observe-reply-key-recovery | 核对回复幂等键恢复行为及真实出站关联，不能只观察一次成功返回 | skill T44.skill-reply |
| create-and-wire-recipient | 真实创建/接线独立recipient，再由DJ查询身份、权限与新目标；不复制创建者权限 | skill T67 |
| run-without-reply | 真实运行但未执行显式回复时，保留ended与reply事实的区别 | skill T44.no-explicit-reply |
| measure-owned-deployment | 对本次自有standalone部署采集60秒/100ms周期的实际进程资源轨迹，交由summarizeResources判定 | performance T27.deployment-resources |

调用及断言入口：[realRelay](../../tests/support/real.eli)、[control](../../tests/e2e/control.test.eli)、[skill](../../tests/e2e/skill.test.eli)、[物理资源用例](../../tests/performance/router.test.eli)。跨工具独立观察源需要随实际受控实例核对；在来源尚未确定时，不用DJ同库字段或合成事件填补native证据。

## IM刺激与独立观察的额外装配事实

`stimulus-telegram`的发送身份、DJ收件bot和独立观察身份须分别绑定，不能把任意第二个bot发送成功当成DJ必能收件。2026-10-25查阅的[Telegram Bot-to-Bot官方说明](https://core.telegram.org/api/bots/bot-to-bot)已提供有条件的bot互通：同群/超级群中，指向接收bot的命令mention或对其消息的直接回复要求至少一方启用Bot-to-Bot模式；普通bot群消息的接收还要求接收方启用该模式、为群管理员并关闭Group Privacy。私聊则双方均须启用。不能沿用旧FAQ中的无条件“不接收其他bot消息”，也不能反向宣称任意bot均可互通。实际版本、开关、目标/topic和本次相关消息须在授权资源上验证；本页没有修改BotFather设置或发消息。

若使用用户身份制造Telegram刺激，应提供该专用测试账户的已授权原生入口；若使用第二个bot，应明确其角色和上述可接收条件。`observe-reply-telegram`须有可关联原chat/topic、回复目标与native message ID的独立平台事实。不得另开与DJ竞争的`getUpdates`消费器，不通过转发/复制消息等写操作伪装只读观察，也不把DJ自身outbox/发送返回值改名为独立原生证明。Lark刺激继续遵守明确的user身份、chat/topic及现有CLI入口，不因收到应用凭据扩大消息权限。

## 原生观察入口的具体约束

OpenCode端点、凭据来源和专用session须分别绑定。已发现本机loopback listener不等于已授权测试会话，未带凭据的health返回401也不等于服务离线；不能降级绕过认证。已有明确endpoint与受保护凭据文件时直接走HTTP；若需要通过临时debugger发现现有桌面sidecar凭据，须另外取得当前授权，不能由测试controller自动启用。没有连接参数时只保留资源缺口，不自动创建另一实例冒充原目标。

Pi的原生RPC管道由DJ的适配器唯一读取与分发。`createPiChannel`持有pending响应和事件队列，`recordEvents`调用`drainEvents`，`observe`再消费已关联的facts；第二个controller不得竞争读取同一stdout、调用这些破坏性消费接口或另起Pi进程冒充同一会话。独立证明须来自本次明确允许的原生会话日志、已有只读观察接口，或在专用实例启动时装配的原始事件旁路捕获。现已提供按固定v0.80.3原生v3 JSONL读取的独立只读controller源码；具体保护文件及会话仍须随真实资源授权确定，尚未运行真实验收。旁路不得丢弃或修改交给DJ的原帧。

`observe-native-start`必须把当前run的delivery_id、精确native_session_id与实际原生event/message ID关联起来；`observe-empty-opencode`必须直接核对新原生会话的prompt数量；Skill采用须保留实际工具调用及参数关联。DJ accepted台账、适配器自己的receipt投影或controller自报布尔值都不能单独替代这些独立证明。独立观察入口也不产生发送模型prompt、读取其他会话或停止其他实例的权限。

## 物理资源controller的返回契约

`measure-owned-deployment`只测量当前明确授权的自有部署，不能为凑齐角色自动部署服务或启动无关Agent。它接收既有调用中的duration_ms=60000、interval_ms=100，返回实际`proc_pid_rusage`捕获：

- 顶层为`measurement_source: "proc_pid_rusage"`、`complete: true`、非空`native_capture_id`、`duration_ms >= 60000`、整数`interval_ms`在1..100及`samples`数组。
- 每个sample含`elapsed_ms`与`processes`；首点为0，后续时间严格增加，相邻间隔不超过200ms，末点至少60000ms。时间缺口不能用复制前值补齐。
- 每个process含正整数`pid`、十进制字符串`start_abstime`、实际非负整数`physical_footprint_bytes`与`rss_bytes`、`ownership_verified: true`、`category: "dj" | "external_agent"`及真实`roles`数组。同一sample不得重复PID；PID与出生标识用于核对进程归属，不能仅按进程名猜测。
- 整窗实际覆盖`dj`、`lark_websocket`、`mcp_proxy`、`external_agent`四种角色；按真实归属把DJ和自有适配器/代理记入dj类别，外部Agent单独记账。不能给不存在的进程贴角色凑数，也不能把RSS当作已含压缩的physical footprint。

现有`summarizeResources`按每个采样点分别求DJ、外部Agent和总物理占用峰值；真实性能用例要求DJ侧峰值不超过268435456字节。受控构建/测试guard的峰值、某个单时点ps读数或本地模拟负载的RSS不能代替这份60秒部署轨迹。此处整理现有消费者的准确字段与判定，不表示捕获器、授权部署或真实资源验收已就绪。

## 装配顺序及边界

1. 保留现有profile schema及授权缺口；先取得两IM精确chat/topic、两Agent专用会话/实例/工作区、模型工作及启动/停止权限。凭据只进入受保护文件或既有安全入口，不进入Git、argv、报告或协作消息。
2. 按实际工具版本和允许的原生观察入口完成控制器实现与本地协议/错误回归；不把业务源码增加测试后门作为控制器实现。
3. 在明确允许的隔离测试根装配服务、client profiles、控制器及真实摘要。创建配置或目录包不等于安装或部署；原生实例和服务生命周期必须使用本次明确资源权限。
4. 真实执行前逐一审阅控制器源码与资源绑定。采用既有verify选择器逐例运行、保留关联证据与清理结果；缺授权/入口/可证观察来源时如实not_run，不能以driver自报代替平台事实。
5. 四组合原话题回复、busy排队、免订阅直发、原实例创建/受控启动停止、Skill实际采用、物理资源分别收齐，最后按A01–A20审计。控制器协议就绪不代表这些用例已通过。


## M物理控制器的编译与保护装配（未部署）

新增Eliscript入口tools/resource-controller.eli，统一build后产生dist-tools/tools/resource-controller.mjs及其Eliscript依赖/运行时。复制完整dist-tools内容到经授权profile根的controllers目录，保留tools/src/node_modules相对树并确保目录0700、文件0600；不只复制入口遗漏传递模块。此处是人工装配步骤，不自动复制到真实服务目录。按最终入口字节计算entry_sha256，argv第一项固定测试Bun，第二项controllers/tools/resource-controller.mjs，第三项resources.binding.json。仅measurement driver可指向该入口；其余入口按本页顶部当前计数装配，15项均默认未授权。

resources.binding.example.json默认authorized=false和PID/出生值0；须由获准部署的操作者在保护的resources.binding.json填入精确PID、libproc出生十进制字符串、原生可执行路径及已核对用途的四角色映射，审阅后才授权。程序不会推断角色或自行启停进程。明确外部Agent根可以位于DJ子树内，该边界单独归类；所有已验证后代（包括后续重挂父但仍存活的原身份）都计量，不重复、不按名称杀进程。超过32活进程、root变更、身份/权限未知或>200ms采样缺口会失败，不能截断部署范围使其通过。

真实入口只使用公开libproc和宿主时钟；模块级mock reader/clock只服务本地组件测试，不能从配置或环境启用。自身reader与纯601点模拟通过也不代表四角色真实部署、256MiB或A20通过；须待原授权部署/资源具备后执行既有T27.deployment-resources.performance，不改门槛。


### 当前M实现的真实拓扑限制（仍未闭环）


真实门禁沿用原完整短进程覆盖依据，不能为适配当前工具改成只测稳定根、随意贴角色、遗漏CLI/MCP子进程或声称短进程物理占用为零。M本地947项只证明所写组件/固定森林范围；动态角色与出生/退出覆盖须继续完成权威观察源及实现后，才可授权装配并运行真实T27。不能把目前的complete字段当作已经证明真实DJ所有进程覆盖。

补充原生接口事实：当前Apple SDK及公开xnu sys/event.h说明，EVFILT_PROC的NOTE_FORK不会把child PID带给实际kevent，NOTE_TRACK/NOTE_CHILD自macOS10.5起不再支持。因此不能只加这些标志就声称已有完整子进程出生观察器；尚未运行任何此类监控，也未请求/取得额外系统观测权限。

## Pi原生日志与共享观察入口（PO，本地D通过、真实未验）

`observe-direct-input`与`observe-native-start`共用`controllers/tools/native-observer-controller.mjs`，按精确tool分流；`observe-empty-opencode`仍使用原OpenCode入口。复制完整dist-tools树，不只复制入口。native-observer.binding.json只引用同一保护根中的opencode-observer.binding.json/pi-observer.binding.json，三个绑定均须逐项审核并授权，未选择的平台不加载。默认示例保持false/零摘要，无自动发现、RPC竞争消费、模型调用或实例创建。

Pi日志只读授权文件本身的v3 header与8MiB尾窗，要求精确cwd/session；连续完整JSON行及原生父链关联本次run/delivery，前后file identity变化失败。原生0644只读日志允许，绑定根0700/文件0600；日志不得被组/其他用户写，符号链接拒绝。日志记录不是进程PID、当前活性或完整历史证明。固定v0.80.3源码表明首个assistant前文件可能尚未flush；缺失原生事实时失败，不能另开Pi或读取其他会话补齐。

新增T49.direct-control.pi.real与原OpenCode用例共享direct-control步骤：目标authorized/allow_model_work与session.get返回tool/session_key/native_session_id在发送前逐项核对。它只是验收源码接线；当前无实际Pi目标/文件/模型工作授权，真实用例not_run，四组合与完整S3不勾。


## O1-O3 native observation (local D passed, real acceptance pending)

The protocol reference is OpenCode v1.18.30, commit 3104c1428ec91f809e5ab86631300de41eb6952e, fetched as an exact tag without switching the cached working tree. GET /session/:id/message uses limit=64 and X-Next-Cursor. The observer encodes only that cursor into a same-origin before parameter and never follows a Link URL. A raw native user text part must contain the exact external_message delivery and run marker. Native started additionally requires an assistant message in that same session whose parentID points to that user. The observer sends no prompt, abort, or message mutation.

T51 will resolve the newly created session native ID via session.get strictly as address mapping, then independently GET the native identity and empty message list, checking projectID/directory/id and stableSessionKey. native_instance_id is an operator-authorized endpoint label, explicitly marked instance_identity_source=authorized_endpoint_binding. The HTTP API supplies no PID/epoch attestation. Real resource acceptance must verify that endpoint mapping and must not present the label as a measured native process identity.

Local build106 component and HTTP/CLI tests plus independent review passed. No controller installation, credential binding, or live model acceptance has occurred. M complete short-process coverage and the other native driver gaps remain open.


### O controller packaging (build106 local D passed, not deployed)

Build all entries, then copy the complete dist-tools dependency tree into the explicitly authorized profile root under controllers, preserving module-relative paths and private directory/file modes. The entry is controllers/tools/opencode-observer-controller.mjs; argv contains the test Bun, that entry, and opencode-observer.binding.json. Bind the exact native endpoint/project/directory/instance and dedicated session targets; review source, supply protected credentials, and set a real entry digest before any authorized execution. Default examples remain unauthorized with zero digest and no credentials.

Only observe-direct-input and observe-empty-opencode examples select this new entry. observe-native-start is shared with Pi and remains unimplemented in the generic example; a reviewed OpenCode-only test profile may explicitly select this entry, while Pi requires its own independent observation source. Do not use an OpenCode-only observer to claim Pi readiness. The endpoint instance label provenance is explicit in successful metadata; no native PID proof is invented.
