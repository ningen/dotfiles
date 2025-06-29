# NixOS ガイド

## 概要

**NixOS**は、Nixパッケージマネージャーを基盤に構築されたLinuxディストリビューションです。システム全体の設定を**宣言的に**行い、原子的な更新とロールバックを可能にすることで、高い再現性と信頼性を実現しています。

## 基本概念

### NixOSとは

NixOSは従来のLinuxディストリビューションとは根本的に異なるアプローチを採用しています：

- **Nixパッケージマネージャー**: パッケージや依存関係を、それぞれ独立した一意なディレクトリにインストール
- **宣言的な設定**: システムのあるべき状態を設定ファイル（`configuration.nix`）にNix言語で記述
- **再現性と信頼性**: 同じ設定ファイルを使えば、どこでも全く同じシステム構成を再現可能
- **原子的なアップグレードとロールバック**: システムの更新は原子的に行われ、失敗してもシステムが不安定になることがない

### 従来のLinuxディストリビューションとの違い

| 特徴 | 従来のLinuxディストリビューション | NixOS |
|------|-----------------------------------|-------|
| **設定管理** | 命令的（コマンドを逐次実行） | 宣言的（あるべき状態を記述） |
| **パッケージ管理** | 共有ディレクトリにインストール | 個別のディレクトリに隔離 |
| **アップグレード** | 不可逆な上書き更新 | 原子的な更新 |
| **ロールバック** | 標準では困難 | 簡単なロールバック機能 |
| **再現性** | 手作業が多く困難 | 設定ファイルにより容易 |

### 宣言的設定管理の利点

- **可読性とバージョン管理**: システム設定全体の見通しが良く、Gitなどで変更履歴を管理可能
- **環境の共有と再現**: 設定ファイルを共有するだけで、同じ環境を簡単に再現
- **信頼性の高い更新**: システムが壊れる心配なく、気軽に設定変更やソフトウェアの試用が可能

## このdotfilesでの実装

### ファイル構成

```
nix/hosts/nixos/
├── configuration.nix        # メインのシステム設定
├── gui.nix                 # GUI アプリケーション設定
└── hardware-configuration.nix  # ハードウェア固有設定（自動生成）
```

### 主要設定内容

#### システム基本設定（configuration.nix）

1. **ブートローダー設定**
   ```nix
   boot.loader.systemd-boot.enable = true;
   boot.loader.efi.canTouchEfiVariables = true;
   ```

2. **ネットワーク設定**
   ```nix
   networking = {
     hostName = "nixos";
     nameservers = [ "8.8.8.8" "8.8.4.4" ];
     networkmanager.enable = true;
   };
   ```

3. **ロケール設定（日本語対応）**
   ```nix
   time.timeZone = "Asia/Tokyo";
   i18n.defaultLocale = "ja_JP.UTF-8";
   ```

#### ハードウェア最適化

1. **NVIDIAドライバー設定**
   ```nix
   # configuration.nix
   services.xserver.videoDrivers = [ "nvidia" ];
   
   # hardware-configuration.nix
   hardware.nvidia = {
     # プロプライエタリドライバー使用（RTX 20シリーズ以降なら open = true も可）
     open = false;
     
     # Kernel Mode Setting（Waylandに必須、画面ティアリング対策）
     modesetting.enable = false;  # 必要に応じて true に変更
     
     # 電源管理（スリープ後のグラフィック破損対策、実験的機能）
     powerManagement.enable = false;
     # powerManagement.finegrained = true;  # Turing以降のGPU用
     
     # NVIDIA設定GUI有効化
     nvidiaSettings = true;
     
     # ドライバーパッケージ選択
     package = config.boot.kernelPackages.nvidiaPackages.stable;
     # その他のオプション: production, beta, legacy_470, legacy_390
   };
   
   # PRIME設定（ハイブリッドグラフィックスの場合）
   # hardware.nvidia.prime.sync.enable = true;      # 画面ティアリング対策、電力消費大
   # hardware.nvidia.prime.offload.enable = true;   # 省電力、必要時のみNVIDIA GPU使用
   ```

2. **カーネルパラメータ（ゲーミング最適化）**
   ```nix
   boot.kernelParams = [
     "nvidia-drm.modeset=1"
     "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
     "nvidia.NVreg_EnableGpuFirmware=0"
   ];
   ```

#### デスクトップ環境

1. **Hyprland（Waylandコンポジター）**
   ```nix
   programs.hyprland = {
     enable = true;
     xwayland.enable = true;
   };
   ```

2. **オーディオ（PipeWire）**
   ```nix
   services.pipewire = {
     enable = true;
     alsa.enable = true;
     alsa.support32Bit = true;
     pulse.enable = true;
   };
   ```

3. **日本語入力（Fcitx5 + Mozc）**
   ```nix
   i18n.inputMethod = {
     enable = true;
     type = "fcitx5";
     fcitx5.addons = [
       pkgs.fcitx5-mozc
       pkgs.fcitx5-gtk
       pkgs.fcitx5-anthy
     ];
   };
   ```

#### ゲーミング環境

```nix
programs.gamemode.enable = true;
programs.gamescope = {
  enable = true;
  capSysNice = true;
};
programs.steam = {
  enable = true;
  gamescopeSession.enable = true;
};
```

