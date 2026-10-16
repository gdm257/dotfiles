# 06: winget 族迁移

**What to build:** 为 `winget-app` 建接收方 task（消费 `id`、`source`（`winget` / `msstore`，默认 `winget`）、`version`（string）；msstore 变体 → `source: msstore`），`manifests/winget.yaml` 原地重写为 v2，`manifest:winget` wrapper 翻转为 dispatch——三件套同一 commit。交付后 `task manifest:winget` 行为与迁移前一致。

接收方 task 命名与落位实现期自定。

**Blocked by:** 05: scoop 族迁移（大头批）.

**Status:** resolved

- [x] 接收方 task 就绪 + `manifests/winget.yaml` v2 重写 + wrapper 翻转，三件套同 commit
- [x] `source` / `version` 声明字段按接收方契约消费；msstore 资源走 msstore 分支
- [x] 批内 grep 双清零：manifest 顶层无 `run:` / `presets:`，无 `manifest:run:manifest` 残留引用
- [x] `CONTINUE_ON_ERROR` / item 级容错行为不变
- [x] 上位契约：`.scratch/manifest-declarative/details/schema.md` Kind Registry 节

## Comments

- 实现 `b62761c`，fast-forward 合入集成分支，后续系统包合并尖端 `1228047`。三件套同 commit，32 个 active item 身份及顺序保留；msstore / string version / 未知字段容忍经安全 dry-run 验证。
- merger 复验 `task --list` 与 wrapper `--dry` 通过，批内 grep 双清零；未执行真实安装。

## Answer

- 实现 `b62761c` 保留 32 个 active item 的身份、顺序和公开 wrapper；三件套同 commit。
- 容错修复 `c72e2eb` 已经合入 `5d24208`，空行清理 `06917d2`。item 显式 false 覆盖全局 true，传入 `FAIL_LOG` 优先使用，缺失时 fallback。
- merger 重放九组安全 CLI 检查全部通过，winget 分支仅 dry-run，不执行安装；`task --list`、runtime 84 场景和 17 wrapper 检查通过，diff whitespace clean。
