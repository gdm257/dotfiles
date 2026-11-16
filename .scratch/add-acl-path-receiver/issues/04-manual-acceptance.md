# 04: 管理员环境手工验收

**What to build:** 在管理员终端对临时目录树做一次性真实验收：验证 grant、owner、reset、protected 跳过四类行为与幂等性（重复运行结果一致），确认后把常用 D 盘路径补入 manifests/permissions.yaml。

**Blocked by:** 03

**Status:** ready-for-agent

- [ ] 临时目录树四场景（grant / owner / reset / protected 跳过）逐项通过
- [ ] 连续两次 apply，ACL 输出（icacls 查看）无差异
- [ ] 至少一条真实路径入册 manifests/permissions.yaml
