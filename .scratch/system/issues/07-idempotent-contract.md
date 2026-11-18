# idempotent-contract: 单独运行与幂等契约

Type: grilling
Status: resolved

## Question

全流水线统一的健壮性契约（用户显式要求）：每个阶段模块 MUST 可单独运行；运行失败或作用于已有 OS 时行为可预期。定稿：幂等语义（重跑结果一致）、退出码/日志约定（沿用 pe-deploy 的区间退出码 + 载荷侧日志风格？）、preflight 自检模式（dry-run/检测已有 OS 时降级为报告）、各阶段失败后的重入路径。

## Answer

定稿全流水线健壮性契约（用户逐条确认）：

1. **幂等语义两级模型**：契约不追求统一语义，每个 action 声明自己属于哪级——
   - 收敛级（converge）：重跑把状态拉回声明值。audit（manifest 安装 / registry:set）、OOBE logon per-user 任务、maintenance、PE 驱动注入（DISM 重复注入同一驱动安全）全部属此级。
   - 拒绝级（refuse）：动作不可重入或破坏性，重跑先检测再硬拒绝（非零退出并说明）。sysprep /generalize、镜像 capture 属此级（检测到已 generalize 的镜像 / 已有 wim 即拒绝）。
2. **退出码区间**：沿用 pe-deploy「2xx = preflight 拒绝、无副作用」风格，按阶段分配互不相交子区间：PE 201–209（现状不动，207 已被 04 号票的 dism-build preflight 占用）、audit 211–219、OOBE 221–229、maintenance 231–239、根级入口 241–249。self-check 维持「退出码 = 失败断言数」。执行期失败用其余非零退出码，语义由日志承载。新增失败原因先用本阶段区间空位，耗尽才换段。
3. **check 模式**：每个阶段提供成对 task 命令 `system:<stage>:check`（优于参数形式）——跑完整 preflight 与漂移检测，只报告不施加变更。退出码：0=干净、10=有漂移、2xx=preflight 拒绝。拒绝级模块的 check 即其拒绝级检测。
4. **作用于已有 OS**：PE 模块只要有 `\Windows` 就照常注入，不区分全新施放 vs 存量系统（DISM 驱动注入幂等无害，区分只增加出错面）；202/203/204 目标盘探测已足够。
5. **失败重入**：收敛级失败后直接重跑；拒绝级失败回到该阶段起点整体重跑，不做断点续传（sysprep generalize 中断即系统状态不可信，从 sysprep 重新开始）；OOBE FirstLogonCommands / logon 任务有全局 mutex 串行，失败后下次登录自动重跑。此条同时收拢了 map 中「各阶段失败恢复的整体策略」fog。
6. **日志约定**：在线阶段日志统一落 `%TEMP%\system\<stage>-<timestamp>.log`（与 pe-deploy `%TEMP%\pdi-*` 同风格），PE 阶段维持现状；内容沿用 `FAIL:` / `ERROR:` 行前缀便于失败计数；不引入集中式日志目录或结构化格式。
