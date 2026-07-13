# Windows + Ubuntu WSL + macOS 移行計画

更新日: 2026-07-14

## 目的

現在の NixOS デスクトップを Windows ホストと Ubuntu WSL 2 に置き換え、macOS と合わせて次の役割分担にする。

- Windows は GUI、IME、ブラウザ、ターミナル、Docker Desktop を担当する。
- Ubuntu WSL はシェル、エディタ、言語処理系、CLI、開発用ソースコードを担当する。
- macOS は現在の Home Manager と nix-darwin 構成を維持する。
- 共通の CLI 設定は Home Manager で共有し、Windows 固有設定は PowerShell と winget で管理する。
- Windows のブラウザから Ubuntu WSL の Emacsへ `org-protocol` URL を渡せるようにする。

移行完了までは現在の NixOS 設定をロールバック用に残す。Windows + WSL を日常利用できると確認してから、NixOS 固有の出力、input、ドキュメントを整理する。

## 決定事項

- WSL distro は Ubuntu WSL 2 を使う。
- WSL のユーザー名は `ningen` とする。
- Home Manager の WSL 出力名はホスト名に依存しない `ningen@wsl` とする。
- Windows ネイティブアプリと WSL の設定は混ぜない。
- 開発リポジトリは WSL の Linux ファイルシステム、原則として `~/ghq` 以下に置く。
- Windows 用 dotfiles は Windows 側の別 checkout から適用する。Windows アプリから `\\wsl$` 上の設定へ恒常的にリンクしない。
- Windows の秘密情報、資格情報、ブラウザプロファイル、SSH 秘密鍵は Git 管理しない。
- NixOS の Hyprland/end-4 設定は WSL に移植しない。

## 推奨する最終構成

```text
Windows host
├── WezTerm
├── VS Code
├── Chrome / browser extensions
├── Windows IME
├── Docker Desktop
├── PowerShell 7
├── winget
├── Nerd Font
├── %USERPROFILE%\.wslconfig
└── org-protocol URL handler
         │
         └── wsl.exe -d Ubuntu -u ningen
                         │
Ubuntu WSL 2             │
├── Nix + Home Manager   │
├── zsh / starship / tmux
├── Git / gh / ghq
├── Neovim / Doom Emacs ◀┘
├── Node.js / Python / Go / language servers
├── Docker CLI
└── ~/ghq 以下の開発リポジトリ

macOS
├── Home Manager
├── nix-darwin
├── Homebrew casks
└── 既存の macOS org-protocol handler
```

## 現状の問題

### Home Manager 出力がホスト名に依存している

`nix run .#switch` は `ningen@$HOSTNAME` を選んでいる。新しい Windows のコンピューター名、WSL の hostname、Ubuntu distro の設定が現在の `ningen@DESKTOP-3TRFQRS` と一致しないと適用できない。

### Linux と WSL の区別がない

現在は `pkgs.stdenv.isLinux` や `unix_only` により、通常のデスクトップ Linux と WSL が同じ扱いになる。フォント、dconf、Hyprland、wallpaper、illogical-impulse など、WSL に不要な設定が混ざる可能性がある。

### Windows 用リンク範囲が広すぎる

`setup-dotfiles.ps1` は `common` の全項目を Windows に適用する。現在の `common` には tmux、Doom Emacs、Nix、Kitty、Yazi などが含まれ、Windows ネイティブ側では使わない設定も多い。一方、`windows_only` は空になっている。

### Docker daemon の所有者が決まっていない

Home Manager は Docker CLI と Compose を導入するが、通常の Ubuntu WSL ではそれだけでは daemon が動かない。Docker Desktop の WSL Integration と WSL 内 Docker Engine を重複させない方針が必要になる。

### Windows/WSL 間の連携が不足している

- Neovim は `unnamedplus` を使うが、WSL 用 clipboard provider がない。
- Yazi は Linux で `xdg-open` を使うため、Windows アプリへ渡せない場合がある。
- Windows の `org-protocol` URL handler がない。
- Windows と WSL の GitHub、SSH、GPG 認証方針が未定義。
- WezTerm は既定 WSL distro を起動しており、接続先が固定されていない。

## 設定の責任範囲

### このリポジトリで管理するもの

