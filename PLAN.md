# end-4/dots-hyprland Integration Plan

## Goal

NixOS + Hyprland 環境を `end-4/dots-hyprland` 風の Quickshell ベース UI に段階的に寄せる。

既存の Hyprland 設定を一気に置き換えず、Nix/Home Manager 管理のまま安全に試せる構成にする。

## Constraints

- `curl | bash` や upstream installer の直実行は避ける。
- 既存の `.config/hypr/hyprland.conf` は保持し、end-4 風の設定は分離して導入する。
- sudo が必要な apply/rebuild は Codex から直接実行しない。
- sudo が必要な作業は tmux 経由で実行し、ユーザーが裏で承認できる形にする。
- 複数セッションで再開できるよう、各段階で検証可能なチェックポイントを残す。

## Current State

- Nix flake:
  - `flake.nix` は `nixpkgs-unstable` を使用。
  - NixOS host は `nix/hosts/nixos/configuration.nix`。
  - Linux GUI Home Manager module は `nix/packages/gui.nix`。
- Hyprland:
  - 実設定は `.config/hypr/hyprland.conf`。
  - 現在の autostart は `fcitx5`, `end4-qs -c ii`。
  - `waybar`, `eww hypr-keymap`, `hyprshell` は end-4 Quickshell preview と競合するためコメントアウト中。
  - 現在の launcher は `rofi -show drun` のまま。end-4 overview/launcher への切り替え可否は実セッションで確認する。
- Packages:
  - `nix/packages/gui.nix` で `hyprland`, `xdg-desktop-portal-hyprland`, `quickshell`, `waybar`, `awww`, `eww`, `rofi`, `ghostty`, `playerctl` などを導入済み。
  - end-4 用に `end4-qs` wrapper, Qt/KDE QML runtime, `ddcutil`, `brightnessctl`, `libqalculate` などを追加済み。
  - `end-4/dots-hyprland` は fixed-output fetch で pin し、Home Manager から `~/.config/quickshell/ii` に配置する。
- NixOS services:
  - end-4 smoke test の警告解消用に `services.upower.enable = true;` を追加済み。
- Git:
  - 現在の未コミット差分は end-4 Quickshell preview の作業メモ更新と Material Symbols font 追加。

## Upstream Notes

- `end-4/dots-hyprland` は単なるテーマではなく、Quickshell ベースの custom graphical shell。
- README では Hyprland 0.55 以降への注意があるため、導入前にローカル Hyprland バージョンを確認する。
- upstream installer はシステムセットアップではなく dotfiles 配置が主目的だが、既存 dotfiles と衝突しやすいため直実行しない。

## Checkpoints

### 1. Prepare Nix Dependencies

- [x] `nix/packages/gui.nix` に Quickshell 系の依存を追加する。
- [x] 追加候補を `nix eval` または `nix search` で確認する。
- [x] 既存の `waybar` / `eww` はこの段階では残す。
- [x] `nix build .#homeConfigurations."ningen@nixos".activationPackage` で Home Manager build を確認する。

Expected result:

- Quickshell と周辺ツールが Nix profile に入る。
- 既存の Hyprland セッション挙動はまだ変えない。

### 2. Add Isolated Hyprland Include

- [x] `.config/hypr/end4-preview.conf` を追加する。
- [x] `.config/hypr/hyprland.conf` から `source = ~/.config/hypr/end4-preview.conf` で読み込む。
- [x] まずは見た目、animation、windowrule、launcher など低リスクな設定に限定する。
- [x] `exec-once` の切り替えはコメント付きで管理し、既存 UI と競合しないようにする。

Expected result:

- 既存 Hyprland config を壊さず、end-4 風の設定を分離して管理できる。

### 3. Quickshell Smoke Test

- [x] upstream `end-4/dots-hyprland` の構成を確認し、必要最小限の Quickshell 起動方法を特定する。
- [x] Quickshell 起動を `exec-once` へ直接固定せず、手動起動またはコメントアウトされた候補として追加する。
- [x] 必要なら tmux で非 sudo の確認コマンドを実行する。

Expected result:

- Quickshell がローカルで起動可能か、既存 Waybar/EWW とどこが競合するか判断できる。

