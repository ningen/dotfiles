# nix-darwin ガイド

## 概要

**nix-darwin**は、Nixパッケージマネージャーを使用してmacOSのシステム設定を宣言的に管理するためのツールです。これにより、システムの構成をコードとして記述し、再現性のある環境を構築できます。NixOSのmacOS版と考えることができますが、OS全体を置き換えるのではなく、既存のmacOS上で動作する設定管理レイヤーです。

## 基本概念

### nix-darwinとは

nix-darwinは、以下の特徴を持つmacOS用の宣言的システム設定管理ツールです：

- **Nix基盤**: 純粋関数型言語であるNixを使用し、パッケージは不変な`/nix/store`に格納
- **宣言的な設定**: システム設定、パッケージ、サービスを設定ファイルで記述
- **モジュールシステム**: macOS特定部分の設定を選択的に管理
- **再現性**: 同じ設定ファイルで同じ環境を再現可能

### macOSでのNixパッケージマネージャーの役割

nix-darwinは、macOS上でNixを活用するための中核的な機能を提供します：

1. **システムレベルのパッケージ管理**
   - Nixpkgsの巨大なパッケージリポジトリを利用
   - Homebrewと同様だが、より宣言的なアプローチ

2. **システム設定の管理**
   - ユーザーアカウント作成
   - システム共通パッケージインストール
   - macOS特有の設定を`configuration.nix`で一元管理

3. **サービスの管理**
   - `launchd`サービスの追加・管理

### NixOSとの違い

| 特徴 | NixOS | nix-darwin |
|------|-------|------------|
| **対象OS** | Nixベースの完全なLinuxディストリビューション | 既存のmacOS上の設定管理レイヤー |
| **置き換え範囲** | OS全体 | システム設定のみ |
| **カーネル管理** | 可能 | 不可（macOSカーネル使用） |
| **パッケージ管理** | 完全にNix | Nixと既存macOSツールの併用 |

## このdotfilesでの実装

### ファイル構成

```
nix/hosts/ningen-mba/
└── macos.nix                # nix-darwin設定ファイル

flake.nix                     # darwinConfigurations定義
```

### flake.nixでの統合

```nix
darwinConfigurations.ningen = nix-darwin.lib.darwinSystem {
  system = "aarch64-darwin";
  modules = [ ./nix/hosts/ningen-mba/macos.nix ];
};
```

### 主要設定内容（macos.nix）

#### 1. Nix基本設定

```nix
nix = {
  optimise.automatic = true;          # ストレージ最適化
  settings = {
    experimental-features = "nix-command flakes";  # Flakes有効化
    max-jobs = 8;                     # 並列ビルド数
  };
};

system.stateVersion = 6;              # nix-darwinバージョン
system.primaryUser = "ningen";        # プライマリユーザー
```

#### 2. macOS特有のシステム設定

```nix
system = {
  defaults = {
    # グローバル設定（defaults write NSGlobalDomain相当）
    NSGlobalDomain = {
      AppleShowAllExtensions = true;        # 全ファイル拡張子表示
      ApplePressAndHoldEnabled = false;     # キーリピート有効化
      "com.apple.keyboard.fnState" = true;  # Fnキーをファンクションキーとして使用
    };
    
    # Finder設定
    finder = {
      AppleShowAllFiles = true;             # 隠しファイル表示
      AppleShowAllExtensions = true;        # 拡張子表示
    };
    
    # Dock設定
    dock = {
      autohide = true;                      # 自動隠蔽
      show-recents = false;                 # 最近使用したアプリを非表示
      orientation = "bottom";               # 画面下部に配置
    };
  };
};
```

#### 3. フォント管理

```nix
fonts = {
  packages = with pkgs; [
    nerd-fonts.jetbrains-mono            # JetBrains Mono Nerd Font
  ];
};
```

#### 4. Homebrew統合

```nix
homebrew = {
  enable = true;
  
  # 自動管理設定
  onActivation = {
    autoUpdate = true;                     # 自動更新
    cleanup = "uninstall";                # 管理外パッケージを削除
  };
  
  # CLI アプリケーション（現在は空）
  brews = [
    # ここにHomebrewのformulaを記述
  ];
  
  # GUI アプリケーション
  casks = [
    "visual-studio-code"                   # VS Code
    "discord"                              # Discord
    "google-chrome"                        # Google Chrome
    "aquaskk"                              # 日本語入力
    "floorp"                               # Firefox系ブラウザ
    "notion"                               # Notion
    "ghostty"                              # ターミナル
    "cursor"                               # AI搭載エディタ
    "obsidian"                             # ノートアプリ
    "raycast"                              # ランチャー
  ];
};
```

