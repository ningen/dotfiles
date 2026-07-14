# Windows 11 + Ubuntu WSL 2 + macOS 移行計画

更新日: 2026-07-14

## 実装進捗（2026-07-14）

Phase 1〜5のrepository側実装とPhase 0/4/6のrunbookを追加した。Linux上で
WSL Home Manager出力の評価・build、flake check、Unix setupのdry-runと
missing-source原子性を確認済み。Windows/WSL/macOS実機で行う項目、および
7日間の経過を必要とする項目は未完了のままとし、`docs/windows-wsl.md`へ
実行順と受け入れログを用意した。

## 目的

現在の NixOS デスクトップを Windows 11 ホストと Ubuntu WSL 2 に置き換える。移行後の役割は次のとおり。

- Windows 11 は GUI、IME、ブラウザ、ターミナル、VS Code、Docker Desktop を担当する。
- Ubuntu WSL 2 はシェル、エディタ、言語処理系、CLI、開発用ソースコードを担当する。
- macOS は既存の Home Manager と nix-darwin 構成を維持する。
- Unix 共通の CLI 設定は Home Manager で共有し、Windows ネイティブ設定は PowerShell と winget で管理する。
- Chrome の bookmarklet から Ubuntu WSL の Doom Emacs へ `org-protocol` URL を渡す。

移行完了までは NixOS 構成を残す。Windows + WSL を7日間連続で日常利用し、受け入れ条件をすべて満たした後に NixOS 固有構成を削除する。

## 固定する前提

| 項目 | 値 |
| --- | --- |
| Windows | Windows 11 x86_64 |
| WSL | WSL 2 / `Ubuntu-24.04` |
| WSL ユーザー | `ningen` |
| Home Manager 出力 | `ningen@wsl` |
| Windows checkout | `%USERPROFILE%\ghq\github.com\ningen\dotfiles` |
| WSL checkout | `~/ghq/github.com/ningen/dotfiles` |
| WSL 開発リポジトリ | `~/ghq` 以下 |
| Org データ | private repository `git@github.com:ningen/org.git` |
| Docker daemon / CLI | Docker Desktop WSL Integration |
| SSH / GPG agent | WSL 内で管理 |
| Emacs | WSLg GUI + `default` daemon |
| Chrome capture | リポジトリ管理の bookmarklet |

Windows checkout と WSL checkout は分離する。Windows アプリから `\\wsl$` 上の dotfiles へ恒常的にリンクしない。秘密鍵、トークン、ブラウザプロファイル、Windows Credential Manager、Docker 認証ファイル、Org データは dotfiles repository に含めない。

## 完成時の構成

```text
Windows 11
├── WezTerm / Windows Terminal
├── VS Code + WSL extension
├── Chrome / Windows IME
├── Docker Desktop
├── PowerShell 7 / winget / Git for Windows
├── JetBrainsMono Nerd Font
├── %USERPROFILE%\.wslconfig
└── org-protocol URL handler
         │
         └── wsl.exe -d Ubuntu-24.04 -u ningen
                         │
Ubuntu 24.04 WSL 2      │
├── Nix + Home Manager  │
├── zsh / starship / tmux
├── Git / gh / ghq
├── Neovim / Doom Emacs ◀┘
├── Node.js / Python / Go / language servers
├── Docker Desktop 提供の Docker CLI
├── ~/ghq 以下の開発リポジトリ
└── ~/org -> git@github.com:ningen/org.git

macOS
├── Home Manager / nix-darwin
├── Homebrew casks
├── 既存の org-protocol AppleScript handler
└── ~/org -> git@github.com:ningen/org.git
```

## 公開インターフェース

### Flake apps

- `nix run .#switch-wsl`: flake 内の Home Manager binaryで `ningen@wsl` を適用する。
- `nix run .#switch-macos`: macOS Home Managerを適用した後、nix-darwinを適用する。
- `nix run .#update-lock`: `nix flake update` だけを実行する。
- hostname 依存の `switch` と、lock更新後に設定まで適用する `update` は削除する。

