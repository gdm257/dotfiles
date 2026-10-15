# 09: 长尾批一：运行时 / 包管理族迁移

**What to build:** 长尾前半，17 个 manifest 逐族迁移：volta、volta-unix、vfox-plugin、vfox-sdk、vfox-globalize、pipx、pipx-unix、npm、cargo、cargo-unix、go、conda-create、rye、stack、pi、astro、x-cmd。每族一个接收方 task（kind 命名遵循 `<manager>-<resource>` 小写 kebab 规则；Kind Registry 表仅示范首批，本批 kind 自行按规则命名），manifest 原地重写、wrapper 翻转为 dispatch。批内三件套同一 commit。

接收方 task 命名与落位实现期自定；windows / unix 变体（`*-unix`）的 `platforms` 表达遵循 schema 保留键规则。

**Blocked by:** 05: scoop 族迁移（大头批）.

**Status:** ready-for-agent

- [ ] 各族接收方就绪（容错模式含）
- [ ] 17 个 manifest 原地重写、wrapper 翻转，三件套同 commit
- [ ] 全部 `task manifest:<name>` 用户面名字不变，经 dispatch 走通
- [ ] 批内 grep 双清零
- [ ] `CONTINUE_ON_ERROR` / item 级容错行为不变
