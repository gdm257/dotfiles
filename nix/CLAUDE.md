# nix-config

整个 repo 的所有文件都在为 `flake.nix` 填充内容。理解 `flake.nix` 的结构就理解了整个 repo。

| 属性 | 接口 | 位置 | 用法 |
|------|------|------|------|
| `inputs` | Flake | `flake.lock` | `inputs.xxx` |
| `outputs.packages` | Flake | `pkgs/` | `nix build .#pkgname` |
| `outputs.formatter` | Flake | `nixpkgs.alejandra` | `nix fmt` |
| `outputs.overlays` | Nix | `overlays/` | `pkgs.xxx` `pkgs.unstable.xxx` |
| `outputs.nixosModules` | NixOS | `modules/nixos/` | `outputs.nixosModules.xxx` |
| `outputs.homeManagerModules` | home-manager | `modules/home-manager/` | `outputs.homeManagerModules.xxx` |
| `outputs.nixosConfigurations` | NixOS | `nixos/configuration.nix` | `nixos-rebuild --flake .#hostname` |
| `outputs.homeConfigurations` | home-manager | `home-manager/home.nix` | `home-manager --flake .#username` |
| `globals` variable | custom | `config.default.json` + `config.json` | `globals.xxx` |

## Usage

### globals

1. 在 `config.default.json` 中定义默认值
2. （可选）在 `config.json`（gitignore）中覆盖
3. 在任意模块中通过 `globals.xxx` 使用

### inputs

1. 在 `flake.nix` 的 `inputs` 中添加 `xxx.url = "..."`
2. 如需获取 hash 见 `.claude/rules/nix-hash.md`
3. 在模块中通过 `inputs.xxx` 引用
4. 更新：`nix flake lock --update-input xxx`

### packages

1. 在 `pkgs/` 下创建目录，编写 `default.nix`（标准 nix 包格式）
2. 在 `pkgs/default.nix` 中注册：`xxx = pkgs.callPackage ./xxx { };`
3. 使用：`nix build .#xxx`，或在配置中通过 `pkgs.xxx` 引用（由 `overlays.additions` 自动注入）

### nixosConfigurations

1. 在 `nixos/` 下创建 `.nix` 文件（标准 NixOS module 格式，接收 `{ inputs, outputs, globals, ... }`)
2. 在 `nixos/configuration.nix` 的 `imports` 中引入
3. 应用：`nixos-rebuild switch --flake .#hostname`

### nixosModules

1. 在 `modules/nixos/` 下创建 `.nix` 文件
2. 在 `modules/nixos/default.nix` 中注册：`xxx = import ./xxx.nix;`
3. 引用：`outputs.nixosModules.xxx`

### homeConfigurations

1. 在 `home-manager/` 下创建 `.nix` 文件（标准 home-manager module 格式，接收 `{ inputs, outputs, globals, ... }`）
2. 在 `home-manager/home.nix` 的 `imports` 中引入
3. 应用：`nixos-rebuild switch`（NixOS module 模式）或 `home-manager switch --flake .#username`（standalone 模式）

### homeManagerModules

1. 在 `modules/home-manager/` 下创建 `.nix` 文件
2. 在 `modules/home-manager/default.nix` 中注册：`xxx = import ./xxx.nix;`
3. 引用：`outputs.homeManagerModules.xxx`