通常の switch は `flake.lock` を変更しない。

### Windows 環境変数

Windows setup が次のユーザースコープ環境変数を設定する。

```powershell
[Environment]::SetEnvironmentVariable('DOTFILES_WSL_DISTRO', 'Ubuntu-24.04', 'User')
[Environment]::SetEnvironmentVariable('DOTFILES_WSL_USER', 'ningen', 'User')
```

WezTerm、Windows Terminal profile generator、org-protocol handlerはこの2値を参照する。未設定時はエラーで停止し、暗黙の既定 distro へ接続しない。

### Setup scripts

- `setup-dotfiles.sh --dry-run`: リンク対象、source の存在、既存targetの扱いを表示し、ファイルを変更しない。
- `setup-dotfiles.ps1 -DryRun`: Windows側で同じ検証を行い、symlink、環境変数、レジストリを変更しない。
- `setup-dotfiles.sh --config PATH` / `setup-dotfiles.ps1 -ConfigPath PATH`: defaultの`dotfiles-links.yaml`の代わりに検証用configを読む。
- source が1件でも存在しなければ、リンクを1件も変更せず非ゼロ終了する。
- 既存の非symlink targetは上書きせず、警告してskipする。
- Windows実適用前の環境変数、Git設定、managed fragment、`.wslconfig`所有状態は`%LOCALAPPDATA%\ningen-dotfiles\setup-state.json`へ記録する。secretは記録しない。
- setup stateのbaseline fieldは最初の実適用時だけ書き、installer/setupの再実行では上書きしない。Terminal original backupと`.wslconfig`の`createdBySetup`も初回値を保持する。

### org-protocol client

- WSL側の固定パスは `/home/ningen/.local/bin/org-protocol-client` とする。
- clientは `org-protocol://...` URLをちょうど1引数で受け取る。引数が0件または2件以上なら失敗する。
- `DOOMPROFILE=default` と daemon名 `default` を明示し、URLを `emacsclient` へ1引数のまま渡す。

## 管理対象

このrepositoryで次を管理する。

- Nix flake、Home Manager、nix-darwin
- WSL用Home Manager moduleと明示的なflake apps
- winget package installer
- PowerShell profile
- `.wslconfig` template
- WezTerm、Windows Terminal、VS CodeのWindows設定
- Windows用org-protocol handler、登録・解除script、bookmarklet生成元
- WSL用org-protocol client、clipboard wrapper、opener wrapper
- Windows、WSL、macOSのsetup・検証・rollback手順

次は管理しない。

- SSH/GPG秘密鍵とagent socket
- GitHub、AWS、Docker、Bitwardenのtoken
- Windows Credential Manager、ブラウザprofile、Docker認証ファイル
- WSLの`ext4.vhdx`
- `%APPDATA%` 全体やregistry全体のexport
- CPU、memory、swapのマシン固有値
- GPU、Bluetooth等のdriver
- `ningen/org` の内容

## 実装する構成

```text
nix/hosts/
├── common/home.nix
├── wsl/home.nix
├── ningen-mba/
└── nixos/                    # Phase 7までは保持

windows/
├── packages/install.ps1
├── powershell/Microsoft.PowerShell_profile.ps1
├── rollback.ps1
├── wsl/.wslconfig.example
├── terminal/profile.template.json
└── org-protocol/
    ├── bookmarklet.js
    ├── get-bookmarklet.ps1
    ├── invoke-wsl-emacs.ps1
    ├── register.ps1
    └── unregister.ps1

docs/windows-wsl.md
```

## Phase 0: バックアップと移行条件をそろえる

- [ ] 作業ツリーをcleanにし、現在のNixOS構成をpushする。
- [ ] 現在の`~/org`、`~/ghq`、SSH/GPG秘密鍵、ブラウザ、Bitwardenのバックアップを確認する。
- [ ] `ningen/org` がなければprivate repositoryとして作成し、現在の`~/org`を最初にpushする。
- [ ] 別の場所へcloneしてOrgファイルを読めることを確認する。
- [ ] BitLocker回復キーとWindows 11インストールメディアを確認する。
- [ ] 対象CPUがx86_64であることを確認する。異なる場合はこの計画を停止する。
- [ ] Windows Developer Modeを有効にする。
- [x] NixOSへ戻す手順とバックアップ場所を`docs/windows-wsl.md`へ記録する。

