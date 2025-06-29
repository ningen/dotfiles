# node2nix ガイド

## 概要

**node2nix**は、Node.jsのnpmパッケージをNixパッケージマネージャーで管理するためのツールです。このツールを使用することで、Node.jsプロジェクトの依存関係を宣言的で再現可能な方法で管理できます。

## 基本概念

### node2nixとは

node2nixは、以下の変換を行うツールです：
- `package.json` や `package-lock.json` → Nix式（`.nix`ファイル）
- npmパッケージ → Nixパッケージ

### Nixパッケージマネージャーでの役割

1. **依存関係の一元管理**
   - Node.jsのパッケージ（npm）
   - システムレベルのライブラリ（C言語のライブラリなど）
   - すべてをNixでまとめて管理

2. **再現性の確保**
   - `package-lock.json`を元にNix式を生成
   - 開発環境と本番環境で完全に同じバージョンを再現
   - 「自分の環境では動いたのに…」問題を解決

3. **Nixエコシステムとの連携**
   - NixOSやNixOpsとの統合
   - 宣言的な環境管理

## 基本的な仕組み

### 1. Nix式の生成
```bash
node2nix -i node-packages.json -o node-packages.nix
```
- `package.json`や`package-lock.json`を読み取り
- 依存関係を定義したNixコード（`.nix`ファイル）を自動生成

### 2. ビルド
```bash
nix-build
```
- 生成された`.nix`ファイルを実行

### 3. 環境構築
- 指定されたバージョンのNode.jsをダウンロード・ビルド
- 必要なnpmパッケージをインストール
- 隔離された環境に配置

## インストール方法

### Nixパッケージとして
```bash
nix-env -iA nixpkgs.node2nix
```

### nix-shellで一時的に使用
```bash
nix-shell -p node2nix
```

### Flakeでの使用
```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };
  
  outputs = { self, nixpkgs }: {
    devShells.default = nixpkgs.legacyPackages.x86_64-linux.mkShell {
      buildInputs = [ nixpkgs.legacyPackages.x86_64-linux.node2nix ];
    };
  };
}
```

## 使用方法

### 基本的なワークフロー

1. **パッケージリストの準備**
   ```json
   // node-packages.json
   [
     "express",
     "lodash",
     "@types/node"
   ]
   ```

2. **Nix式の生成**
   ```bash
   node2nix -i node-packages.json -o node-packages.nix
   ```

3. **生成されるファイル**
   - `default.nix` - エントリーポイント
   - `node-env.nix` - ビルド環境定義
   - `node-packages.nix` - パッケージ定義（編集禁止）

### コマンドオプション

```bash
# 基本的な使用
node2nix -i package.json

# 出力ファイル名を指定
node2nix -i package.json -o my-packages.nix

# package-lock.jsonを使用
node2nix -l package-lock.json

# 開発依存関係も含める
node2nix -i package.json --include-dev-dependencies

# Node.jsバージョンを指定
node2nix -i package.json --nodejs-16

# システムを指定
node2nix -i package.json --system x86_64-linux
```

### 既存プロジェクトでの使用

```bash
# プロジェクトディレクトリで実行
cd my-node-project
node2nix -l package-lock.json

# ビルド
nix-build -A package

# 開発環境に入る
nix-shell -A shell
```

## 生成されるファイルの構造

### default.nix
```nix
{ pkgs ? import <nixpkgs> {} }:

let
  nodePackages = import ./node-packages.nix { inherit pkgs; };
in
nodePackages
```

### 使用例
```nix
let
  nodePackages = pkgs.callPackage ./node2nix-output { };
in
{
  home.packages = [
    nodePackages.express
    nodePackages.lodash
  ];
}
```

## メリット

### 1. 完全な再現性
- 同じ設定が同一環境を生成
- バージョンロックによる一貫性

### 2. システムレベルの依存関係管理
- Node.jsパッケージが依存するCライブラリなども自動管理
- システム全体の整合性を保証

### 3. 宣言的管理
- すべての設定がコードとして管理
- バージョン管理による変更履歴

### 4. 原子的な更新とロールバック
- 設定変更は原子的に適用
- 問題があれば簡単にロールバック可能

