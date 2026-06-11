# 获取 hash

## fetchzip（pkgs 下的预编译二进制包）

```bash
nix-prefetch-url --unpack "https://example.com/release-${version}/pkg-{platform}.zip"
```

注意：`nix-prefetch-url --unpack` 的结果可能与 `fetchzip` 实际解压后的 hash 不一致。如果构建时出现 hash mismatch 错误，直接用错误信息中的 `got:` 值替换即可。

## fetchFromGitHub

先获取最新 commit hash：

```bash
git ls-remote https://github.com/{owner}/{repo}.git HEAD
```

再获取 SRI 格式的 hash：

```bash
nix-prefetch-url --unpack "https://github.com/{owner}/{repo}/archive/{rev}.tar.gz" | xargs -I{} nix hash convert --hash-algo sha256 --from nix32 --to sri {}
```

注意：同理，如果构建时 hash mismatch，直接用 `got:` 值替换。