完了条件:

- NixOSへ戻せるcommitとバックアップがある。
- Org repositoryを別cloneから復元できる。
- Windows 11 x86_64を導入できる。

## Phase 1: WSL出力とモジュール境界を作る

- [x] `nix/hosts/wsl/home.nix` を追加する。
- [x] `homeConfigurations."ningen@wsl"` をx86_64-linuxとして追加する。
- [x] `switch-wsl`、`switch-macos`、`update-lock`を追加し、既存の`switch`と`update`を削除する。
- [x] `common/home.nix` をmacOS/WSL共通CLI設定に絞る。
- [x] GNOME dconfとdesktop Linux用font設定をNixOS moduleへ移す。
- [x] Doom Emacsのclone/sync activationはmacOSとWSLの両方で有効にする。
- [x] `home.username = "ningen"` と、Darwin/Linuxで分岐する`home.homeDirectory`は維持する。
- [x] Docker CLIとComposeを共有`dev-tools.nix`から分離し、macOS/NixOSだけに導入する。
- [x] WSL出力へNixOS home moduleとGUI package moduleをimportしない。
- [x] `ningen@DESKTOP-3TRFQRS` はrollback用としてPhase 7まで残す。

検証:

```bash
nix eval '.#homeConfigurations."ningen@wsl".activationPackage.drvPath'
nix build '.#homeConfigurations."ningen@wsl".activationPackage'
nix flake check
```

closureまたは設定評価を調べ、WSL出力にHyprland、NVIDIA、Steam、GNOME dconf、desktop Linux GUI、Nix版Docker CLIが含まれないことを確認する。

完了条件:

- hostnameに依存せずWSL出力をbuildできる。
- switchとlock更新が分離されている。
- WSL、macOS、desktop Linuxの責任範囲がmodule単位で分かれている。

## Phase 2: dotfiles配布をプラットフォーム別に分ける

`dotfiles-links.yaml` のsectionを次の責任に固定する。

| section | 適用先 | 内容 |
| --- | --- | --- |
| `unix_only` | macOS、WSL、desktop Linux | Git、Neovim、tmux、Doom、Helix、Yazi、Nix、agent skills |
| `desktop_linux_only` | desktop Linuxのみ | Kitty、Discord、Hyprland、wallpaper、illogical-impulse |
| `macos_only` | macOSのみ | macOS側WezTerm等 |
| `wsl_only` | WSLのみ | clipboard、opener等のWSL bridge |
| `windows_only` | Windowsのみ | PowerShell、WezTerm、org-protocol |
| `vscode` | Windows、macOS | VS Code User settingsとkeybindings |

- [x] 旧`common` sectionは削除し、すべてのlinkを上表の最も狭いsectionへ移す。
- [x] `setup-dotfiles.sh` は `/proc/sys/kernel/osrelease` の`microsoft`を優先し、次に`WSL_INTEROP`を調べてWSLを識別する。
- [x] WSLでは`unix_only`と`wsl_only`を処理し、`desktop_linux_only`と`vscode`を処理しない。
- [x] macOSでは`unix_only`、`macos_only`、`vscode`を処理する。
- [x] PowerShell setupは`windows_only`と`vscode`だけを処理し、`common`をWindowsへ配布しない。
- [x] sourceファイルを追加してからYAMLへ登録する。
- [x] 両setupへdry-runと全sourceの事前検証を追加する。
- [x] `.gitattributes` は`* text=auto eol=lf`を基本とし、PNG、JPEG、GIF、ICO、PDF、TTF、OTFを`binary`として列挙する。
- [x] 追跡中の空`.gitconfig.local`を`.gitconfig.local.example`へ変更し、実際の`.gitconfig.local`を`.gitignore`へ追加する。
- [x] Unix実適用はpreflightより前に、repository内の`.gitconfig.local`がなければexampleからcopyする。既存local fileは変更しない。
- [x] dry-runはlocal fileを作らず、copy予定として表示し、生成後のsourceが存在するものとしてpreflightを続ける。

