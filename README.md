# Dotfiles

このリポジトリは、私の個人的な設定ファイル（dotfiles）を [Nix](https://nixos.org/) と [Home Manager](https://github.com/nix-community/home-manager) を使って宣言的に管理するものです。Nix Flakesを活用し、macOS・NixOS・WSL 間で再現性のある環境構築を実現しています。

## アーキテクチャ概要

このdotfilesリポジトリは、Nix Flakesをベースとしたモジュラー構成で、以下の主要コンポーネントから構成されています：

- **Flake-based管理**: 全体の依存関係とビルド定義
- **マルチプラットフォーム対応**: macOS (nix-darwin)、NixOS、WSL をサポート
- **モジュラー設計**: ホスト固有とパッケージ群に分離された設定

## ディレクトリ構成

```
dotfiles/
├── flake.nix                    # メインのFlake設定ファイル
├── flake.lock                   # Flakeの依存関係ロックファイル
├── dotfiles-links.yaml         # シンボリックリンク設定
├── setup-dotfiles.sh           # セットアップスクリプト (macOS/Linux)
├── nix/
│   ├── hosts/                   # ホスト別設定
│   │   ├── common/             # 全ホスト共通設定
│   │   │   └── home.nix        # Home Manager基本設定
│   │   ├── ningen-mba/         # MacBook Air設定
│   │   │   ├── home.nix        # macOS用Home Manager設定
│   │   │   └── macos.nix       # nix-darwinシステム設定
│   │   ├── linux/              # NixOSデスクトップ設定
│   │   │   ├── configuration.nix
│   │   │   └── hardware.nix
│   │   ├── wsl/                # WSL設定
│   │   │   └── home.nix        # WSL用Home Manager設定
│   └── packages/               # パッケージ群定義
│       ├── dev-tools.nix       # 開発ツール
│       ├── docker-cli.nix      # Docker CLI
│       ├── formatters.nix      # コードフォーマッター
│       ├── language-servers.nix # LSP サーバー
│       ├── linters.nix         # リンター
│       └── node-packages.nix   # Node.js パッケージ
```

## 主要な依存関係

### Flake Inputs

- **nixpkgs**: Nixパッケージ集合（unstableブランチ）
- **home-manager**: ユーザー環境管理
- **nix-darwin**: macOS向けNix設定管理
- **hunk**: hunkdiff CLI
- **stylix**: 配色・フォント・カーソルの一元管理
- **flake-utils**: Flake開発ユーティリティ

### 開発環境スタック

**言語とランタイム:**
- Neovim: メインエディタ
- Node.js (Volta): JavaScript/TypeScript開発
- Python (uv): Python開発環境
- Go: Go言語開発
- GHC: Haskell開発
- GCC: C/C++コンパイラ

**開発ツール:**
- Git: バージョン管理
- Lazygit: Git GUI
- Docker: コンテナ化
- Tmux: ターミナルマルチプレクサ
- Direnv: 環境変数管理
- AWS CLI v2: クラウド管理

**Language Servers & Formatters:**
- TypeScript Language Server
- Pyright (Python)
- Lua Language Server
- nil (Nix)
- Prettier, Black, Stylua, nixfmt

### プラットフォーム固有の設定

**macOS (nix-darwin):**
- システムデフォルト設定 (Dock、Finder等)
- Homebrew連携 (Cask アプリケーション)
- フォント管理 (JetBrains Mono Nerd Font)

**NixOS (ningen-desktop):**
- Hyprland + Waybar + Quickshell のデスクトップ環境
- NVIDIAドライバ、Steam、fcitx5、AirPlayレシーバー

**WSL:**
- Home ManagerによるCLI環境とフォント設定

## サポートシステム

- **aarch64-darwin**: Apple Silicon Mac
- **x86_64-linux (NixOS)**: ningen-desktop
- **x86_64-linux (WSL)**: Home ManagerによるCLI環境

## 構成管理の特徴

1. **宣言的設定**: すべての設定がコードとして管理
2. **再現性**: どの環境でも同じ構成を再現可能
3. **原子的更新**: 設定変更は原子的に適用され、ロールバック可能
4. **モジュラー設計**: 機能ごとに分離された設定で保守性が高い

## セットアップ方法

### dotfilesのシンボリックリンク作成

dotfilesの設定ファイル（`.gitconfig.local`含む）をシステムにリンクするには、以下のコマンドを実行します。

**macOS / Linux:**
```bash
./setup-dotfiles.sh
```

SSH/GPG鍵、トークン、ブラウザprofile、Orgデータ、API key、ユーザー名や絶対パスなどのマシン固有情報はコミットしません。

macOS/Linux用の`setup-dotfiles.sh`は以下をセットアップします：
- 各種設定ファイルのシンボリックリンク（Neovim、Tmux、Kitty、Yazi等。WezTermはmacOS/Linuxのみ対象）
- Git設定（`.gitconfig.local` - ghq root設定を含む）
- VSCode設定

リンク設定は `dotfiles-links.yaml` で管理されており、`XDG_CONFIG_HOME` が設定されている場合は優先使用します（未設定時は `~/.config`）。

### Home Manager（macOS / NixOS / WSL）

macOS・NixOS・WSLで、ユーザーレベルの設定（パッケージ、シェル設定など）を適用するには、以下のコマンドを実行します。

```bash
# Flakeの依存関係を更新（ロック更新のみ）
nix run .#update-lock

# macOS・NixOS・WSL に適用（実行環境を自動判定）
nix run .#switch

# その他のLinuxホストに適用
nix run nixpkgs#home-manager -- switch --flake .#ningen@$HOSTNAME
```

## ドキュメント

- [Secure Boot (lanzaboote) + Windows デュアルブート](docs/nix/secure-boot.md)
