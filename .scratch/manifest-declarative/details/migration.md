# Manifest v2 Migration Strategy（定稿）

Status: 定稿。[07: 迁移策略 detail file 定稿](../issues/07-migration-strategy.md) 一轮 grilling 落定（5 问：验收不实跑一条按用户裁决，其余按推荐确认）。
上位：[map.md](../map.md)；item 结构见 [details/schema.md](schema.md)；引擎契约见 [details/engine.md](engine.md)。

事实基线（已实证）：`manifests/` 70 个 v1 manifest 与根 taskfile 70 个 `manifest:<name>` wrapper 一一点名对应（无 glob 枚举）；`manifest:run` 全仓唯一调用方是根 taskfile wrapper；v1 引擎对缺失 `run:` 走 `default list` 兜空——v2 文件误入 v1 引擎会静默空跑 exit 0。

## Coexistence（并存期形态）

- v2 引擎放置：`manifest:dispatch`（04 定稿名）追加进现 `taskfile.d/manifest.yaml`，与 v1 `run` / `run:manifest` 同文件并存。includes 不动；一个 namespace 只能指一个 taskfile，另立文件即被迫改入口名，否决。
- manifest 换代：**原地重写同名文件**——文件名与路径不变，wrapper 的 `MANIFEST` 路径稳定，git diff 即迁移记录。两代同目录混放：无 glob 枚举，误入方向由防呆兜底（见 Freeze）。
- wrapper 翻转：`manifest:<name>` 用户面名字全程不变；内部调用从 `manifest:run:manifest` 换为 `manifest:dispatch` + `MANIFEST` + `CALL`。`CALL` 指向批内就绪的接收方 task（命名与落位属实现期，map Out of scope）。
- 原子性（三件套同 commit）：接收方 task 就绪 + manifest 原地重写 + wrapper 翻转，批内同一 commit 落地。分步的中间态 = v1 引擎跑 v2 文件静默空跑（假成功），禁止。
- UX 不变量：CLI 全局 var（如 `CONTINUE_ON_ERROR=true`）迁移前后同样可用；引擎不转发、接收方自取（04 定稿），行为面不变。

## Freeze（旧格式冻结）

- 禁止新建 v1 格式 manifest；**新增资源 MUST 走 v2 表达**——所在族未迁则先迁该族，或建新 v2 manifest 并补接收方。冻结本身是推进迁移的 forcing function。
- 既有 v1 manifest 只许「下机」类编辑：删除行 / 注释 / `enable: false`；禁止新增 item / group / preset。
- 执行面 = 约定 + 双向机械防呆，不建 CI lint（单人仓库，YAGNI）：
  - v2 引擎：未知顶层键 `fail`（04 定稿）——v1 表达进不了 v2 引擎；
  - v1 引擎加固（并存期启动第一笔）：`run:manifest` 解析后顶层含 `items:` 即 `fail`（消息含 manifest 路径）——v2 误入 v1 由静默空跑变响亮报错。task 名与既有 v1 语义不动，只加拒绝。

## Batches（批次与验收）

- 批 = 一个 manager 族 = 一个接收方 task 的覆盖面；接收方就绪一族迁一族。windows / unix 两侧互不阻塞，可并行。
- 次序锁定三条，其余顺序实现期自定：
  1. 试点批：`debug`（`kind: shell` escape hatch 原型场景）+ `windows-features`（`state` 字段、非 install 形态）；
  2. 大头批：scoop 族（`app-*` 14 个 + `scoop-bucket` + `scoop-config`，约 16 个）；
  3. 其余按族逐批：winget → brew（app + tap）→ apt / yum → npm / pipx 等长尾。
- 每批验收（**静态，不实跑**）：
  1. 三件套同 commit（原子性）；
  2. 批内 grep 双清零：`manifest:run:manifest` 引用残留、manifest 顶层 `run:` / `presets:`；
  3. 结构合法性交给 v2 引擎 fail 自检（未知顶层键 / platforms 值域），首次真实调用即验——不安排实跑验收（已装多为 no-op，实跑无验收价值；用户裁决）。

## Deletion（旧引擎删除判据）

三条件全满足即删，无观察宽限期：

1. `manifests/` 全目录顶层 `run:` / `presets:` grep 零命中——零 v1 格式内容；
2. 全仓 `manifest:run` grep 零命中——v1 入口引用清零（实证唯一调用方为根 taskfile wrapper）；
3. 删除动作 = 单独 commit 删 `run` + `run:manifest` 两 task；`taskfile.d/manifest.yaml` 随即只含 `dispatch`，文件名不改，即纯 v2 引擎。
