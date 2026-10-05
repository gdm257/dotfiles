# 01: 实现 run group 纯展开与向下兼容

**What to build:** `run:manifest` 对含 `{ group: <name> }` 的 manifest 端到端可执行 —— group 按声明顺序纯展开、成员沿用 run item > preset > defaults 解析；未知 group、嵌套 group 报错；旧格式 manifest 行为不变。

**Blocked by:** None (can start immediately)

**Status:** resolved

- [x] `{ group: <name> }` 展开为 `groups.<name>` 成员，顺序一致，preset/defaults 解析不变
- [x] 引用不存在的 group 报错，信息含 group 名与 manifest 路径
- [x] group 内嵌套 group 报错
- [x] 全注释（null）与空 `[]` group 展开为零条，不报错
- [x] 旧格式 manifest（无 groups）行为不变，unknown preset 报错不回归
- [x] 真实 manifest dry-run 通过

## Answer

yq 预处理展开（`_RUNS_JSON`）+ Task 模板在 RUN map 构建时对残留 `group` 键 `fail`（与既有 unknown preset 校验同模式）。本机 yq 为残缺实现：不支持 `if`/`get`/object 构造，且 `error()`/`select` 组合行为异常，故错误检测放 Task 层。