- Nix flake、Home Manager、nix-darwin
- Ubuntu WSL 用 Home Manager モジュール
- Windows アプリの winget パッケージ一覧
- PowerShell profile
- `.wslconfig` の共通設定またはテンプレート
- WezTerm、VS Code、Windows Terminalを使う場合の設定
- `org-protocol` の PowerShell handler と登録スクリプト
- WSL 側の `org-protocol-client`
- clipboard、ファイルオープンなどの Windows/WSL bridge
- Windows、WSL、macOS それぞれのセットアップスクリプト
- セットアップ手順、手動確認項目、ロールバック手順

### このリポジトリで管理しないもの

- SSH 秘密鍵、GPG 秘密鍵
- GitHub、AWS、Docker、Bitwarden のトークン
- Windows Credential Manager の内容
- ブラウザプロファイルとログイン状態
- Docker の認証ファイル
- WSL の `ext4.vhdx`
- `%APPDATA%` 全体やレジストリ全体の export
- GPU、Bluetoothなどハードウェア固有ドライバー

## 予定するディレクトリ構成

既存構造を一度に変えず、必要なファイルから段階的に追加する。

```text
nix/hosts/
├── common/
│   ├── home.nix
│   └── zshrc.zsh
├── wsl/
│   └── home.nix
├── ningen-mba/
│   ├── home.nix
│   └── macos.nix
└── nixos/                 # 移行確認までは残す

windows/
├── packages/
│   └── winget.json        # または再現可能な install script
├── powershell/
│   └── Microsoft.PowerShell_profile.ps1
├── wsl/
│   └── .wslconfig
├── org-protocol/
│   ├── invoke-wsl-emacs.ps1
│   └── register.ps1
└── terminal/              # Windows Terminalを使う場合
    └── settings.json

docs/
└── windows-wsl.md
```

## 実施手順

### Phase 0: 移行前のバックアップと前提確認

- [ ] NixOS の最新コミットを push し、未コミット変更がないことを確認する。
- [ ] 必要なら `pre-windows-wsl-migration` タグまたは退避ブランチを作る。
- [ ] `~/ghq`、Org ファイル、SSH/GPG、ブラウザ、パスワード管理ツールなどのバックアップ先を確認する。
- [ ] BitLocker 回復キーと Windows インストールメディアを確認する。
- [ ] Windows の CPU アーキテクチャを確認する。ARM Windows の場合は flake に `aarch64-linux` を追加する。
- [ ] Windows で使う Ubuntu の正式な distro 名を `wsl.exe -l -v` で確認する。
- [ ] Windows のユーザー名と WSL のユーザー名 `ningen` を確認する。
- [ ] Docker は Windows の Docker Desktop + WSL Integration を使う方針で確定する。

完了条件:

- NixOS に戻せるバックアップがある。
- Windows と WSL のユーザー名、distro 名、CPU アーキテクチャが分かっている。

### Phase 1: flake に固定名の WSL 出力を追加する

- [ ] `nix/hosts/wsl/home.nix` を追加する。
- [ ] `flake.nix` に `homeConfigurations."ningen@wsl"` を追加する。
- [ ] 現在の `ningen@DESKTOP-3TRFQRS` は移行中だけ alias として残すか、利用箇所を確認してから削除する。
- [ ] `nix run .#switch` が `$HOSTNAME` に依存しないようにする。
- [ ] `switch-wsl`、`switch-macos` など、対象が明確な flake app を用意するか検討する。
- [ ] `nix run .#update` と設定適用を分離する。通常の switch で `flake.lock` を自動更新しないようにする。
- [ ] WSL モジュールへ共通 CLI、開発ツール、language servers、formatters、linters、node packages を読み込む。
- [ ] WSL モジュールへ `nix/hosts/nixos/home.nix` と `nix/packages/gui.nix` を読み込まない。

検証:

```bash
nix build '.#homeConfigurations."ningen@wsl".activationPackage'
nix eval '.#homeConfigurations."ningen@wsl".activationPackage.drvPath'
```

完了条件:

- hostname に関係なく WSL の Home Manager 出力を build できる。
- Hyprland、NVIDIA、Steam、デスクトップ Linux GUI が WSL 出力へ入っていない。

### Phase 2: 共通設定を役割ごとに分離する