## 実用的な使用方法

### darwin-rebuildコマンド

このdotfilesでは、CLAUDE.mdに記載の通り以下のコマンドを使用：

```bash
# Darwin設定を適用（macOSのみ）
sudo nix run nix-darwin/nix-darwin-24.11#darwin-rebuild -- switch --flake .#ningen
```

### 一般的なdarwin-rebuildコマンド

```bash
# 設定を即座に適用
sudo darwin-rebuild switch

# Flakeを使用した適用
sudo darwin-rebuild switch --flake .#ningen

# 設定をビルドのみ（適用はしない）
darwin-rebuild build

# 設定を確認
darwin-rebuild check
```

### システム更新ワークフロー

1. **設定ファイルの編集**
   ```bash
   vim nix/hosts/ningen-mba/macos.nix
   ```

2. **変更の適用**
   ```bash
   sudo nix run nix-darwin/nix-darwin-24.11#darwin-rebuild -- switch --flake .#ningen
   ```

3. **設定の確認**
   - システム環境設定で変更を確認
   - Homebrewアプリケーションの確認

### パッケージ管理

#### Nixパッケージの追加
```nix
# macos.nix
environment.systemPackages = with pkgs; [
  git
  vim
  curl
];
```

#### Homebrewパッケージの追加
```nix
# macos.nix
homebrew = {
  enable = true;
  brews = [
    "imagemagick"      # CLI tool
    "ffmpeg"           # Media processing
  ];
  casks = [
    "docker"           # Docker Desktop
    "slack"            # Slack
  ];
};
```

## macOS特有の設定オプション

### system.defaults設定可能項目

#### NSGlobalDomain（グローバル設定）
```nix
NSGlobalDomain = {
  # キーボード設定
  ApplePressAndHoldEnabled = false;           # キーリピート有効
  InitialKeyRepeat = 14;                      # 初回リピート遅延
  KeyRepeat = 1;                              # リピート速度
  
  # UI設定
  AppleShowAllExtensions = true;              # 拡張子表示
  AppleShowScrollBars = "Always";             # スクロールバー表示
  
  # その他
  "com.apple.keyboard.fnState" = true;        # Fnキー設定
  "com.apple.mouse.tapBehavior" = 1;          # タップクリック
};
```

#### Finder設定
```nix
finder = {
  AppleShowAllFiles = true;                   # 隠しファイル表示
  AppleShowAllExtensions = true;              # 拡張子表示
  FXEnableExtensionChangeWarning = false;     # 拡張子変更警告無効
  QuitMenuItem = true;                        # Finderを終了メニュー
  ShowPathbar = true;                         # パスバー表示
  ShowStatusBar = true;                       # ステータスバー表示
};
```

#### Dock設定
```nix
dock = {
  autohide = true;                            # 自動隠蔽
  autohide-delay = 0.24;                      # 表示遅延
  autohide-time-modifier = 1.0;               # アニメーション時間
  orientation = "bottom";                     # 位置
  show-recents = false;                       # 最近のアプリ非表示
  tilesize = 48;                              # アイコンサイズ
};
```

### Homebrew統合の詳細設定

#### 基本設定
```nix
homebrew = {
  enable = true;
  
  # 自動管理
  onActivation = {
    autoUpdate = true;                        # 自動更新
    cleanup = "uninstall";                    # クリーンアップ戦略
    # cleanup = "zap";                        # より徹底的な削除
    # cleanup = "none";                       # クリーンアップしない
  };
  
  # グローバル設定
  global = {
    autoUpdate = true;                        # Homebrew自体の自動更新
  };
};
```

#### パッケージ種別
```nix
homebrew = {
  # Tap（リポジトリ追加）
  taps = [
    "homebrew/cask-fonts"
    "homebrew/services"
  ];
  
  # Formula（CLI tools）
  brews = [
    "imagemagick"
    "ffmpeg"
    "node"
  ];
  
  # Cask（GUI apps）
  casks = [
    "google-chrome"
    "visual-studio-code"
    "docker"
  ];
  
  # Mac App Store apps
  masApps = {
    "1Password 7" = 1333542190;
    "Xcode" = 497799835;
  };
};
```

## 世代管理とロールバック

### 設定世代の確認
```bash
# 世代一覧表示
sudo nix-env -p /nix/var/nix/profiles/system --list-generations

# 現在の世代確認
ls -la /nix/var/nix/profiles/system
```

### ロールバック
```bash
# 直前の世代に戻る
sudo nix-env -p /nix/var/nix/profiles/system --rollback

# 特定の世代に戻る
sudo nix-env -p /nix/var/nix/profiles/system --switch-generation <世代番号>

# 設定を再適用
sudo darwin-rebuild switch
```

