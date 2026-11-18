# 08: 根级薄入口、退出码区间与文档收口

**What to build:** `system/` 根薄入口依次调用各模块 self-check（退出码=失败断言数），全流水线退出码区间（audit 211–219、OOBE 221–229、maintenance 231–239、根级 241–249）落地核对，日志统一落 `%TEMP%\system\<stage>-<timestamp>.log`；`system/README.md` 汇总阶段结构、命令表与端到端流程（audit → sysprep/capture → PE → OOBE → maintenance，及镜像保鲜全量重跑）。

**Blocked by:** 01, 03, 04, 05, 06, 07

**Status:** ready-for-agent

- [ ] 根 self-check 入口一次跑全部模块断言
- [ ] 各阶段退出码落在自己区间，区间互不相交，文档有表
- [ ] 在线阶段日志路径与命名符合约定
- [ ] README 完整描述端到端流程与保鲜流程