- [ ] `nix/hosts/common/home.nix` を「全 Unix 環境で必要な CLI 設定」に絞る。
- [ ] GNOME dconf 設定をデスクトップ Linux 固有モジュールへ移す。
- [ ] Linux フォント設定を WSLg 用とデスクトップ Linux 用で分ける。
- [ ] `isLinux` だけで WSL 固有動作を決めないようにする。
- [ ] Doom Emacs の clone/sync activation を macOS と WSL の両方で使うか確認する。
- [ ] WSL で不要な GUI パッケージが共通 package module に混ざっていないか確認する。
- [ ] Docker CLI を共通の `dev-tools.nix` に残すか、WSL/Darwin モジュールへ分ける。
- [ ] `home.username` と `home.homeDirectory` の固定値をホスト引数にする必要があるか確認する。

完了条件:

- `common`、`wsl`、`darwin`、`desktop Linux` の責任範囲が明確になっている。
- WSL と macOS の Home Manager build が両方成功する。

### Phase 3: dotfiles の配布先を分離する

- [ ] `dotfiles-links.yaml` の `common` を本当に全環境共通の項目だけにする。
- [ ] `wsl_only` と `desktop_linux_only` を追加する。
- [ ] 既存の `unix_only` を macOS/WSL共通とデスクトップ Linux 固有に分ける。
- [ ] `windows_only` に PowerShell、`.wslconfig`、org-protocol、Windows terminal設定を追加する。
- [ ] VS Code は既存の `vscode` セクションを維持する。
- [ ] Neovim、tmux、Doom Emacs、Nix、Yazi、Codex/agent skills を WSL/macOS 側へ移す。
- [ ] WezTerm は Windows と macOS の両方へ正しいパスで配布する。
- [ ] `setup-dotfiles.sh` で WSL を `/proc` または環境変数から識別する。
- [ ] `setup-dotfiles.sh` が WSL へ Hyprland、wallpaper、illogical-impulse をリンクしないようにする。
- [ ] `setup-dotfiles.ps1` が Windows に tmux、Doom Emacs、Nix などをリンクしないようにする。
- [ ] Windows の Developer Mode 有効時は非管理者 symlink を許容し、管理者権限なしでも動く範囲を維持する。
- [ ] Windows ネイティブアプリ固有の config path を `%APPDATA%` 一括ではなく個別に確認する。

検証:

```bash
bash -n setup-dotfiles.sh
```

Windows では PowerShell の parser check またはテスト用ディレクトリへの dry-run を用意する。

完了条件:

- Windows、WSL、macOS の各セットアップで対象外設定が配布されない。
- 既存ファイルを破壊せず、既存の非 symlink は従来どおり skip する。

### Phase 4: Windows ホスト設定を追加する

- [ ] winget で管理するアプリ一覧を決める。
- [ ] WezTerm、VS Code、Docker Desktop、Chrome、PowerShell 7、Git for Windows、Nerd Font を一覧へ追加する。
- [ ] Windows Terminal、Obsidian、Discordなどを使う場合は一覧へ追加する。
- [ ] パッケージのインストール処理を再実行可能にする。
- [ ] PowerShell profile を追加し、WSL 起動や dotfiles 更新の補助関数だけを置く。
- [ ] `.wslconfig` を追加する。
- [ ] `.wslconfig` の memory、processors、swap はマシン依存値として local override またはテンプレートにする。
- [ ] Windows 11 を使う場合は mirrored networking、DNS tunneling、auto proxy の必要性を確認する。
- [ ] WezTerm の起動先を `wsl.exe -d Ubuntu -u ningen --cd ~` 相当へ固定する。
- [ ] Windows のフォントを Windows 側へインストールする。WSL の Nix font package だけに依存しない。
- [ ] Windows 用セットアップのうち、管理者権限が必要な処理を明記する。
- [ ] Docker Desktop の WSL Integration は自動化できない場合、手動チェックリストにする。

完了条件:

- 新規 Windows 環境で必要なホストアプリと設定をこのリポジトリから復元できる。
- secret やログイン状態をリポジトリへ保存していない。

### Phase 5: Ubuntu WSL を構築する