検証:

```bash
bash -n setup-dotfiles.sh
./setup-dotfiles.sh --dry-run
```

WindowsではPowerShell parserと`-DryRun`を実行する。存在しないsourceを含む一時configを`--config`または`-ConfigPath`へ渡し、targetが1件も変更されず非ゼロ終了することを確認する。Phase 2では既存sourceの移動だけを登録し、Phase 5で追加するbridgeはsource作成後に登録する。

完了条件:

- 各platformへ対象外設定が配布されない。
- dry-runはrepositoryやhome directoryを変更しない。
- 既存の非symlinkは上書きされない。

## Phase 3: Windowsホスト設定を作る

`windows/packages/install.ps1` をwinget packageの唯一の定義元とし、次のIDを固定する。

```text
wez.wezterm
Microsoft.VisualStudioCode
Docker.DockerDesktop
Google.Chrome
Microsoft.PowerShell
Git.Git
Microsoft.WindowsTerminal
Obsidian.Obsidian
Discord.Discord
DEVCOM.JetBrainsMonoNerdFont
```

新規Windowsでは、標準搭載のWindows PowerShellとwingetでGitとPowerShell 7を先に導入し、Windows checkoutを作る。

```powershell
winget install --exact --id Git.Git --accept-package-agreements --accept-source-agreements
winget install --exact --id Microsoft.PowerShell --accept-package-agreements --accept-source-agreements
New-Item -ItemType Directory -Force "$env:USERPROFILE\ghq\github.com\ningen" | Out-Null
git clone https://github.com/ningen/dotfiles.git "$env:USERPROFILE\ghq\github.com\ningen\dotfiles"
Set-Location "$env:USERPROFILE\ghq\github.com\ningen\dotfiles"
```

- [ ] installerは`winget list --exact --id`で導入済みpackageをskipし、未導入packageを`winget install --exact --id`で入れる。
- [ ] source/package agreementを非対話で受諾し、失敗したpackage IDを一覧表示して非ゼロ終了する。
- [ ] Git for Windows導入後、変更前値をsetup stateへ保存してから`git config --global core.autocrlf false`を設定する。同梱のGit Credential Managerを維持し、WindowsへUnix用Git configをリンクしない。
- [ ] VS Code導入後に`ms-vscode-remote.remote-wsl` extensionを冪等導入する。
- [ ] WindowsのVS Code User settingsを配布し、WSL内の`~/.config/Code/User`は作らない。
- [ ] PowerShell profileにはWSL起動、Windows/WSL各checkoutの更新、各setupの補助関数だけを置く。
- [ ] Windows setupが`DOTFILES_WSL_DISTRO`と`DOTFILES_WSL_USER`をユーザースコープへ設定する。
- [ ] Windows setupは変更前の環境変数値と`core.autocrlf`をsetup stateへ保存する。値が未設定だった場合も`null`として記録する。
- [ ] WezTermは環境変数のdistro/userを使い、home directoryから起動する。
- [ ] Windows Terminal profileはtemplateから生成し、同じ環境変数を埋め込む。
- [ ] 生成先は`%LOCALAPPDATA%\Microsoft\Windows Terminal\Fragments\ningen\wsl.json`とする。同名fileがあればlocal state directoryへbackupしてsetup stateへ記録してから上書きする。Windows Terminalの`settings.json`と既存profileは変更しない。
- [ ] `.wslconfig.example` を次の内容で管理する。setupはtargetがない場合だけcopyし、作成した事実をsetup stateへ記録する。既存targetは変更せず、setup stateへ`createdBySetup = false`を記録する。

```ini
[wsl2]
networkingMode=mirrored
dnsTunneling=true
autoProxy=true

[experimental]
autoMemoryReclaim=gradual
```

CPU、memory、swapは設定しない。変更を反映するときは`wsl.exe --shutdown`を実行する。

