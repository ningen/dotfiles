# Dotfiles

このリポジトリは、私の個人的な設定ファイル（dotfiles）を [Nix](https://nixos.org/) と [Home Manager](https://github.com/nix-community/home-manager) を使って宣言的に管理するものです。Nix Flakesを活用し、macOSとLinux (NixOS) 環境間で再現性のある環境構築を実現しています。

## アーキテクチャ概要

このdotfilesリポジトリは、Nix Flakesをベースとしたモジュラー構成で、以下の主要コンポーネントから構成されています：

- **Flake-based管理**: 全体の依存関係とビルド定義
- **マルチプラットフォーム対応**: macOS (nix-darwin) とLinux (NixOS) の両方をサポート
- **モジュラー設計**: ホスト固有とパッケージ群に分離された設定

## ディレクトリ構成

```
dotfiles/
├── flake.nix                    # メインのFlake設定ファイル
├── flake.lock                   # Flakeの依存関係ロックファイル
├── hardware-configuration.nix   # ハードウェア固有の設定
├── dotfiles-links.yaml         # シンボリックリンク設定
├── setup-dotfiles.sh           # セットアップスクリプト (macOS/Linux)
├── setup-dotfiles.ps1          # セットアップスクリプト (Windows)
├── nix/
│   ├── hosts/                   # ホスト別設定
│   │   ├── common/             # 全ホスト共通設定
│   │   │   └── home.nix        # Home Manager基本設定
│   │   ├── ningen-mba/         # MacBook Air設定
│   │   │   └── macos.nix       # macOS固有設定
│   │   └── nixos/              # NixOS設定
│   │       ├── configuration.nix # システム設定
│   │       └── gui.nix         # GUI アプリケーション
│   ├── packages/               # パッケージ群定義
│   │   ├── dev-tools.nix       # 開発ツール
│   │   ├── formatters.nix      # コードフォーマッター
│   │   ├── language-servers.nix # LSP サーバー
│   │   └── node-packages.nix   # Node.js パッケージ
│   └── node2nix/               # Node.js依存関係管理
│       ├── default.nix         # node2nix設定
│       ├── node-env.nix        # Node環境
│       ├── node-packages.json  # NPMパッケージリスト
│       └── node-packages.nix   # 生成されたNix設定
```

## 主要な依存関係

### Flake Inputs

- **nixpkgs**: NixOSパッケージ集合（unstableブランチ）
- **home-manager**: ユーザー環境管理
- **nix-darwin**: macOS向けNix設定管理
- **nixos-hardware**: ハードウェア固有の最適化
- **xremap**: キーマッピング設定
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

**NixOS:**
- Hyprland (Wayland コンポジター)
- NVIDIA ドライバー設定
- 日本語入力 (Fcitx5 + Mozc)
- ゲーミング環境 (Steam, GameMode)

## サポートシステム

- **aarch64-darwin**: Apple Silicon Mac
- **x86_64-linux**: Intel/AMD Linux
- **Windows 11 + WSL 2**: Windowsネイティブアプリと設定はPowerShell/winget、CLI環境はWSL内のNix/Home Managerで管理

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

**Windows (PowerShell 7):**

前提はWindows 11、winget、Git、PowerShell 7、および初期ユーザー設定済みのWSL distributionです。Windows側とWSL側の両方にこのリポジトリをcloneしてから、Windows cloneで実行します。WSLをまだ導入していない場合は先に[`docs/windows-wsl.md`](docs/windows-wsl.md)のmanual WSL bootstrapを実施してください。

```powershell
pwsh -NoProfile -File .\windows\bootstrap.ps1 -DryRun
pwsh -NoProfile -File .\windows\bootstrap.ps1
```

スクリプトは自身の場所からリポジトリルートを解決するため、clone先は任意です。`-DryRun` はパッケージ、バックアップ、リンク、レジストリ操作の予定を表示し、設定ファイルを変更しません。未指定のWSLユーザーを検出する際はdistributionが起動する場合があります。通常実行は不足パッケージだけを導入し、導入済みバージョンを保持します。明示的に更新する場合は `-Upgrade` を付けます。

```powershell
pwsh -NoProfile -File .\windows\bootstrap.ps1 -Upgrade
```

Windows側の管理対象は次のとおりです。

- winget: WezTerm、VS Code、Docker Desktop、Chrome、PowerShell 7、Git、Windows Terminal、Obsidian、Discord、PowerToys、JetBrains Mono Nerd Font、GlazeWM、YASB Reborn
- シンボリックリンク: WezTerm、GlazeWM、PowerShell profile、VS Code settings/keybindings
- その他: Windows TerminalのWSL profile fragment、WSL Emacsショートカット、current-userの`org-protocol`登録

Oh My PoshはWSL側のStarshipと役割が重複するため導入しません。YASBの設定はv2のfirst-run wizardが生成するため、秘密情報やマシン固有値を含み得る設定をこのリポジトリから上書きしません。

リンク先が既に正しければ`NOOP`になります。通常ファイル、ディレクトリ、別のリンクがある場合は削除せず、`%LOCALAPPDATA%\ningen-dotfiles\backups\<UTC timestamp>`へ移動してからリンクを作成します。WindowsのDeveloper Modeが有効なら通常ユーザーで作成できます。Developer Modeを有効にしない場合だけ管理者PowerShellが必要です。スクリプト自身はDeveloper Modeの変更、再起動、ログアウトを行いません。

リンク作成が途中で失敗しても元データは表示されたbackup先に残ります。必要なら作成途中のリンクを確認して手動で退避し、backupを元のパスへ戻してから再実行してください。スクリプトは未知の既存ファイルを自動削除しません。

再実行は同じコマンドで安全です。パッケージとリンクの個別実行もできます。

```powershell
pwsh -NoProfile -File .\windows\packages\install.ps1 -DryRun
pwsh -NoProfile -File .\setup-dotfiles.ps1 -DryRun
```

SSH/GPG鍵、トークン、ブラウザprofile、Orgデータ、API key、ユーザー名や絶対パスなどのマシン固有情報はコミットしません。詳しいWindows/WSLの責務分離と検証手順は[`docs/windows-wsl.md`](docs/windows-wsl.md)を参照してください。

macOS/Linux用の`setup-dotfiles.sh`は以下をセットアップします：
- 各種設定ファイルのシンボリックリンク（Neovim、Tmux、Wezterm等）
- Git設定（`.gitconfig.local` - ghq root設定を含む）
- VSCode設定

リンク設定は `dotfiles-links.yaml` で管理されており、以下の環境変数に対応しています：
- `XDG_CONFIG_HOME`: 設定されている場合は優先使用
- 未設定時の OS デフォルト:
  - macOS/Linux: `~/.config`
  - Windows: `$APPDATA` (通常 `C:\Users\<username>\AppData\Roaming`)

### NixOSの場合

NixOSマシンでシステム全体の設定を適用するには、以下のコマンドを実行します。

```bash
sudo nixos-rebuild switch --flake .#myNixOS
```

### Home Manager（macOS / Linux）

NixOS、macOS、またはその他のLinuxディストリビューションで、ユーザーレベルの設定（パッケージ、シェル設定など）を適用するには、以下のコマンドを実行します。

```bash
nix run .#update
```

このコマンドは、flakeの依存関係を更新し、現在のホスト名に応じた適切なHome Managerプロファイルを適用します。
