# Tasks

## 1. Receiver（断言先行）

- [x] 1.1 在 `fixtures/manifest-dispatch/check-receivers.sh` 新增 link:apply 断言（kind 自验证、state absent 响亮失败、New-Item SymbolicLink 拼装、目录/精确路径语义、同指跳过与 relink 分支、precedence 环），验证新增断言红（receiver 尚不存在）
- [x] 1.2 在 `taskfile.d/receivers.yaml` 新增 link:apply receiver，验证 1.1 断言全绿（bash 直跑，经 `--taskfile taskfile.d/manifest.yaml --dir .`）

## 2. Manifest 与 wrapper

- [x] 2.1 新增 `manifests/links.yaml`（apps/dotfiles/state 三条目录 glob、AppData 三目录 glob、PSReadLine 单文件，共 7 个 item），验证 `task --dry manifests:links:apply` 输出含全部 src
- [x] 2.2 在 `taskfile.yaml` 新增 `manifests:links:apply` wrapper（windows），验证 `task --list` 出现且 `--dry` 可拼装

## 3. 硬切换与验收

- [x] 3.1 实跑 `task manifests:links:apply`，验证与执行前链接快照比对无变化且重跑幂等（现存链接全部同指跳过）
- [x] 3.2 删除 `dotbot-configs/links.yaml` 与 `dotbot:links` task，验证 rg 无残留引用、dotbot:age 等其余 dotbot task 仍可 `--dry`
- [x] 3.3 跑全量 `check-receivers.sh` 与 `check-dispatch.sh`（30 场景）通过
- [x] 3.4 code-review 两轴审查通过后提交（不触碰 session.ini 与 manifests/dsh.yaml 两个无关未提交改动）