Windows checkout作成後、次の順で適用する。

```powershell
pwsh -File .\windows\packages\install.ps1
pwsh -File .\setup-dotfiles.ps1 -DryRun
pwsh -File .\setup-dotfiles.ps1
```

完了条件:

- installerを2回実行しても重複導入やエラーが発生しない。
- WezTermとWindows Terminalが必ず`Ubuntu-24.04`の`ningen`を起動する。
- secretやlogin状態がrepositoryへ入っていない。

## Phase 4: Ubuntu 24.04 WSLを構築する

Windows PowerShellからdistroを導入する。

```powershell
wsl --install -d Ubuntu-24.04
```

- [ ] 初回起動でユーザー`ningen`を作る。
- [ ] ユーザー作成後、次のcommandでdistro、WSL version、ユーザーを確認する。

```powershell
wsl -l -v
wsl -d Ubuntu-24.04 -u ningen -- whoami
```

- [ ] `/etc/wsl.conf`へsystemdとdefault userを明示する。

```ini
[boot]
systemd=true

[user]
default=ningen
```

- [ ] `wsl.exe --shutdown`後、systemdとdefault userを確認する。
- [ ] Ubuntu packageを更新し、Gitとcurlをbootstrap用に導入する。
- [ ] 公式multi-user installerでNixを導入する。

```bash
sh <(curl -L https://nixos.org/nix/install) --daemon
```

- [ ] dotfilesを`~/ghq/github.com/ningen/dotfiles`へcloneする。
- [ ] 初回だけCLI flagでflakesと`nix-command`を有効化し、次を実行する。

```bash
cd ~/ghq/github.com/ningen/dotfiles
nix --extra-experimental-features 'nix-command flakes' run .#switch-wsl
```

- [ ] `setup-dotfiles.sh --dry-run`を確認してから実適用する。
- [ ] SSH鍵とGPG鍵をバックアップからWSL内へ復元し、permissionとagentを確認する。
- [ ] `gh auth login`をWSL内で行う。
- [ ] `ssh -T git@github.com`でSSH接続を確認してから`git@github.com:ningen/org.git`を`~/org`へcloneする。
- [ ] Windows側agentへのbridgeは作らない。

完了条件:

- `ningen@wsl`からHome Managerを再適用できる。
- zsh、starship、direnv、tmux、Git、gh、ghq、Neovim、Doom Emacs、Node.js、Python、Go、language serversを実行できる。
- ソースコードとOrgファイルが`/mnt/c`ではなくWSL filesystemにある。

## Phase 5: Docker、clipboard、opener、org-protocolを接続する

### Docker Desktop

- [ ] Docker DesktopのWSL 2 backendを有効にする。
- [ ] `Ubuntu-24.04`のWSL Integrationを有効にする。
- [ ] UbuntuへDocker EngineまたはNix版Docker CLIを導入しない。
- [ ] Linux filesystem上のprojectをbind mountし、file watchを確認する。

```bash
docker version
docker context ls
docker run --rm hello-world
docker compose version
```

Docker daemon、socket、contextが一系統だけであることを完了条件とする。

### Clipboardとopener

- [ ] WSLへ`win-copy`と`win-paste` wrapperを追加する。
- [ ] `win-copy`は`clip.exe`、`win-paste`は`powershell.exe -NoProfile -Command Get-Clipboard -Raw`を使う。
- [ ] Neovimの`g:clipboard`へwrapperを登録し、`:checkhealth clipboard`を成功させる。
- [ ] WSLg GUI EmacsはWSLg native clipboardを使う。
- [ ] YaziのURLはWindows browser、fileはWindows既定アプリ、directoryはExplorerへ渡す。
- [ ] file/directory pathは`wslpath -w`でWindows pathへ変換する。

日本語、複数行、末尾改行、空白を含むpathで往復確認する。

### org-protocol

