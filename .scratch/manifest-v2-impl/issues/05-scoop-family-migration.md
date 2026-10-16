# 05: scoop 族迁移（大头批）

**What to build:** 大头批：为 scoop 族建接收方 task（一个接收方按 `kind` 路由三种 item：`scoop-app`（`name`，`bucket/app` 复合名原样保留；sudo 变体 → `elevated: true`）、`scoop-bucket`（`name` + `url`）、`scoop-config`（`key` / `value`）），16 个 manifest 原地重写为 v2——`app-*` × 14（np / kernel / layer / audio / video / devops / downloader / file / network / picture / process / shell / text / toolbox）+ `scoop-bucket` + `scoop-config`——对应 `manifest:app-*` 等 wrapper 全部翻转为 dispatch。批内三件套同一 commit 落地（接收方就绪即整批翻转）。

接收方 task 命名与落位实现期自定。

**Blocked by:** 03: 试点批 debug（kind: shell 接收方）; 04: 试点批 windows-features（state 接收方）.

**Status:** resolved

- [x] scoop 接收方就绪（三 kind 路由 + `elevated` 提权消费 + `continue_on_error` / `FAIL_LOG` 容错模式）
- [x] 16 个 manifest 原地重写为 v2，文件名路径不变；wrapper 全部翻转，三件套同 commit
- [x] `task manifest:app-np` 等用户面名字不变，经 dispatch 走通
- [x] 批内 grep 双清零：16 个 manifest 顶层无 `run:` / `presets:`，全仓 `manifest:run:manifest` 无该批残留引用
- [x] `CONTINUE_ON_ERROR=true` 全局 var（接收方自取）与 item 级 `continue_on_error` 行为不变
- [x] 上位契约：`.scratch/manifest-declarative/details/schema.md` Kind Registry 节、`details/migration.md` Batches 节

## Comments

- batch commit `053ac60`（feat: migrate scoop family to v2 dispatch，18 文件），fast-forward 并入集成分支（尖端 `1a59a11`）；批期间集成分支前进（票 02 fixtures），已在批分支内合并并解 taskfile.d/manifest.yaml EOF 接收方追加冲突（保留 `scoop:apply` 与 `echo:apply` 两者，commit `1a59a11`）。
- 三件套：接收方 `scoop:apply`（requires 仅 `ITEM_JSON`、自取 `_FAIL_LOG` 与引擎同路径；按 kind 路由 scoop-app / scoop-bucket / scoop-config；`elevated` → sudo 前缀；未知 kind 响亮报错；容错照 windows-feature:apply 形态）+ 16 manifest 原地重写（549 active + 805 commented 条目注释原样保留）+ 16 wrapper 翻转。
- 用户面名注记：实际 wrapper 名为双冒号形态 `manifest:app:np` 等（票文 `manifest:app-np` 为示意），迁移前后名字与 `platforms: [windows]` 均未动。
- 验收：grep 双清零（16 manifest 顶层 `run:`/`presets:` = 0；taskfile.yaml 余 52 个 `run:manifest` 引用属未迁批次，68−16=52 吻合）；16/16 wrapper `--dry`，15 个与 v1 展开逐条比对 503 条命令全部一致（4 个另与实采 v1 dry 输出逐字节一致）；仓外 fixture 探针验证 sudo / 容错 / 未知 kind 渲染分支。merger 复验：`--dry manifest:app:np` 渲染 fonts 组 9 条 scoop install、`manifest:scoop-config` 4 条 scoop config、`manifest:app:shell` 等价 fail。
- 既有损坏原样保留（用户内容，待用户裁决）：① `app-shell.yaml` items[0] 引用不存在的组 `scoop-install-sudo`，v1 本来就 fail（同消息），v2 等价保留，疑似应为 `{ group: sudo }`；② `app-np` 的 `path` 组（含唯一 sudo 变体 gdm257/path-globolize-user-scoop）在 v1 `run:` 中本就未被引用，迁移按原样仅引用 `fonts`（schema.md 样例双组引用属示意）。
