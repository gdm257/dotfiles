Bad: `./node_module/.bin/tsc ...` `~/myrepo/node_module/.bin/tsc`
Good: `tsc ...`

Do NOT run toolchain binary with relative/absolute path. Execute command directly. If command is not found, you should consider whether deps are installed by package manager, checking packages and scripts declaration file like `package.json` `pyproject.toml` or using `bunx` `npx` as last method.
