# 01: 引擎 enable 拆除与 state 传播

**What to build:** dispatch 引擎不再理解 `enable`：三处 enable 过滤删除，过滤步只剩 platforms；组引用条目的 `state` 值按 continue_on_error 同机制传播给未声明自身 state 的成员（成员显式优先）；残留 `enable` 键在内联 item / 组成员 / 组引用条目任一层出现即 fail，错误信息含 manifest 路径、展开序号 `#N` 与「注释掉条目或改用 state」指引。同批把 manifests/ 下 8 处 `enable: false`（dsh 1 处、app-video 3 处、app-kernel 4 处，均为组引用条目）迁为注释行，保证仓库在任何 wrapper 运行下保持绿。行为契约见 openspec change `manifest-item-state` 的 manifest-v2-dispatch / manifest-v2-schema delta。

**Blocked by:** None（可立即开工）

**Status:** resolved

- [x] 重放 fixture：组引用 `state: absent` 传播至未声明成员；显式声明成员保留自身值（对照 group-coe-* 系列风格，新增 state-* 系列）
- [x] 结构 fixture：残留 enable（内联 / 成员 / 引用三形态）fail，消息含 `#N`、manifest 路径、指引文案
- [x] filtering fixture 去掉 enable 用例，platforms 行为回归不变
- [x] manifests/ 全目录 grep `enable` 清零（8 处迁注释，保留行内容）
- [x] check-dispatch.sh 全绿；引擎保持零依赖（ADR-0001：Task 模板内实现，不引入外部命令）

## Comments

- 实施备注（6622e06 / ef050a6 / 1054c6e，merger 全绿验证）：dsh.yaml 的 enable 实为内联条目而非组引用，按实际处理；「grep 清零」按零活跃声明口径达成（注释行与无关键名 `aria2-enabled` 保留字面量）。
- 附带修复两处基线即红的检查断言：no-such-task 退出码断言（后经 merger 放宽为 200|201，task 版本敏感：3.51.1=201 / 3.54.0=200）、check.py 陈旧 `>&2` 断言。
