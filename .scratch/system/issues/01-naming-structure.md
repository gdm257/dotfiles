# naming-structure: 目录命名与阶段结构定稿

Type: grilling
Status: resolved

## Question

流水线的最终命名（`system/` 或更好）与阶段→模块的目录结构定稿：audit / sysprep / PE / OOBE / 维护 各阶段在仓库里如何落位；`reinstall/` 现有四件套（build-drivers / pe-deploy / unattend / self-check）如何平移；阶段中性名与 taskfile 任务命名如何对齐。

## Answer

（与用户一轮 grilling 定稿，四问全取推荐项）

- 顶层目录定名 `system/`：阶段中性、单词、小写，覆盖 audit / sysprep / PE / OOBE / 维护全流程。
- 目录按阶段分子目录（方案 A）：`system/pe/`（build-drivers.cmd、pe-deploy.cmd、bin/）、`system/audit/`、`system/oobe/`、`system/maintenance/` 各阶段自带脚本与载荷；跨阶段的 `unattend.xml` 放 `system/` 根（OOBE 唯一载体、由 pe-deploy 挂钩）。
- self-check 每模块一个放各自子目录，`system/` 根再加薄入口依次调用；与 07 号票「每模块可单独运行」契约对齐。
- taskfile 任务用新前缀 `system:<stage>:<action>`（如 `system:audit:run`、`system:maintenance:run`），与 `manifests:*` 并列；PE 阶段脚本在 PE 里裸跑，不建 taskfile 任务。勘误：现有前缀实际为复数 `manifests:`（map Notes 原记 `manifest:` 系笔误）。