#### フォント設定

```nix
fonts = {
  packages = with pkgs; [
    noto-fonts-cjk-serif
    noto-fonts-cjk-sans
    noto-fonts-emoji
    nerd-fonts.jetbrains-mono
  ];
  fontconfig.defaultFonts = {
    serif = [ "Noto Serif CJK JP" "Noto Color Emoji" ];
    sansSerif = [ "Noto Sans CJK JP" "Noto Color Emoji" ];
    monospace = [ "JetBrainsMono Nerd Font" "Noto Color Emoji" ];
  };
};
```

### flake.nixでの統合

```nix
nixosConfigurations = {
  myNixOS = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      ./nix/hosts/nixos/configuration.nix
      {
        users.users.ningen.home = "/home/ningen";
      }
    ];
    specialArgs = { inherit inputs; };
  };
};
```

## 実用的な使用方法

### システム更新コマンド

このdotfilesでは、CLAUDE.mdに記載の通り以下のコマンドを使用：

```bash
# NixOSシステム設定を適用
sudo nixos-rebuild switch --flake .#myNixOS

# 設定をビルドのみ（適用はしない）
nix build .#nixosConfigurations.myNixOS.config.system.build.toplevel
```

### 一般的なnixos-rebuildコマンド

```bash
# 設定を即座に適用し、次回起動時もデフォルトに設定
sudo nixos-rebuild switch

# 次回起動時のデフォルトに設定（即座には適用しない）
sudo nixos-rebuild boot

# 一時的にテスト（再起動で元に戻る）
sudo nixos-rebuild test

# ビルドのみ（適用しない）
sudo nixos-rebuild build
```

### パッケージ管理

#### システムパッケージの追加
```nix
# configuration.nix
environment.systemPackages = with pkgs; [
  # 既存のパッケージ
  kitty
  wofi
  waybar
  # 新しいパッケージを追加
  firefox
  vscode
];
```

#### ユーザーパッケージの追加
```nix
# configuration.nix
users.users.ningen = {
  packages = with pkgs; [
    thunderbird
    discord
  ];
};
```

### 世代管理とロールバック

```bash
# 世代一覧を表示
nixos-rebuild list-generations

# 特定の世代に切り替え
sudo nixos-rebuild switch --rollback

# 世代を指定してロールバック
sudo nixos-rebuild switch --switch-generation <世代番号>

# 古い世代を削除
sudo nix-collect-garbage -d
```

## 設定オプションの確認方法

### search.nixos.orgの活用

NixOSの設定オプションは以下のURLで検索可能：
```
https://search.nixos.org/options?channel=25.05&query=${parameter}
```

例：
- `query=nvidia` - NVIDIA関連設定
- `query=hyprland` - Hyprland関連設定
- `query=fcitx5` - 日本語入力関連設定

### オプションの詳細確認

```bash
# システム内でオプションを確認
nixos-option <オプション名>

# 例：NVIDIAドライバー設定を確認
nixos-option hardware.nvidia

# 設定値を確認
nixos-option hardware.nvidia.modesetting.enable
```

## トラブルシューティング

### よくある問題

1. **ビルドエラー**
   ```bash
   # 構文チェック
   nix-instantiate --parse /etc/nixos/configuration.nix
   
   # キャッシュクリア
   sudo nix-collect-garbage
   ```

2. **ブートできない場合**
   - GRUBメニューから前の世代を選択
   - 起動後に `sudo nixos-rebuild switch --rollback`

3. **Hyprlandが起動しない**
   - NVIDIAドライバーとの競合確認
   - `hardware.nvidia.modesetting.enable = true;` を設定

### デバッグのヒント

```bash
# システムログ確認
journalctl -xe

# 特定サービスの状態確認
systemctl status <サービス名>

# ビルドプロセスの詳細表示
nixos-rebuild switch --show-trace
```

## セキュリティ考慮事項

### 重要な設定

```nix
# 不自由なパッケージを許可（必要に応じて）
nixpkgs.config.allowUnfree = true;

# ファイアウォール設定
networking.firewall.enable = true;
networking.firewall.allowedTCPPorts = [ 22 80 443 ];

# SSH設定
services.openssh = {
  enable = true;
  settings = {
    PasswordAuthentication = false;
    PermitRootLogin = "no";
  };
};
```

## パフォーマンス最適化

### ゲーミング向け設定

```nix
# CPU性能モード
powerManagement.cpuFreqGovernor = "performance";

# カーネルパラメータでのVRR最適化
environment.sessionVariables = {
  __GL_GSYNC_ALLOWED = "1";
  __GL_VRR_ALLOWED = "1";
  __GL_MaxFramesAllowed = "1";
  __GL_SYNC_TO_VBLANK = "0";
};
```

### SSD最適化

```nix
# hardware-configuration.nix（自動生成される例）
fileSystems."/mnt/external-ssd" = {
  options = [ "defaults" "noatime" "nofail" ];
};
```

## 参考リンク

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [NixOS Options Search](https://search.nixos.org/options)
- [NixOS Wiki](https://wiki.nixos.org/)
- [Nix Language Tutorial](https://nixos.org/manual/nix/stable/language/)
- [Home Manager Manual](https://rycee.gitlab.io/home-manager/)