- [ ] Windows へ WSL 2 と Ubuntu をインストールする。
- [ ] Ubuntu の既定ユーザーを `ningen` にする。
- [ ] WSL と Ubuntu を最新状態にする。
- [ ] systemd が有効か確認し、必要な場合だけ `/etc/wsl.conf` で有効化する。
- [ ] Nix を Ubuntu WSL にインストールする。
- [ ] flakes と nix-command を有効化する。
- [ ] dotfiles を `~/ghq/github.com/ningen/dotfiles` へ clone する。
- [ ] `home-manager switch --flake .#ningen@wsl` を実行する。
- [ ] `setup-dotfiles.sh` の WSL 対象だけを適用する。
- [ ] zsh、starship、direnv、tmux、Git、gh、ghq を確認する。
- [ ] Neovim、Doom Emacs、Node.js、Python、Go、language servers を確認する。
- [ ] `gh auth login` は WSL 内で実行し、Windows の資格情報へ暗黙依存しない。
- [ ] SSH agent と GPG agent を WSL 内で完結させるか、Windows と bridge するか決めて文書化する。
- [ ] Windows checkout と WSL checkout で改行コードや executable bit が不要に変わらないよう、Git の `core.autocrlf` と `.gitattributes` 方針を確認する。

完了条件:

- 新しい WSL shell で開発ツールが利用できる。
- Home Manager を固定名の出力から再適用できる。
- ソースコードが `/mnt/c` ではなく WSL ファイルシステムにある。

### Phase 6: Docker Desktop と WSL を連携する

- [ ] Windows に Docker Desktop をインストールする。
- [ ] WSL 2 backend を有効にする。
- [ ] Ubuntu distro の WSL Integration を有効にする。
- [ ] Ubuntu 内に独立した Docker Engine daemon を重複インストールしない。
- [ ] Home Manager の Docker CLI が Docker Desktop の socket/context を利用できるか確認する。
- [ ] CLI の競合があれば、Nix 版 Docker CLIを外して Docker Desktop 提供の連携を使うか判断する。
- [ ] Linux ファイルシステム上のプロジェクトを bind mount して動作とファイル監視を確認する。

検証:

```bash
docker version
docker context ls
docker run --rm hello-world
docker compose version
```

完了条件:

- WSL から Docker Desktop の daemon を一意に利用できる。
- Docker Engine、socket、context が重複していない。

### Phase 7: Windows/WSL の clipboard と opener を連携する

- [ ] Neovim の clipboard provider を決める。
- [ ] WSL Emacs と Windows clipboard の連携方法も決める。
- [ ] `win32yank.exe`、`clip.exe`/PowerShell bridge、WSLg Wayland clipboard の候補を比較する。
- [ ] `:checkhealth clipboard` が成功する設定を WSL module に追加する。
- [ ] Yazi の WSL opener を Windows 側の既定アプリへ渡す wrapper に変更する。
- [ ] Windows path と Linux path の変換が必要な操作で `wslpath` を使う。
- [ ] URL は Windows browser、ローカルファイルは用途に応じて Explorer または WSLg アプリへ渡す。
- [ ] `explorer.exe .` または専用 wrapper で WSL のカレントディレクトリを Windows Explorer から開けるようにする。

完了条件:

- Neovim と Windows 間でコピー/ペーストできる。
- Yazi から Windows のブラウザ、Explorer、既定アプリを開ける。

### Phase 8: Windows の org-protocol から WSL Emacsへ接続する

- [ ] WSL 側に安定したパスの `org-protocol-client` を作る。
- [ ] handler で `DOOMPROFILE=default` を明示する。
- [ ] Emacs server が起動済みか確認する。
- [ ] server がなければ `emacs --daemon` を起動し、接続可能になるまで短時間待つ。
- [ ] server 起動失敗や timeout を Windows 側へ分かる形で返し、必要最小限の診断ログを保存する。
- [ ] `emacsclient --no-wait` へ受け取った URL を単一引数として渡す。
- [ ] Windows 側に `invoke-wsl-emacs.ps1` を追加する。
- [ ] `wsl.exe --distribution Ubuntu --user ningen --exec ...` で distro とユーザーを固定する。
- [ ] URL 全体を安全に一引数として渡し、`&`、`%`、引用符、空白を壊さないようにする。
- [ ] `HKCU\Software\Classes\org-protocol` へ URL protocol を登録する PowerShell script を追加する。
- [ ] レジストリ登録はユーザースコープに限定し、管理者権限を不要にする。
- [ ] 登録解除スクリプトまたは rollback 処理を用意する。
- [ ] ブラウザ拡張の capture URL と Doom Emacs の template key `w` を合わせる。
- [ ] WSL が停止している状態、Emacs server が停止している状態、起動済み状態をそれぞれテストする。
- [ ] URL、タイトル、日本語、選択テキストが正しく保存されることを確認する。
- [ ] macOS の既存 AppleScript handler が引き続き動くことを確認する。

