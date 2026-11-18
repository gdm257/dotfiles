# 07: maintenance 阶段 system:maintenance:run

**What to build:** 手动一条命令重放 Windows 上全部 `manifests:*:install` 任务修复机器级配置漂移（不新增聚合选择机制），配套 `system:maintenance:check` 先报告漂移（0=干净 / 10=漂移）；与 audit 在机器级配置上是同一动作、同一引擎；self-check 验证重放与漂移检测。

**Blocked by:** 02

**Status:** ready-for-agent

- [ ] run 重放全部 Windows manifests:*:install 任务，被改掉的 item 恢复声明值
- [ ] check 不施加变更，退出码语义正确
- [ ] 不含 update 语义、不含 per-user、不含 Windows Update/清理
- [ ] self-check 断言全 PASS
