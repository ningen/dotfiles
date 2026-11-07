# Secure Boot (lanzaboote) + Windows デュアルブート手順

最終更新: 2026-11-07
対象: `ningen-desktop` (NixOS)
Windows: 別ディスク `sda` にインストール済み

## 現状

- Secure Boot: 無効
- BitLocker / デバイス暗号化: OFF
- Linux: `nvme0n1p1` (ESP, `/boot`) + `nvme0n1p2` (ext4, `/`)
- Windows: `sda1` (ESP), `sda2` (MSR), `sda3` (C:), `sda4` (Recovery)
- Windows Boot Manager は `sda1` を指す EFI エントリとして再作成済み
- Linux ESP の空き: 約967MB

## 方針

- 通常の起動は NixOS を優先する
- Windows はファームウェアの一時ブートメニュー (F11/F12) から起動する
- lanzaboote は別ディスクの Windows をブートメニューに追加できない
- Microsoft 鍵は残す (`sbctl enroll-keys --microsoft`)。Windows は Microsoft 署名のまま起動できる
- 1つのブートメニューに NixOS と Windows をまとめたい場合は Limine を検討する（この手順では扱わない）

## 重要な順序

**必ず lanzaboote を導入して署名済みの UKI を用意してから、鍵を enroll する。**

Secure Boot が Setup Mode で「Enabled」になっている場合、鍵を enroll した時点で
User Mode に移行し、次回起動から Secure Boot が有効になる。このとき署名済みの
ブートローダー/UKI が無いと NixOS が起動できない。鍵作成 → lanzaboote 導入 →
署名確認 → Setup Mode → enroll の順で進める。

## 手順

### 0. 前提確認

```bash
bootctl status | sed -n '1,12p'
```

Secure Boot が `disabled`、BitLocker が OFF であることを確認する。

### 1. Windows Boot Manager エントリの再作成

Secure Boot が無効なうちに、Windows の EFI エントリを作成する。

```bash
sudo mkdir -p /mnt/winesp
sudo mount -o ro /dev/sda1 /mnt/winesp
ls -l /mnt/winesp/EFI/Microsoft/Boot/bootmgfw.efi
sudo umount /mnt/winesp
```

`bootmgfw.efi` がある場合:

```bash
nix shell nixpkgs#efibootmgr -c sudo efibootmgr --create \
  --disk /dev/sda --part 1 \
  --label "Windows Boot Manager" \
  --loader '\EFI\Microsoft\Boot\bootmgfw.efi'

nix shell nixpkgs#efibootmgr -c sudo efibootmgr -v
```

再起動し、F11/F12 または BIOS の Boot Override から Windows が起動することを確認する。
この手順は完了済み。

### 2. sbctl の鍵を作成

```bash
nix shell nixpkgs#sbctl -c sudo sbctl create-keys
nix shell nixpkgs#sbctl -c sudo sbctl status
```

鍵は `/var/lib/sbctl` に作成される。

### 3. lanzaboote を導入して署名済み UKI を用意

`flake.nix`:

```nix
lanzaboote = {
  url = "github:nix-community/lanzaboote/v1.2.0";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

`nix/hosts/linux/configuration.nix`:

```nix
boot.loader.systemd-boot.enable = lib.mkForce false;
boot.loader.efi.canTouchEfiVariables = true;
boot.lanzaboote = {
  enable = true;
  pkiBundle = "/var/lib/sbctl";
  configurationLimit = 5;
};
environment.systemPackages = [ pkgs.sbctl ];
```

ビルドと適用:

```bash
nix run .#switch

# 署名確認
sudo sbctl verify
```

`/boot/EFI/Linux/*.efi` と lanzaboote のブートローダーが署名済みになっていることを確認する。
この時点では Secure Boot はまだ無効/Setup Mode なので、未署名でも起動できる。

### 4. BIOS で Setup Mode に入る

BIOS は Del キー、または Linux から以下で直接開ける。

```bash
sudo systemctl reboot --firmware-setup
```

BIOS での操作:

1. Security（または Boot）→ Secure Boot を開く
2. 可能なら Secure Boot Mode を **Custom** にする
3. Secure Boot を **Enabled** にする
4. Key Management → **Reset to Setup Mode**（または **Delete PK**）を選ぶ
5. F10 で保存して再起動

注意:

- **Clear All Secure Boot Keys は選ばない**（dbx まで消える）
- **Restore Factory Keys は選ばない**（sbctl の鍵が消える）
- `Reset to Setup Mode` が無く `Delete PK` だけなら `Delete PK` を使う
- `Clear All Secure Boot Keys` しか選択肢が無い場合は、実行せずに相談する

### 5. 鍵を登録する

Setup Mode になっていることを確認する。

```bash
sudo sbctl status
# Setup Mode: Enabled を確認
```

`File is immutable` が出た場合:

```bash
sudo chattr -i /sys/firmware/efi/efivars/KEK-* /sys/firmware/efi/efivars/db-*
```

`chattr` が無い場合:

```bash
nix shell nixpkgs#e2fsprogs -c sudo chattr -i \
  /sys/firmware/efi/efivars/KEK-* /sys/firmware/efi/efivars/db-*
```

鍵を登録する:

```bash
sudo sbctl enroll-keys --microsoft
sudo sbctl status
```

`Setup Mode: Disabled` になり、Microsoft の鍵も登録されていればOK。
この時点で Secure Boot が有効化される場合があるが、lanzaboote は署名済みなので起動できる。

### 6. Secure Boot 有効化後の確認

```bash
bootctl status | sed -n '1,12p'
sudo sbctl verify
```

期待する状態:

```text
Secure Boot: enabled (user)
```

Secure Boot が無効のままなら、BIOS で Secure Boot を Enabled にして再起動する。
起動できれば、以降は署名済み lanzaboote 経由で NixOS が起動する。

### 7. Windows の起動確認

再起動して F11/F12 のブートメニューから Windows Boot Manager を選ぶ。

- Windows が起動すれば完了
- BitLocker は OFF なので回復キーは不要
- Secure Boot 有効化後に Vanguard などが要求する Secure Boot 条件を満たす

## トラブル時

- NixOS が起動しない: BIOS で Secure Boot を一時的に無効化し、systemd-boot の前世代または lanzaboote の前世代を選ぶ
- 署名確認で失敗する: `sudo sbctl verify` と `sudo sbctl status` を確認し、再度 `nix run .#switch`
- `File is immutable` が別のファイルでも出る: 該当する `/sys/firmware/efi/efivars/` 下のファイルに `chattr -i` を実行
- Windows が起動しない: BIOS の Boot Override に Windows Boot Manager があるか確認。無ければ手順1をやり直す
- Windows の BitLocker を後から有効化した場合: 次回キー変更前に必ず保護を一時停止する

## チェックリスト

- [x] Windows Boot Manager エントリを作成
- [x] F11/F12 から Windows が起動
- [x] `sudo sbctl create-keys`
- [ ] lanzaboote を有効化して switch
- [ ] `sudo sbctl verify` で署名確認
- [ ] BIOS で Setup Mode に変更
- [ ] `chattr -i` で immutable を解除
- [ ] `sudo sbctl enroll-keys --microsoft`
- [ ] `bootctl status` が `Secure Boot: enabled (user)`
- [ ] NixOS と Windows の両方が起動
