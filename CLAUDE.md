# CLAUDE.md

このファイルは、Claude Code (claude.ai/code) がこのリポジトリでコードを操作する際のガイダンスを提供します。

## リポジトリ概要

このリポジトリは、Nix Flakes と Home Manager を使用して macOS と Windows+WSL 間で宣言的で再現可能な環境設定を管理する個人用dotfilesリポジトリです。

## 主要コマンド

### 設定の適用・更新
```bash
# Flakeの依存関係を更新（ロック更新のみ）
nix run .#update-lock

# macOSまたはWSLの設定を適用（実行環境を自動判定）
nix run .#switch

# Home Manager設定を手動で適用（Linux全般）
nix run nixpkgs#home-manager -- switch --flake .#ningen@$HOSTNAME
```

### 開発用コマンド
```bash
# Flakeの依存関係のみ更新
nix flake update

# Flake設定をチェック
nix flake check

# 現在のシステム設定を表示
nix config show

# 切り替えずに設定をビルド
nix build .#homeConfigurations."ningen@$HOSTNAME".activationPackage
```

## Subagent オーケストレーション

- オーケストレーション、設計判断、レビュー判断、最終回答は利用可能な強いモデルで行う。
- `git diff`、`git status`、`rg`、`sed`、`nl`、`ls`、ログ収集、コマンド実行結果の要約は、安い `diff-command-worker` subagent に委譲する。
- `diff-command-worker` は read-only を基本とし、編集・commit・push・破壊的操作・依存関係インストールは行わせない。
- worker からは `task`、`commands`、`findings`、`risks`、`next` の構造で結果を受け取り、オーケストレーターが判断してユーザーに返す。

## アーキテクチャ

### Flake構造
- **flake.nix**: 入力、出力、システム設定を定義するメイン設定ファイル
- **マルチプラットフォーム対応**: aarch64-darwin (Apple Silicon) と x86_64-linux (WSL)
- **モジュラー設計**: 共通設定、ホスト固有設定、パッケージコレクションを分離

### 主要設定モジュール
- **nix/hosts/common/home.nix**: starship、direnv、zshを含むHome Managerベース設定
- **nix/packages/**: 機能別に整理されたパッケージコレクション（dev-tools、language-servers、formatters、node-packages）
- **nix/hosts/wsl/**: クリップボード連携・WSL open bridgeを含むWSL固有設定
- **nix/hosts/ningen-mba/**: nix-darwinを使用したmacOS固有設定

### ホスト設定
- **ningen@ningen-mba.local**: macOS Apple Silicon開発環境
- **ningen@wsl**: Windows+WSL環境用Home Manager設定（共通のswitchで適用）

### 開発スタック
- **エディタ**: Neovim with 言語サーバー（TypeScript、Python/Pyright、Lua、Nix）
- **言語**: Node.js (Volta)、Python (uv)、Go、Haskell (GHC)、C/C++ (GCC)
- **ツール**: Git、Lazygit、Docker、Tmux、Direnv、AWS CLI v2
- **フォーマッター**: Prettier、Black、Stylua、nixfmt

### プラットフォーム固有機能
- **macOS**: システムデフォルト統合、Homebrewアプリ管理、nix-darwin設定
- **Windows+WSL**: Windows側のsymlink配布は `setup-dotfiles.ps1`、WSL側は `nix/hosts/wsl/home.nix`（クリップボード連携・WSL open bridge含む）

## Node.js パッケージ管理

このリポジトリはNode.js CLIパッケージを `nix/packages/node-packages.nix` で管理します：
- npm tarballで配布されるCLIは `pkgs.buildNpmPackage` でpackage化する
- upstreamがFlake packageを提供している場合は `flake.nix` のinputに追加して参照する
- `node2nix` はnixpkgsから削除済みのため使わない

Node.jsパッケージを更新するには：
1. `npm view <package> version dist.integrity dist.tarball --json` でversionとhashを確認
2. `nix/packages/node-packages.nix` のderivation、または `flake.nix` のinputを更新
3. `nix build '.#homeConfigurations."ningen@ningen-mba.local".activationPackage' --no-link` で検証
4. 必要なら `nix run .#switch` で設定を適用

## 設定管理

すべての設定は宣言的でバージョン管理されています。変更は原子的に適用され、ロールバック可能です。システムは以下をサポートします：
- **再現可能ビルド**: 同じ設定が同一環境を生成
- **マルチホスト管理**: 単一リポジトリで複数マシンを管理
- **モジュラーアーキテクチャ**: ホストごとに機能セットの有効/無効を簡単に切り替え

## トラブルシューティング

### 更新エラーの調査手順

1. **基本診断**
   ```bash
   # Flake設定の問題をチェック
   nix flake check
   ```

2. **パッケージ名変更の確認**
   ```bash
   # パッケージの現在の名前を検索
   nix search nixpkgs <パッケージ名>
   ```

3. **設定ファイル内検索**
   ```bash
   # 設定ファイル内で特定文字列を検索
   rg "<検索文字列>" <設定ファイルパス>
   ```

### 一般的なパッケージ名変更例
- `libsForQt5.*` → `kdePackages.*` (KDE関連パッケージ)
- `noto-fonts-emoji` → `noto-fonts-color-emoji`

## ドキュメント

技術的な詳細情報やガイドは `docs/` ディレクトリに整理されています：

- **docs/nix/node-packages.md**: Node.js CLIパッケージ管理のガイド
- **docs/nix/nix-darwin.md**: nix-darwinの詳細ガイド（macOS特有設定、Homebrew統合、システム管理）
- **docs/windows-wsl.md**: Windows+WSL環境のセットアップガイド

## Web検索について

Web検索が必要な場合は、その実行環境で利用可能な検索手段を使ってください。
