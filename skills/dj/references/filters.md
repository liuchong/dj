# 消息触发黑名单

- purpose: 通过同一持久规则模型管理人员、字符或组合条件；消息可见度与触发行为分离。
- boundary: 当前只支持服务级suppress_trigger，不能隐藏、删除消息或绕过既有读取权限。管理需要message.filter.manage、读取需要message.filter.inspect，资源均为message-filter:service。
- read: 先调用message.filter.get读取revision和已有rules，不因新增一人就覆盖其他规则。
- literal: sender.id来自获准消息的原生ID，不猜显示名；contains按区分大小写的字面子串，支持Unicode/emoji，空contains/prefix拒绝。
- composition: 启用规则之间按OR；规则内使用all/any/not。可用connection_id缩小范围，不把不同平台同名人自动合并。

## 一次设置人员和字符

message.filter.update输入如下；将示例revision、连接、人员ID与字符替换成实际授权内容，保留当前其他规则：

```json
{
  "expected_revision": 1,
  "idempotency_key": "filters-update-1",
  "rules": [
    {"id":"blocked-people","enabled":true,"effect":"suppress_trigger","predicate":{"all":[{"field":"connection_id","op":"eq","value":"lark-main"},{"field":"sender.id","op":"in","value":["person_native_id"]}]}},
    {"id":"blocked-text","enabled":true,"effect":"suppress_trigger","predicate":{"any":[{"field":"text","op":"contains","value":"不触发的词组"},{"field":"text","op":"contains","value":"🚫"}]}}
  ]
}
```

- update: 替换同一rule.id对应条件；保留其他条目，重新读取revision后一次提交完整rules。版本冲突先读最新策略，不能盲目覆盖；同一逻辑请求保持相同幂等键和输入。
- disable: 将原规则enabled改为false后按当前revision更新；删除该条规则也使用完整列表。清空全部规则传rules=[]。
- effect: 命中或条件因正文截断而无法判定时阻止本次自动触发，原消息仍可通过message.list/get等按原授权读取。显式session.send和message.send/reply不属于订阅自动触发。
- pending: 未提交的push与待领取的pull会按最新规则复核；已经提交或仍有效的已领取信封不隐藏、不撤回。取消屏蔽不会自动补发被阻止的历史消息。
- extension: 条件与effect分别扩展；当前运行时拒绝未知effect，不声称支持未来的隐藏、删除或脱敏动作。