想定する呼び出し経路:

```text
Browser
  -> org-protocol://capture?template=w&url=...&title=...
  -> HKCU URL handler
  -> PowerShell wrapper
  -> wsl.exe -d Ubuntu -u ningen
  -> /home/ningen/.local/bin/org-protocol-client
  -> emacsclient
  -> Doom Emacs org-capture
```

完了条件:

- Windows browser から WSL の Org ファイルへ capture できる。
- WSL と Emacs が停止していても、初回 capture が失敗せず処理される。
- URL handler の削除手順がある。

### Phase 9: macOS の回帰確認

- [ ] WSL 分離後も `aarch64-darwin` の Home Manager 出力が評価できる。
- [ ] nix-darwin の system build が成功する。
- [ ] Homebrew casks と macOS 固有設定が WSL/Windows変更の影響を受けていない。
- [ ] macOS の `org-protocol` AppleScript app を再生成できる。
- [ ] 共通設定から移動した zsh、Doom Emacs、Git、Neovim 設定が macOS に残っている。
- [ ] `setup-dotfiles.sh` が macOS に WSL/Windows 固有設定をリンクしない。

検証:

```bash
nix build '.#homeConfigurations."ningen@ningen-mba.local".activationPackage'
nix build .#darwinConfigurations.ningen.system
bash -n setup-dotfiles.sh
```

実際の switch や `sudo darwin-rebuild` は macOS 実機で明示的に実行する。

完了条件:

- Windows/WSL 対応を追加しても macOS の既存環境が変わらない。

### Phase 10: ドキュメントと日常運用を整える

- [ ] README の対応環境を Windows host + Ubuntu WSL + macOS に更新する。
- [ ] `docs/windows-wsl.md` に初回セットアップ手順を書く。
- [ ] Windows clone と WSL clone の配置方針を書く。
- [ ] Windows の setup、WSL の Home Manager switch、macOS の switch を別コマンドとして記載する。
- [ ] `.wslconfig` 変更後の `wsl.exe --shutdown` を記載する。
- [ ] Docker Desktop の手動設定項目を書く。
- [ ] GitHub、SSH、GPG の認証方針を書く。
- [ ] org-protocol の登録、確認、解除方法を書く。
- [ ] トラブルシューティングとして hostname、clipboard、DNS、Docker context、Emacs server を扱う。
- [ ] `nix flake update` と通常の設定適用を分離した運用を書く。

完了条件:

- クリーンな Windows + Ubuntu WSL から README と docs だけで環境を復元できる。

### Phase 11: 日常利用テスト

- [ ] Windows + WSL を最低数日間、実際の開発に使う。
- [ ] VS Code Remote WSL で WSL filesystem 上のプロジェクトを開く。
- [ ] WezTerm、tmux、Neovim、Doom Emacs の起動を確認する。
- [ ] Node.js、Python、Go プロジェクトをそれぞれ build/test する。
- [ ] direnv と nix-direnv を確認する。
- [ ] Docker Compose とファイル監視を確認する。
- [ ] VPN、社内ネットワーク、localhost、IPv6 が必要な場合の通信を確認する。
- [ ] WSL のメモリ回収、ディスク使用量、起動時間を確認する。
- [ ] Windows Update、WSL update、再起動後も設定が維持されることを確認する。
- [ ] org-protocol、clipboard、opener を日常操作で確認する。

完了条件:

- NixOS に戻らず、日常の開発と Org capture を完了できる。
- 致命的な性能、ネットワーク、認証、GUI連携の問題がない。

### Phase 12: NixOS 固有構成を整理する

この Phase は Windows + WSL の日常利用テスト完了後に実施する。

