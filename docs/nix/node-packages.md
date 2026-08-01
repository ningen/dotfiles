# Node.js パッケージ管理

このリポジトリでは、Node.js CLI パッケージを `nix/packages/node-packages.nix` に集約します。

## 方針

- npm tarball で配布される CLI は `pkgs.buildNpmPackage` で package 化する
- upstream が Flake package を提供している場合は `flake.nix` の input に追加して参照する
- `node2nix` は nixpkgs から削除済みのため使わない

## 現在のパッケージ

- `portless`: npm tarball を `buildNpmPackage` で package 化
- `hunk`: `github:modem-dev/hunk` の Flake package を使用

## 更新手順

### npm tarball パッケージ

1. `npm view <package> version dist.integrity dist.tarball --json` で version と hash を確認
2. `nix/packages/node-packages.nix` の derivation を更新
3. `npmDepsHash` が変わる場合は一度 fake hash で build し、Nix が出す `got:` の hash に置き換える

### Flake package

1. `flake.nix` の `inputs` に upstream Flake を追加
2. `nix flake lock --update-input <input-name>` で lock を更新
3. `nix/packages/node-packages.nix` で `inputs.<input-name>.packages.${pkgs.stdenv.hostPlatform.system}.default` を参照する

## 検証

```bash
nix build '.#homeConfigurations."ningen@ningen-mba.local".activationPackage' --no-link
```