- [ ] Home Managerで`~/.local/bin/org-protocol-client`を配置する。
- [ ] WSLではGUI対応の`pkgs.emacs`を導入し、WSLgからGUI frameを開けることを確認する。
- [ ] GUI起動commandを`DOOMPROFILE=default emacsclient --socket-name=default --create-frame`に固定し、独立した別Emacs serverを起動しない。
- [ ] clientは`DOOMPROFILE=default`を設定し、`emacsclient --socket-name=default --eval t`で接続を調べる。
- [ ] 接続できなければ`emacs --daemon=default`を起動する。
- [ ] daemon接続を500ms間隔、最大30秒でpollする。
- [ ] 接続後、`emacsclient --socket-name=default --no-wait "$url"`でURLを単一引数として渡す。
- [ ] Windows handlerもURLを単一引数として`wsl.exe`へ渡す。
- [ ] handlerは環境変数のdistro/userを使い、未設定時は停止する。
- [ ] `HKCU\Software\Classes\org-protocol`へ登録する`register.ps1`と、対象キーだけを消す`unregister.ps1`を追加する。
- [ ] timeoutまたは起動失敗時は非ゼロ終了し、Windows error dialogと診断logを出す。
- [ ] error dialogはPresentationFrameworkの`System.Windows.MessageBox`を使う。
- [ ] logは`%LOCALAPPDATA%\ningen-dotfiles\org-protocol.log`へ保存する。時刻、処理段階、終了codeだけを記録し、URL、title、selectionを保存しない。
- [ ] `bookmarklet.js`はtitle、URL、selectionをUTF-8でpercent encodeし、template `w`へ渡す。
- [ ] `get-bookmarklet.ps1`でChromeへ登録する`javascript:` URLを生成する。

次の3状態でcaptureを確認する。

1. WSL停止、Emacs停止
2. WSL起動、Emacs停止
3. WSL起動、`default` daemon起動済み

`&`、`%`、引用符、空白、日本語、選択テキストを含むcaptureが`~/org/links.org`へ1件だけ保存されることを完了条件とする。

## Phase 6: macOS回帰と7日間の日常利用を確認する

macOS実機で次を実行する。

```bash
nix build '.#homeConfigurations."ningen@ningen-mba.local".activationPackage'
nix build .#darwinConfigurations.ningen.system
bash -n setup-dotfiles.sh
./setup-dotfiles.sh --dry-run
```

- [ ] macOSのzsh、Doom Emacs、Git、Neovim、WezTerm、VS Code設定が残っている。
- [ ] macOSのorg-protocol AppleScript appを再生成し、captureできる。
- [ ] `~/org`が`ningen/org`を参照し、push/pullできる。
- [ ] macOS setupがWSL/Windows固有設定を配布しない。

その後、Windows + WSLを7日間連続で日常利用する。期間中に次をすべて実施する。

- [ ] Windows再起動と`wsl --update`後の再確認
- [ ] VS Code Remote WSLでWSL filesystem上のprojectを編集
- [ ] WezTerm、Windows Terminal、tmux、Neovim、WSLg Doom Emacsを利用
- [ ] Node.js、Python、Go projectを各1件build/test
- [ ] direnvとnix-direnvを利用
- [ ] Docker Composeとfile watchを利用
- [ ] VPN、localhost、IPv6、DNSを利用する実環境で確認
- [ ] org-protocol、clipboard、Yazi openerを日常操作で利用
- [ ] Windows/macOSの両方からOrg repositoryを更新し、競合時は通常のGit手順で解消
- [ ] WSLのdisk使用量、起動時間、memory reclaimを確認

7日間の途中で致命的な問題が発生した場合は日数をリセットし、修正後に1日目から再確認する。

## Phase 7: NixOS固有構成を削除する

Phase 6を完了した後だけ実行する。

```bash
git tag -a pre-windows-wsl-migration -m "Preserve the final NixOS configuration"
git push origin pre-windows-wsl-migration
```

tagをremoteで確認してから次を削除する。

