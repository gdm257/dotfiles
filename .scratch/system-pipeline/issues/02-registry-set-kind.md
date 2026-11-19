# 02: manifest 新 kind registry:set

**What to build:** 以 manifest item 声明 registry/HKLM 设置（kind 如 `registry:set`），走既有 dispatch → receiver 路由，重跑收敛到声明值；配套 manifest 文件、`manifests:registry:set` 任务与 receiver，self-check 用 stub seam 验证幂等与漂移修复语义。

**Blocked by:** None (can start immediately).

**Status:** resolved

- [x] item 经 dispatch 路由到新 receiver，值写入生效
- [x] 重跑结果一致；手动改掉注册表值后重跑拉回声明值
- [x] 未知 kind 照旧被 dispatch 报 unclaimed
- [x] receiver self-check 断言全 PASS
