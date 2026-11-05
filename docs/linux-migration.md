# Windows から NixOS への移行

Windows を「LoL と Apex のためだけの箱」に縮小し、日常環境を NixOS に移すための手順。

## 方針

- 日常の開発・生活は NixOS 側で行う
- Windows はアンチチートの都合で Linux に移せないゲーム専用として残す
- ディスクは OS ごとに完全分離する（Windows = BX500、NixOS = NVMe）
- Home Manager の共通層（`nix/hosts/common/home.nix` と `nix/packages/*`）はそのまま流用する

## ゲームの振り分け

| ゲーム | 実行環境 | 理由 |
| --- | --- | --- |
| League of Legends | Windows | Vanguard が TPM 2.0 / Secure Boot / HVCI を要求 |
| Apex Legends | Windows | EA が EAC の Linux/Proton モードを有効化していない |
| Overwatch 2 | Linux | Proton で動作。Blizzard は Proton 利用を BAN 対象外と明言 |
| その他 | Linux | Steam + Proton、Epic は Heroic、Battle.net は Lutris/Bottles |

## ハードウェア

| 項目 | 内容 |
| --- | --- |
| CPU | Intel Core i5-12400F（iGPU なし） |
| GPU | NVIDIA GeForce RTX 3060 Ti |
| Motherboard | ASUS PRIME Z690-P D4（有線 LAN のみ、Wi-Fi なし） |
| Disk 0 | Crucial BX500 480GB (SATA) |
| Disk 1 | Samsung 970 EVO Plus 1TB (NVMe) |

iGPU がないため、インストーラ起動時から NVIDIA しか使えない。画面が真っ黒な場合は `nomodeset` を付ける。

## 目標のレイアウト

| ディスク | 内容 |
| --- | --- |
| BX500 480GB | Windows 11 + LoL + Apex |
| NVMe 1TB | NixOS（ESP 1GB + root 残り全部、swap は zram） |

Windows のライセンスはマザーボードに紐づくデジタルライセンスなので、再インストールしても追加購入は不要。

## 事前準備（WSL 側）

NVMe を消すと WSL ごと消えるため、先に退避する。

1. dotfiles リポジトリを push する
2. `~/ghq` 配下の他リポジトリに未 push のコミットがないか確認する

   ```bash
   for d in $(find ~/ghq -maxdepth 5 -name .git); do
     r=$(dirname "$d")
     echo "$r: dirty=$(git -C "$r" status --porcelain | wc -l) unpushed=$(git -C "$r" log --branches --not --remotes --oneline | wc -l)"
   done
   ```

## Windows 11 の再インストール

1. Windows 11 のインストール USB から起動する（Secure Boot は ON のままでよい）
2. 言語選択画面で `Shift + F10` を押してコマンドプロンプトを開く
3. `diskpart` で両方のディスクを消す

   ```
   list disk
   select disk 0
   clean
   select disk 1
   clean
   exit
   exit
   ```

   `list disk` のサイズ（480GB / 1000GB）を必ず確認してから `select` する。番号は環境によって変わる。

   NVMe を物理的に外す代わりにここで `clean` する。これにより Windows の ESP が BX500 に必ず作られる。

4. 画面を更新し、**480GB の未割り当て領域**を選んでインストールする
5. セットアップ後、ライセンス認証が自動で通ることを確認する
6. LoL と Apex をインストールして起動確認する

## NixOS のインストール

1. NixOS のインストール USB を作成する（Windows なら Rufus / Ventoy、macOS なら Etcher）
2. BIOS で **Secure Boot をオフ**にして USB から起動する
3. 有線 LAN を接続する（このマザーボードは Wi-Fi 非搭載）
4. NVMe に次のパーティションを作る

   | パーティション | サイズ | 形式 | ラベル |
   | --- | --- | --- | --- |
   | ESP | 1GB | FAT32 | `ESP` |
   | root | 残り全部 | ext4 | `nixos` |

   ラベルは [`nix/hosts/linux/hardware.nix`](../nix/hosts/linux/hardware.nix) の `fileSystems` と一致させる。

5. インストール後、初回だけホスト名を明示して適用する

   ```bash
   sudo nixos-rebuild switch --flake .#ningen-desktop
   ```

   ホスト名がまだ `nixos` のため `nix run .#switch` は使えない。2 回目以降は使える。

## dotfiles の適用

1. リポジトリを取得する

   ```bash
   ghq get ningen/dotfiles
   ```

2. 実機のハードウェア設定を生成して差し替える

   ```bash
   sudo nixos-generate-config --show-hardware-config > nix/hosts/linux/hardware.nix
   ```

3. 適用する

   ```bash
   nix run .#switch
   ```

4. 初回パスワードを変更する

   ```bash
   passwd
   ```

## Secure Boot（lanzaboote）

LoL の Vanguard が Secure Boot を要求するため、NixOS 側も Secure Boot に対応させる。

1. `flake.nix` に lanzaboote の input を追加する

   ```nix
   lanzaboote = {
     url = "github:nix-community/lanzaboote/v1.0.0";
     inputs.nixpkgs.follows = "nixpkgs";
   };
   ```

2. [`nix/hosts/linux/configuration.nix`](../nix/hosts/linux/configuration.nix) のコメントを外して有効化する

   ```nix
   boot.lanzaboote = {
     enable = true;
     pkiBundle = "/var/lib/sbctl";
   };
   boot.loader.systemd-boot.enable = lib.mkForce false;
   ```

3. 鍵を作成して登録する

   ```bash
   sudo sbctl create-keys
   sudo sbctl enroll-keys --microsoft   # Microsoft の鍵を残さないと Windows が起動しない
   sudo nixos-rebuild switch --flake .#ningen-desktop
   ```

4. BIOS で Secure Boot をオンに戻す
5. 動作確認する

   ```bash
   bootctl status      # Secure Boot: enabled
   nvidia-smi
   ```

6. Windows を起動し、LoL が起動することを確認する

## トラブルシューティング

| 症状 | 対処 |
| --- | --- |
| インストーラが黒画面 | 起動オプションに `nomodeset` を追加 |
| Secure Boot 有効時に NVIDIA が動かない | モジュール署名の問題。Secure Boot を切るか、モジュール署名を設定する |
| Windows が起動しない | BIOS のブートメニューで Windows Boot Manager を選ぶ |
| `nix run .#switch` が失敗する | ホスト名が `ningen-desktop` か確認する |
| LoL が起動しない | Secure Boot がオンか、TPM 2.0 が有効かを確認する |

## 参考

- [NixOS: Supported Platforms](https://nix.dev/manual/nix/latest/installation/supported-platforms.html)
- [Lanzaboote](https://wiki.nixos.org/wiki/Lanzaboote)
- [Vanguard Security Requirements](https://support.riotgames.com/en-us/riot/performance/vanguard-security-requirements/)