### 4. Optional System Apply

- [x] Home Manager 適用が必要な場合は tmux session を作成する。
- [x] sudo が不要な場合は `nix run .#switch` または Home Manager switch を tmux 内で実行する。
- [x] sudo が必要な NixOS rebuild は tmux 内で `sudo nixos-rebuild switch --flake .#myNixOS` を実行し、ユーザーが裏で承認する。
- [x] `nix run .#update` は Linux では `nixos-rebuild` を実行しないため、NixOS system 反映は別コマンドで実行する。

Expected tmux commands:

```bash
tmux new-session -d -s dotfiles-switch 'nix run .#switch'
tmux attach -t dotfiles-switch
```

```bash
tmux new-session -d -s nixos-rebuild 'sudo nixos-rebuild switch --flake .#myNixOS'
tmux attach -t nixos-rebuild
```

### 5. Full end-4 Migration Decision

- [x] Waybar/EWW を残すか Quickshell に寄せるか決める。
- [x] `hyprshell` と end-4 overview/launcher の役割重複を確認する。
- [x] upstream dotfiles のうち取り込む対象を明確にする。
- [x] 必要なら submodule/vendor 配置、または手動移植のどちらにするか決める。

Expected result:

- 完全移行、部分移植、現状維持の判断ができる。

## Progress Log

### 2026-06-28

