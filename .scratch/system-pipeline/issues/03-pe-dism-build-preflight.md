# 03: PE dism-build preflight 硬校验

**What to build:** pe-deploy 注入前读 dism 文件版本与目标系统 build 比对，dism < build 时拒绝注入并以新退出码 207 退出，报错信息提示「PE 过旧，请升级 PE」；self-check 补对应断言。

**Blocked by:** 01

**Status:** resolved

- [x] stub dism 版本低于目标 build 时退出 207 且不写任何盘
- [x] 版本满足时照常注入，现有断言不回归
- [x] README 退出码表补充 207
