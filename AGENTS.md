home 仓库：整棵 home 目录纳入 git，ignored 树（apps/scoop、libraries/、codebase/、state/ 等）远比被追踪内容庞大。

## File discovery

- 内容搜索用遵守 `.gitignore` 的工具（`rg`；`grep` 默认不遵守，同条只作指名搜索）。多数 agents 的按名发现工具（glob/file-listing）不遵守 `.gitignore`，海量 ignored 文件会灌满结果上限并带偏排序。
- 按名发现优先用 `fd`（默认遵守 `.gitignore`）；agents 的 glob 只在已指向具体子树时使用，全仓库按名发现也可用 `git ls-files --cached --others --exclude-standard` 加 pattern 过滤。
- `.gitignore` 不是访问控制：ignored 文件照样可被 `glob` 列出、`read` 直读、`grep` 指名搜索，secrets 的存放与授权不依赖它。