## トラブルシューティング

### よくある問題

1. **権限エラー**
   ```bash
   # Nixストアの権限確認
   ls -la /nix/store
   
   # nix-darwinの再インストール
   nix run nix-darwin/nix-darwin#darwin-installer
   ```

2. **Homebrew競合**
   ```bash
   # Homebrewのクリーンアップ
   brew cleanup
   
   # 孤立したパッケージの削除
   brew autoremove
   ```

3. **設定が反映されない**
   ```bash
   # キャッシュクリア
   sudo nix-collect-garbage -d
   
   # 強制再ビルド
   sudo darwin-rebuild switch --recreate-lock-file
   ```

### macOSアップデート時の対応

1. **アップデート前**
   ```bash
   # 現在の設定をバックアップ
   cp -r ~/.config/nix-darwin ~/nix-darwin-backup
   ```

2. **アップデート後**
   ```bash
   # nix-darwinの動作確認
   darwin-rebuild check
   
   # 必要に応じて再インストール
   nix run nix-darwin/nix-darwin#darwin-installer
   ```

### デバッグのヒント

```bash
# 詳細ログ表示
sudo darwin-rebuild switch --show-trace

# ビルドプロセス確認
nix build .#darwinConfigurations.ningen.system --show-trace

# 設定差分確認
nix build .#darwinConfigurations.ningen.system
diff /nix/var/nix/profiles/system result
```

## 他のツールとの比較

### 従来のmacOS管理ツールとの比較

| 特徴 | nix-darwin | Homebrew | Ansible | Dotbot |
|------|------------|----------|---------|---------|
| **宣言的設定** | ✅ | ❌ | ✅ | ✅ |
| **再現性** | ✅ | 部分的 | ✅ | ✅ |
| **ロールバック** | ✅ | ❌ | ❌ | ❌ |
| **システム設定** | ✅ | ❌ | ✅ | ❌ |
| **パッケージ管理** | ✅ | ✅ | 部分的 | ❌ |
| **学習コスト** | 高 | 低 | 中 | 低 |

### Home Managerとの連携

nix-darwinとHome Managerは相互補完的に使用できます：

- **nix-darwin**: システムレベルの設定とパッケージ
- **Home Manager**: ユーザーレベルの設定とdotfiles

```nix
# このdotfilesでの連携例
homeConfigurations = {
  "ningen@ningen-mba.local" = mkHome {
    system = "aarch64-darwin";
    modules = [
      ./nix/hosts/common/home.nix        # 共通ユーザー設定
      ./nix/packages/dev-tools.nix       # 開発ツール
      # ... その他のモジュール
    ];
  };
};
```

## セキュリティ考慮事項

### 重要な設定

```nix
# システムセキュリティ設定
system.defaults = {
  # ファイアウォール有効化
  alf.globalstate = 1;
  
  # スクリーンセーバー設定
  screensaver.askForPassword = true;
  screensaver.askForPasswordDelay = 5;
  
  # ソフトウェアアップデート
  SoftwareUpdate.AutomaticallyInstallMacOSUpdates = false;
};

# 不要なサービス無効化
services.nix-daemon.enable = true;
```

### Homebrewセキュリティ

```nix
homebrew = {
  # 信頼できるソースのみ使用
  taps = [
    "homebrew/core"
    "homebrew/cask"
  ];
  
  # 自動更新でセキュリティパッチ適用
  onActivation.autoUpdate = true;
};
```

## パフォーマンス最適化

### Nix設定の最適化

```nix
nix = {
  # ストレージ最適化
  optimise.automatic = true;
  
  # ビルド並列化
  settings = {
    max-jobs = 8;                          # CPUコア数に応じて調整
    cores = 4;                             # コア数制限
  };
  
  # ガベージコレクション
  gc = {
    automatic = true;
    interval = { Weekday = 0; Hour = 2; Minute = 0; };  # 日曜日2時
    options = "--delete-older-than 30d";
  };
};
```

### Homebrew最適化

```nix
homebrew = {
  # クリーンアップ戦略
  onActivation.cleanup = "uninstall";       # 不要パッケージ削除
  
  # 自動更新無効化（手動管理する場合）
  global.autoUpdate = false;
};
```

## 参考リンク

- [nix-darwin Manual](https://nix-darwin.github.io/nix-darwin/manual/)
- [nix-darwin GitHub Repository](https://github.com/LnL7/nix-darwin)
- [Nixpkgs Manual](https://nixos.org/manual/nixpkgs/stable/)
- [Home Manager Manual](https://rycee.gitlab.io/home-manager/)
- [macOS defaults](https://macos-defaults.com/) - macOS設定リファレンス