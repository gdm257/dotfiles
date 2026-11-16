# Proposal

## Why

dotbot 的 link 布局（`dotbot-configs/links.yaml`）是 home 仓库中最后仍由 dotbot 承载的 symlink 管理，与 manifests/receivers 体系并存形成两套 source of truth；`acl-path` 范式归档后 receiver 模板已成熟，链接应迁入同一体系，使重装系统后一条命令重建 home 链接布局。

## What Changes

- 新增 kind `sym-link` 与 receiver `link:apply`：`src`（仓库根相对 glob 或精确路径）到 `dst`（`~/` 锚定）的 SymbolicLink 幂等收敛（relink、父目录创建、异指替换）
- 新增 `manifests/links.yaml` 承载 links.yaml 全部 link 语义：dotbot `*`+`.*` 成对规则合并为含隐藏条目的单条 glob，PSReadLine 单文件迁移为精确路径 item；恒真 `if:` 条件与已被 `manifests/permissions.yaml` 接管的 `create: ~/.ssh/` 不迁移
- 新增顶层 wrapper `manifests:links:apply`（windows）
- **BREAKING** 删除 `dotbot-configs/links.yaml` 与 `dotbot:links` task，dotbot 不再管理链接（硬切换，无双轨）

## Capabilities

### New Capabilities

- `sym-link`: home 布局 symlink 的声明与收敛契约（src/dst 语义、含隐藏条目的单层 glob 展开、幂等 relink、glob 零匹配静默、目标非 SymbolicLink 响亮失败）

### Modified Capabilities

（无：glob 以普通 item 开放字段表达，`manifest-v2-dispatch` / `manifest-v2-schema` / `manifest-item-state` 契约不变）

## Impact

- `taskfile.d/receivers.yaml`（新增 link:apply）、`taskfile.d/manifest.yaml`（receivers include 补 `dir: ".."`，使 receiver 命令以仓库根为 cwd——否则 `src` 仓库根相对路径解析到 `taskfile.d/` 下；该修正同样惠及 acl:apply 的相对 path item）、`taskfile.yaml`（新增 wrapper、删除 dotbot:links）、`manifests/links.yaml`（新增）、`dotbot-configs/links.yaml`（删除）
- `fixtures/manifest-dispatch/check-receivers.sh` 扩充断言
- dotbot 其余配置（scoop / age / registry / once.lib / test-plugins）不受影响