- [ ] `nixosConfigurations.myNixOS`と`nixosConfigurations.nixos`
- [ ] `mkNixos`
- [ ] `nixos-hardware`と`xremap` input
- [ ] `ningen@DESKTOP-3TRFQRS`
- [ ] `nix/hosts/nixos`
- [ ] NixOS専用GUI package
- [ ] Hyprland、wallpaper、illogical-impulse設定
- [ ] NixOS専用link sectionとsetup処理

README、AGENTS.md、NixOS/Hyprland docsを実際の対応環境へ更新し、`flake.lock`から不要inputが消えたことを確認する。archive branchは作らず、annotated tagを旧構成の参照点とする。

完了条件:

- flakeとdocsがWindows 11 + Ubuntu WSL 2 + macOSだけを表す。
- WSLとmacOSのbuildが成功する。
- tagから最終NixOS構成を参照できる。

## 全体検証matrix

| 実行環境 | 検証 |
| --- | --- |
| x86_64 Linux / WSL | WSL Home Manager build、flake check、shell syntax、setup dry-run |
| macOS実機 | macOS Home Manager、nix-darwin build、AppleScript handler |
| Windows 11実機 | winget再実行、PowerShell parser、setup dry-run、symlink、registry |
| Windows + WSL | Docker、clipboard、opener、VS Code Remote WSL、org-protocol |

Darwin derivationのbuildをLinuxへ要求しない。registry変更、winget install、Home Manager switch、nix-darwin switchは対象実機でdry-runまたは差分確認後に実行する。

## ロールバック

### WSL / Home Manager

- Home Manager generationを前の世代へ切り替える。
- `ningen@wsl`追加前のcommitへ戻す。
- distroを破棄するときはOrgと開発repositoryのpushを確認してから`wsl --unregister Ubuntu-24.04`を実行する。

### Windows

- `windows/rollback.ps1`はsetup stateを読み、setupが作成したsymlinkだけを削除する。
- Terminal fragmentに変更前backupがあれば復元し、なければ`%LOCALAPPDATA%\Microsoft\Windows Terminal\Fragments\ningen\wsl.json`だけを削除する。Windows Terminalの`settings.json`は変更しない。
- org-protocolは`unregister.ps1`で対象HKCU keyだけを削除する。
- `DOTFILES_WSL_DISTRO`、`DOTFILES_WSL_USER`、`core.autocrlf`をsetup stateの変更前値へ戻す。変更前が`null`なら削除する。
- `.wslconfig`は`createdBySetup = true`の場合だけ削除する。既存fileには触れず、最後に`wsl.exe --shutdown`を実行する。
- Docker Desktopの`Ubuntu-24.04` WSL Integrationを無効にする。
- winget packageは自動uninstallしない。rollback scriptがPhase 3の管理対象package IDを全件表示し、`winget list --exact --id`の結果を見て利用者が個別に削除する。bootstrapで導入したGitとPowerShell 7もこの一覧に含める。

### NixOS

- Phase 7までは現在のNixOS commitとbackupを保持する。
- Phase 7後は`pre-windows-wsl-migration` tagから旧構成を参照または復元する。

## 最終受け入れ条件

- Windowsの必要アプリと設定をWindows checkoutから再適用できる。
- Ubuntu 24.04 WSLを`ningen@wsl`とWSL checkoutから再現できる。
- switchはhostname非依存で、`flake.lock`を自動更新しない。
- Windows、WSL、macOSへ対象外configを配布しない。
- macOS Home Managerとnix-darwinが引き続きbuildできる。
- WezTermとWindows Terminalが`Ubuntu-24.04`の`ningen`を起動する。
- VS Code Remote WSLでWSL filesystem上の開発ができる。
- WSLからDocker DesktopのdaemonとCLIだけを利用できる。
- Neovim、WSLg Emacs、Windows間で日本語clipboardが使える。
- YaziからWindows browser、既定アプリ、Explorerを開ける。
- Chrome bookmarkletからWSL Doom Emacsへcaptureできる。
- `ningen/org`をWSLとmacOSの両方から復元できる。
- SSH/GPG秘密鍵と認証情報がGitに含まれていない。
- 7日間の受け入れ運用を完了している。
- NixOS撤去後もannotated tagから旧構成を参照できる。