- [ ] `nixosConfigurations.myNixOS` と `nixosConfigurations.nixos` を削除するか archive 方針を決める。
- [ ] `mkNixos` を削除する。
- [ ] 不要になった `nixos-hardware` と `xremap` input を削除する。
- [ ] `nix/hosts/nixos` を削除するか archive branch のみに残す。
- [ ] `nix/packages/gui.nix` の Hyprland/end-4 package 群を削除する。
- [ ] `.config/hypr`、wallpaper、illogical-impulse を削除するか archive する。
- [ ] `docs/hyprland` と `docs/nix/nixos.md` を削除、または過去構成として明記する。
- [ ] README と AGENTS.md の NixOS コマンド、ホスト一覧、アーキテクチャ説明を更新する。
- [ ] flake.lock から不要 input が消えたことを確認する。
- [ ] NixOS 用 symlink section と setup 処理を整理する。

完了条件:

- flake とドキュメントが実際に使う Windows + WSL + macOS のみを表している。
- NixOS 固有 input の更新失敗が日常の flake check に影響しない。
- 必要なら Git tag/branch から旧 NixOS 構成を参照できる。

## 全体検証

実装中は変更範囲に応じて狭い check から実行する。

```bash
# Nix syntax / outputs
nix flake check

# WSL Home Manager
nix build '.#homeConfigurations."ningen@wsl".activationPackage'

# macOS Home Manager
nix build '.#homeConfigurations."ningen@ningen-mba.local".activationPackage'

# nix-darwin
nix build .#darwinConfigurations.ningen.system

# shell script
bash -n setup-dotfiles.sh
```

Windows PowerShell は Windows 実機で次を確認する。

```powershell
$ErrorActionPreference = 'Stop'
.\setup-dotfiles.ps1
wsl.exe -l -v
wsl.exe -d Ubuntu -u ningen -- echo ok
```

適用を伴う `home-manager switch`、`nix run .#update`、`darwin-rebuild`、レジストリ変更、winget install は、対応する実機で内容を確認してから実行する。

## ロールバック

### WSL Home Manager

- Home Manager generation を切り替える。
- `ningen@wsl` の追加前コミットへ戻す。
- WSL distro 自体に問題がある場合は export/import または再作成する。

### Windows dotfiles

- `setup-dotfiles.ps1` が作成した symlink だけを削除する。
- 既存の非 symlink ファイルは setup 時に上書きしない。
- org-protocol は登録解除スクリプトで `HKCU\Software\Classes\org-protocol` の対象キーだけを削除する。
- `.wslconfig` を退避して `wsl.exe --shutdown` する。

### Docker

- Docker Desktop の Ubuntu WSL Integration を無効にする。
- WSL 内で独立 daemon を導入していないことを確認する。

### NixOS

- 移行完了までは現行 NixOS の commit/tag とバックアップを保持する。
- NixOS 固有ファイルを削除する Phase 12 は、Windows + WSL の受け入れ条件を満たした後に行う。

## 最終受け入れ条件

- Windows の再セットアップに必要なアプリ一覧と設定がリポジトリにある。
- Ubuntu WSL を `ningen@wsl` から再現できる。
- Windows と WSL の設定が互いの不要な config を配布しない。
- macOS の Home Manager と nix-darwin が引き続き build できる。
- WezTerm から必ず Ubuntu/ningen を起動できる。
- VS Code Remote WSL で WSL filesystem 上の開発ができる。
- Docker Desktop を Ubuntu WSL から利用できる。
- Neovim と Windows 間で clipboard が使える。
- Yazi/CLI から Windows のブラウザと Explorer を開ける。
- Windows browser の org-protocol から WSL Doom Emacsへ capture できる。
- secret、秘密鍵、認証情報が Git に含まれていない。
- NixOS を撤去した後も旧構成を Git 履歴または archive tag から参照できる。

## 最初に着手する項目

1. `ningen@wsl` と `nix/hosts/wsl/home.nix` を追加する。
2. `common`、`wsl`、`windows`、`desktop Linux` の境界を整理する。
3. `dotfiles-links.yaml` と setup script に WSL 判定を追加する。
4. Windows package/setup と `.wslconfig` の管理方法を追加する。
5. clipboard、opener、org-protocol bridge を実装する。
6. Ubuntu WSL 実機で適用し、macOS を回帰確認する。
7. 数日間の運用後に NixOS 固有構成を整理する。
