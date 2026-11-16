# Design

## Context

dotbot 以 `-d .` 运行 links.yaml：`src` 相对仓库根解析，`~` 为真实家目录（USERPROFILE），两者不是同一棵树。现存链接（`.gitconfig`、`.ssh` 等）均为 SymbolicLink，开发者模式已具备创建特权。`state/` 大部分内容被 gitignore。见 proposal.md - Why。

## Goals / Non-Goals

**Goals:** 一条 `task manifests:links:apply` 幂等收敛全部 home 链接；glob/relink/create 行为对齐 dotbot。

**Non-Goals:** 跨平台（仅 windows）；junction；条件链接机制；dotbot 其余配置迁移。

## Decisions

- 单条 PowerShell 命令承载全部收敛逻辑（照抄 acl:apply 模板范式）：glob 展开、存在性判定、relink、父目录创建在 PS 内一次完成；bash 侧零 glob/readlink 依赖（mvdan/sh 不保证 coreutils 存在）。经 `pwsh` 而非 Windows PowerShell 5.1 调用：5.1 的 `New-Item -ItemType SymbolicLink` 不携带开发者模式 unprivileged 标志，非管理员会话必失败；`pwsh` 7+ 携带。
- dotbot `*`+`.*` 成对规则合并为单条 dotglob：`Get-ChildItem -Force` 含隐藏条目，语义等价成对规则，item 数减半。
- glob 零匹配静默：`state/` 大部分 gitignored，bootstrap 时可能为空，静默是 dotbot 既有行为且为可用性必需；精确路径缺失则响亮失败（捕获 manifest 笔误）。通配符与精确路径的分歧由 GCI 语义天然承载：通配符零匹配不报错，精确路径缺失报错。
- 目录语义与精确路径以 dst 尾部 `/` 区分，在 PS 内判定（`EndsWith("/")`），模板只透传 src/dst 两个字符串，模板层零分支。
- PSReadLine 链接的 `if:` 恒真（`C:\Windows\System32` 必然存在），迁移为普通单文件 item，不引入条件机制。
- `create: ~/.ssh/` 不迁移：链接由 state glob 建立，ACL 已由 `manifests/permissions.yaml`（acl-path）接管。
- 无特权预检：New-Item 失败即响亮失败（acl:apply 的 admin 预检是 icacls/takeown 的特有需求，symlink 的 PS 原生错误已足够定位）。
- 指向比较经 `GetFullPath` 归一（大小写不敏感），规避 PS5/PS7 Target 类型差异与分隔符差异。

## Risks / Trade-offs

- [src/dst 含引号或反引号破坏命令拼装] → 接受：与既有 receiver 同一风险面，home 布局无此类路径
- [删除 links.yaml 遗留引用] → 仅 taskfile.yaml 的 dotbot:links 引用它，rg 确认后删除
- [PS 单行脚本可读性] → check-receivers.sh 的 dry-run 断言先行锁定各分支行为
