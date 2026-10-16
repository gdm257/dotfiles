# 09: 长尾批一：运行时 / 包管理族迁移

**What to build:** 长尾前半，17 个 manifest 逐族迁移：volta、volta-unix、vfox-plugin、vfox-sdk、vfox-globalize、pipx、pipx-unix、npm、cargo、cargo-unix、go、conda-create、rye、stack、pi、astro、x-cmd。每族一个接收方 task（kind 命名遵循 `<manager>-<resource>` 小写 kebab 规则；Kind Registry 表仅示范首批，本批 kind 自行按规则命名），manifest 原地重写、wrapper 翻转为 dispatch。批内三件套同一 commit。

接收方 task 命名与落位实现期自定；windows / unix 变体（`*-unix`）的 `platforms` 表达遵循 schema 保留键规则。

**Blocked by:** 05: scoop 族迁移（大头批）.

**Status:** resolved

- [x] 各族接收方就绪（容错模式含）
- [x] 17 个 manifest 原地重写、wrapper 翻转，三件套同 commit
- [x] 全部 `task manifest:<name>` 用户面名字不变，经 dispatch 走通
- [x] 批内 grep 双清零
- [x] `CONTINUE_ON_ERROR` / item 级容错行为不变

## Answer

- 原子实现 `c3323a9` 包含 17 manifest、14 接收方及 17 wrapper，同 commit；集成合并 `aacc161`。
- 对齐提交 `ea27795` 将 volta kind 统一为既有 `volta-tool`，保留原始资源内容与顺序，并清理 receiver 尾部空行。
- 标准库 checker 通过 14 接收方 × 6 场景、17 wrapper dry-run 和批内双清零；覆盖未知字段、显式 false 优先、传入日志及 standalone 缺失日志。
- merger 额外验证动态 `CALL=runtime:volta:apply` 渲染 node、npx、pnpm、yarn；`task --list` 与 diff whitespace 通过。未执行安装或原生 Unix 验证。