- [x] 現在の Nix/Hyprland 構成を確認。
- [x] `nix/packages/gui.nix` が GUI パッケージ管理の入口であることを確認。
- [x] `.config/hypr/hyprland.conf` が Hyprland の実設定であることを確認。
- [x] 現在は `waybar`, `eww`, `hyprshell` を autostart していることを確認。
- [x] `nixpkgs#quickshell` が現在の環境で評価できることを確認。
- [x] `PLAN.md` を作成。
- [x] `nix/packages/gui.nix` に `quickshell`, `hypridle`, `hyprlock`, `wallust`, `matugen`, `cliphist`, `swappy`, `hyprpicker`, `fuzzel`, `wlogout` を追加。
- [x] `swww` はこの nixpkgs では main program が `awww` と評価され、既存で `awww` 導入済みのため追加しない判断にした。
- [x] `nix build .#homeConfigurations."ningen@nixos".activationPackage` が成功。
- [x] `nixpkgs#hyprland.version` が `0.55.4` で、end-4 現行系の前提に合うことを確認。
- [x] `.config/hypr/end4-preview.conf` を追加し、既存 config の末尾から source するようにした。
- [x] Quickshell autostart はまだ有効化せず、コメント付き候補として残した。
- [x] preview include 追加後も `nix build .#homeConfigurations."ningen@nixos".activationPackage` が成功。
- [x] upstream Quickshell 起動は `qs -c $qsConfig` 形式で、ローカル `quickshell` パッケージが `qs` と `quickshell` の両方を提供することを確認。
- [x] `hypridle`, `hyprlock`, `fuzzel`, `wlogout` 追加後も `nix build .#homeConfigurations."ningen@nixos".activationPackage` が成功。
- [x] `nix run .#update` は Linux では Home Manager までで、`nixos-rebuild` は別途必要なことを確認。
- [x] `nix run .#update` と `sudo nixos-rebuild switch --flake .#myNixOS` 実行後に `.config/hypr/end4-preview.conf` の Hyprland config error を確認。
- [x] Hyprland 0.55 の公式 syntax に合わせて `layerrule` を `blur on, match:namespace ...` / `ignore_alpha ...` 形式へ修正。
- [x] terminal opacity rule を `opacity ... override, match:class ...` 形式へ修正。
- [x] 修正後に `nix build .#homeConfigurations."ningen@nixos".activationPackage` が成功。
- [x] `hyprctl reload config-only` / `hyprctl configerrors` は `Couldn't set socket timeout (2)` で、この shell からは live reload 確認できなかった。
- [x] upstream `end-4/dots-hyprland` の HEAD `c04b0bbc8143a2b2166c1f699f7583cb28ff78fe` を確認。
- [x] upstream Quickshell config root は `dots/.config/quickshell/ii`、entry point は `shell.qml` と確認。
- [x] upstream の autostart は `qs -c $qsConfig &` で、config 名 `ii` を使う場合は `qs -c ii` が候補。
- [x] upstream Nix support は `sdata/dist-nix/README.md` 上で WIP かつ NixOS 向けではないと明記されているため、installer や dist-nix を直接採用しない判断にした。
- [x] 手動 smoke test 手順を `docs/hyprland/end4-quickshell-smoke-test.md` に追加。
- [x] `waybar`, `eww hypr-keymap`, `hyprshell`, notification UI, wallpaper/color tooling が end-4 Quickshell と重複することを整理。
- [x] `qs` 直接起動では Qt/KDE QML runtime を拾えないため、`end4-qs` wrapper を Home Manager package として追加。
- [x] upstream Quickshell submodule `rounded-polygon-qmljs` を `/tmp/dots-hyprland-end4` で取得。
- [x] smoke test 中の不足に合わせて `qt5compat`, `qtpositioning`, `qtmultimedia`, `qtsensors`, `qtsvg`, `syntax-highlighting`, `kirigami`, `ddcutil`, `brightnessctl`, `libqalculate` を追加。
- [x] `services.upower.enable = true;` を NixOS config に追加。
- [x] `nix run .#switch` を tmux 経由で実行し、`end4-qs`, `ddcutil`, `brightnessctl`, `qalc` が profile に入ったことを確認。
- [x] `sudo nixos-rebuild switch --flake .#myNixOS` を tmux 経由で実行し、UPower DBus activation 警告が smoke test から消えたことを確認。
- [x] `timeout 15s end4-qs -p /tmp/dots-hyprland-end4/dots/.config/quickshell/ii/shell.qml` が `Configuration Loaded` まで到達。
- [x] `end-4/dots-hyprland` を fixed-output fetch し、Home Manager で `~/.config/quickshell/ii` に配置する方針にした。
- [x] Hyprland autostart を `end4-qs -c ii &` に寄せ、`waybar`, `eww hypr-keymap`, `hyprshell` はコメントアウト候補として残した。
- [x] `PLAN.md` の Current State を現在の `end4-qs -c ii` autostart 状態に更新。
- [x] sandbox 外で `timeout 15s end4-qs -c ii` を実行し、Home Manager 配置済み config でも `Configuration Loaded` まで到達することを確認。
- [x] sandbox 外の `hyprctl configerrors` は空で、Hyprland config error は出ていないことを確認。
- [x] 現時点では `qs` プロセスは常駐していないため、autostart の実確認は次回 Hyprland login/reload 後に行う。
- [x] end-4 UI で `expand_more`, `memory` などの Material Symbols 名が文字列として表示され、曜日周辺の表示が重なる問題を確認。
- [x] 原因は `Material Symbols Rounded` が fontconfig で JetBrainsMono に fallback していたこと。
- [x] `material-symbols` を Home Manager と NixOS system fonts に追加し、`fc-match 'Material Symbols Rounded'` が正しい font を返すことを確認。
- [x] `nix run .#switch` を実行し、既存 Quickshell instance を `quickshell kill -c ii --any-display` で終了後、`end4-qs -d -c ii` で再起動。
- [x] 再起動後の Quickshell は `Configuration Loaded` まで到達し、`hyprctl configerrors` は空。

## Next Action

end-4 Quickshell preview は `end4-qs -c ii` で autostart する段階まで進んだ。

次にやること:

1. 次回 Hyprland login/reload 後に `end4-qs -c ii` が実際に起動しているか確認する。
2. `expand_more`, `memory`, `ram` などが文字列ではなく Material Symbols icon として描画されているか確認する。
3. 起動している場合は bar, notification, overview/launcher, clipboard, wallpaper/color 周りの常用感を確認する。
4. 問題があれば `waybar` / `eww` / `hyprshell` のコメントアウトを一部戻す。
5. 常用できそうなら upstream config を pin 更新する運用にするか、必要部分だけ手動移植へ切り替えるか決める。

Immediate check commands from an active Hyprland session:

```bash
pgrep -a qs
hyprctl configerrors
end4-qs -c ii
```
