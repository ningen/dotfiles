# CLAUDE.md

このファイルは、Claude Code (claude.ai/code) がこのリポジトリでコードを操作する際のガイダンスを提供します。

## リポジトリ概要

このリポジトリは、Nix Flakes と Home Manager を使用してmacOSとLinux (NixOS) システム間で宣言的で再現可能な環境設定を管理する個人用dotfilesリポジトリです。

## 主要コマンド

### 設定の適用・更新
```bash
# Flakeの依存関係を更新し、Home Manager設定を適用
nix run .#update

# NixOSシステム設定を適用（NixOSのみ）
sudo nixos-rebuild switch --flake .#myNixOS

# Home Manager設定を手動で適用
nix run nixpkgs#home-manager -- switch --flake .#ningen@$HOSTNAME

# Darwin設定を適用（macOSのみ）
sudo nix run nix-darwin/nix-darwin-24.11#darwin-rebuild -- switch --flake .#ningen
```

### 開発用コマンド
```bash
# Flakeの依存関係のみ更新
nix flake update

# Flake設定をチェック
nix flake check

# 現在のシステム設定を表示
nix show-config

# 切り替えずに設定をビルド
nix build .#homeConfigurations."ningen@$HOSTNAME".activationPackage
```

## アーキテクチャ

### Flake構造
- **flake.nix**: 入力、出力、システム設定を定義するメイン設定ファイル
- **マルチプラットフォーム対応**: aarch64-darwin (Apple Silicon) と x86_64-linux
- **モジュラー設計**: 共通設定、ホスト固有設定、パッケージコレクションを分離

### 主要設定モジュール
- **nix/hosts/common/home.nix**: starship、direnv、zshを含むHome Managerベース設定
- **nix/packages/**: 機能別に整理されたパッケージコレクション（dev-tools、language-servers、formatters、node-packages）
- **nix/hosts/nixos/**: Hyprland、NVIDIAドライバー、日本語入力を含むNixOS固有のシステム設定
- **nix/hosts/ningen-mba/**: nix-darwinを使用したmacOS固有設定

### ホスト設定
- **ningen@ningen-mba.local**: macOS Apple Silicon開発環境
- **ningen@DESKTOP-0DRJD1E**: Linux開発環境
- **ningen@nixos**: GUIアプリケーション付き完全NixOSデスクトップ
- **myNixOS**: NixOSシステム設定

### 開発スタック
- **エディタ**: Neovim with 言語サーバー（TypeScript、Python/Pyright、Lua、Nix）
- **言語**: Node.js (Volta)、Python (uv)、Go、Haskell (GHC)、C/C++ (GCC)
- **ツール**: Git、Lazygit、Docker、Tmux、Direnv、AWS CLI v2
- **フォーマッター**: Prettier、Black、Stylua、nixfmt

### プラットフォーム固有機能
- **NixOS**: Hyprlandコンポジター、NVIDIAドライバー、日本語入力（Fcitx5+Mozc）、ゲーミング環境
- **macOS**: システムデフォルト統合、Homebrewアプリ管理、nix-darwin設定

## Node.js パッケージ管理

このリポジトリはNode.js依存関係の管理にnode2nixを使用します：
- **nix/node2nix/node-packages.json**: NPMパッケージ仕様
- **nix/node2nix/node-packages.nix**: 自動生成されたNix式（編集禁止）
- **nix/packages/node-packages.nix**: Nodeパッケージ統合モジュール

Node.jsパッケージを更新するには：
1. `nix/node2nix/node-packages.json` を編集
2. `nix-shell -p node2nix --run "node2nix -i nix/node2nix/node-packages.json -o nix/node2nix/node-packages.nix"` を実行
3. `nix run .#update` で設定を適用

## 設定管理

すべての設定は宣言的でバージョン管理されています。変更は原子的に適用され、ロールバック可能です。システムは以下をサポートします：
- **再現可能ビルド**: 同じ設定が同一環境を生成
- **マルチホスト管理**: 単一リポジトリで複数マシンを管理
- **モジュラーアーキテクチャ**: ホストごとに機能セットの有効/無効を簡単に切り替え