### 5. 隔離された環境
- プロジェクトごとに独立した環境
- グローバル汚染を回避

## 注意点・制限事項

### 自動生成ファイルの扱い
- `node-packages.nix`は自動生成されるため、直接編集しない
- `node-env.nix`も同様に編集禁止

### パフォーマンス
- 大きなプロジェクトでは初回ビルドに時間がかかる
- 依存関係が多い場合、生成ファイルが巨大になる

### メンテナンス
- npmパッケージの更新には再生成が必要
- 手動での依存関係管理が必要な場合がある

## トラブルシューティング

### よくある問題

1. **ビルドエラー**
   ```bash
   # 依存関係を確認
   nix-instantiate --eval -E 'with import <nixpkgs> {}; nodejs.version'
   
   # キャッシュをクリア
   nix-collect-garbage
   ```

2. **パッケージが見つからない**
   - `node-packages.json`の記述を確認
   - npmレジストリでのパッケージ名を確認

3. **バージョン競合**
   - `package-lock.json`を最新に更新
   - 競合するパッケージを除外

### デバッグのヒント

```bash
# 生成された式の構文チェック
nix-instantiate --parse node-packages.nix

# 依存関係の確認
nix-store --query --requisites $(nix-instantiate default.nix)

# ビルドログの確認
nix-build -v default.nix
```

## このdotfilesでの実装

### ファイル構成

```
nix/
├── node2nix/
│   ├── node-packages.json     # パッケージ仕様（手動編集）
│   ├── default.nix           # エントリーポイント（自動生成）
│   ├── node-env.nix          # ビルド環境定義（自動生成）
│   └── node-packages.nix     # パッケージ定義（自動生成・編集禁止）
└── packages/
    └── node-packages.nix     # システム統合モジュール
```

### 現在管理されているパッケージ

`nix/node2nix/node-packages.json`:
```json
[
  "@anthropic-ai/claude-code",
  "@google/gemini-cli"
]
```

### システム統合

`nix/packages/node-packages.nix`:
```nix
{ pkgs, ... }: 
let
  nodePkgs = pkgs.callPackage ../node2nix { inherit pkgs; };
in
{
  home.packages = with pkgs; [
    nodePkgs."@anthropic-ai/claude-code"
    nodePkgs."@google/gemini-cli"
  ];
}
```

### flake.nixでの統合

パッケージは`flake.nix`で以下のように統合されています：

```nix
homeConfigurations = {
  "ningen@${hostname}" = home-manager.lib.homeManagerConfiguration {
    pkgs = nixpkgs.legacyPackages.${system};
    modules = [
      ./nix/hosts/common/home.nix
      ./nix/packages/dev-tools.nix
      ./nix/packages/language-servers.nix
      ./nix/packages/formatters.nix
      ./nix/packages/node-packages.nix  # <- ここで統合
    ];
  };
};
```

### パッケージ更新のワークフロー

このdotfilesでは以下の手順でNode.jsパッケージを管理します：

1. **パッケージリストの編集**
   ```bash
   # nix/node2nix/node-packages.json を編集
   vim nix/node2nix/node-packages.json
   ```

2. **Nix式の再生成**
   ```bash
   nix-shell -p node2nix --run "node2nix -i nix/node2nix/node-packages.json -o nix/node2nix/node-packages.nix"
   ```

3. **設定の適用**
   ```bash
   nix run .#update
   ```

### 実装の特徴

- **Flakeベース**: 現代的なNix Flakesを使用した構成
- **Home Manager統合**: ユーザー環境での管理
- **マルチプラットフォーム**: macOS (aarch64-darwin) と Linux (x86_64-linux) で共通利用
- **宣言的管理**: すべての設定がコードとして管理され、再現可能

## 関連ツール

- **npm2nix**: node2nixの前身
- **yarn2nix**: Yarn用の類似ツール  
- **pnpm2nix**: PNPM用の類似ツール

## 参考リンク

- [node2nix GitHub Repository](https://github.com/svanderburg/node2nix)
- [Nix Manual - Node.js](https://nixos.org/manual/nixpkgs/stable/#node.js)
- [NixOS Wiki - Node.js](https://nixos.wiki/wiki/Node.js)