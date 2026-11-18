# openspec-draft: 汇总各票决策起草 openspec change

Type: task
Status: resolved

## Question

本图的 destination 是一份 openspec change（matt-pocock schema）定稿。全部架构决策已收齐（00–07），用 `openspec new change`（--schema matt-pocock）把 00–07 各票的 Answer 汇总起草为 change：阶段结构（01）、audit（03）、sysprep/capture（04）、OOBE（05）、maintenance（06）、幂等契约（07）、PE 并入（00/02/04）。change 定稿即本图完成；实现由后续 apply 会话执行。

## Answer

已起草 openspec change `system-pipeline`（matt-pocock schema，4/4 artifacts，`openspec validate` 通过），汇总 00–07 全部决策：

- spec 发布于 `.scratch/system-pipeline/spec.md`（Status: ready-for-agent），含 26 条 user stories 与全部实现/测试决策。
- tickets 拆为 8 张 tracer-bullet 票于 `.scratch/system-pipeline/issues/01..08`：01 PE 平移、02 registry:set kind、03 dism-build preflight(207)、04 audit apply、05 sysprep/capture、06 OOBE 自动化、07 maintenance、08 根级入口与文档收口；依赖边按票内 Blocked by 记录。
- delta specs 三个能力：`system-pipeline`（新，阶段契约/幂等两级/退出码区间/日志/self-check）、`registry-set`（新，receiver 收敛语义）、`pe-driver-inject`（MODIFIED：dism-build 硬校验 207 + unattend 载体改为流水线根）。

本图为最后一张票，map 完成；实现由后续 apply 会话执行。
