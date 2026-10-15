# 07: 迁移策略 detail file 定稿

Type: grilling
Status: resolved
Blocked by: 04

## Question

`details/migration.md` 的内容定稿（Destination 所列三份 detail files 之一，此前无属主票，03 收口时补立）：

- 并存期入口形态：v1 / v2 引擎入口如何区分调用（依赖 04 的入口 task 命名），根 Taskfile 侧如何组织。
- 旧格式冻结规则：「过渡期冻结、禁止新增」的执行面——v1 manifests 是否只读语义、新增资源必须走 v2 表达。
- 迁移判据：按何种顺序/批次迁（manager 族逐批？）、每批的验收形态。
- 旧引擎删除条件：何时允许删（全部 manifest 迁空、wrapper 重写完成之类判据）。

范围边界见 map Out of scope：只写策略，不执行迁移。

## Answer

一轮 grilling（5 问）：Q1 / Q2 / Q3 / Q5 按推荐确认；Q4 验收部分用户裁决为**静态验收、不实跑**（批粒度、试点批、大头批仍按推荐）。定稿落 [details/migration.md](../details/migration.md)，要点：

- 并存：`manifest:dispatch` 追加进现 `taskfile.d/manifest.yaml` 同文件三 task 并存（includes 不动，另立文件被迫改 04 入口名，否决）；manifest **原地重写同名文件**；wrapper 用户面名不变、内部换调 dispatch；批内三件套（接收方 task + 重写 + 翻转）同 commit 原子落地——分步中间态 = v1 引擎跑 v2 文件静默空跑（实测 `run:` 缺省 `default list` 兜空 exit 0），禁止。
- 冻结：禁新建 v1 manifest、新增资源 MUST 走 v2 表达（所在族未迁则先迁该族，forcing function）；既有 v1 只许下机类编辑（删行 / 注释 / `enable: false`）；执行面 = 约定 + 双向防呆——v2 引擎未知顶层键 `fail`（04 既有）+ v1 `run:manifest` 加顶层 `items:` 即 `fail` 加固（并存期启动第一笔，名与语义不动），不建 CI lint。
- 批次：批 = manager 族 = 接收方覆盖面，windows / unix 可并行；锁定试点批 `debug` + `windows-features`、大头批 scoop 族（约 16 个），其余顺序实现期自定；每批验收 = 原子性 + grep 双清零（`manifest:run:manifest` 引用、顶层 `run:` / `presets:`），结构合法性靠引擎 fail 自检，不实跑。
- 删除：双 grep 清零即删（manifests 零 v1 内容 + 全仓零 `manifest:run` 引用），单独 commit、无观察宽限期；`manifest.yaml` 只剩 `dispatch`，文件名不改。

事实注记：70 manifests ↔ 70 wrapper 一一点名（无 glob 枚举）；`manifest:run` 全仓唯一调用方为根 taskfile。
