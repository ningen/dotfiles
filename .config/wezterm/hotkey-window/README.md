# WezTerm Hotkey Window Setup

iTerm2の「Hotkey Window」機能のように、ショートカットキーでWeztermを瞬時に表示/非表示できる設定です。

## 📋 セットアップ

### 自動セットアップ（推奨）

dotfilesのセットアップスクリプトを実行すると、自動的に設定ファイルが配置されます。

**macOS:**
```bash
cd ~/dev/dotfiles
./setup-dotfiles.sh
```

**Windows:**
```powershell
cd ~/dev/dotfiles
.\setup-dotfiles.ps1
```

### OS別の追加設定

#### macOS

1. **Karabiner-Elementsをインストール**
   ```bash
   brew install --cask karabiner-elements
   ```

2. **Karabinerで設定を有効化**
   - Karabiner-Elementsを起動
   - "Complex Modifications" タブを開く
   - "Add rule" をクリック
   - "Quake-style Hotkey Window for WezTerm" を有効化

3. **使用方法**
   - `Ctrl + I`: Weztermを表示/非表示

#### Windows

1. **AutoHotkey v2.0をインストール**
   - [AutoHotkey公式サイト](https://www.autohotkey.com/)からダウンロード
   - または winget経由: `winget install AutoHotkey.AutoHotkey`

2. **スクリプトの動作確認**
   - セットアップスクリプト実行後、自動的にスタートアップに配置されます
   - 配置先: `~/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup/wezterm-quake.ahk`
   - 次回ログイン時から自動起動します

3. **即座に使いたい場合**
   - スタートアップフォルダ内の `wezterm-quake.ahk` をダブルクリック
   - またはコマンドで実行:
     ```powershell
     & "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\wezterm-quake.ahk"
     ```

4. **使用方法**
   - `Ctrl + I`: Weztermを表示/非表示
   - ウィンドウは画面上部40%の高さでドロップダウン表示
   - 常に最前面で半透明表示

## ⚙️ カスタマイズ

### macOS - ショートカットキー変更

[karabiner-wezterm.json](karabiner-wezterm.json) の `key_code` と `modifiers` を変更:

```json
"from": {
  "key_code": "i",                // 変更したいキー
  "modifiers": { "mandatory": ["control"] }  // 修飾キー
}
```

変更後、Karabiner-Elementsで設定を再読み込みしてください。

### Windows - 設定変更

[wezterm-quake.ahk](wezterm-quake.ahk) の冒頭で調整可能:

```autohotkey
; ウィンドウの透明度 (0-255、255=不透明)
Opacity := 225

; 初期ウィンドウ高さ (画面高さの40%)
InitialHeight := A_ScreenHeight * 0.4

; ホットキー変更 (例: Ctrl+I → Ctrl+Shift+I)
Control & Shift & i:: {
    ToggleTerminal()
}
```

変更後、スタートアップフォルダ内のスクリプトを再起動してください。

## 📝 動作説明

### macOS (Karabiner-Elements)
- Weztermが非アクティブ時: `Ctrl+I` でWeztermを起動または表示
- Weztermがアクティブ時: `Ctrl+I` でWeztermを非表示（`Cmd+H`）

### Windows (AutoHotkey)
- 初回実行時: Weztermを起動し、画面上部に配置
- ウィンドウ設定:
  - 画面幅いっぱい、高さは40%
  - 常に最前面表示
  - 透明度225/255（約88%）
- トグル動作: `Ctrl+I`で表示/非表示を切り替え

## 🔧 トラブルシューティング

### macOS
- **Karabinerが動作しない**
  - システム環境設定 → セキュリティとプライバシー → アクセシビリティ
  - Karabiner-Elementsに権限を付与

- **Weztermが起動しない**
  - インストールパスが `/Applications/WezTerm.app` か確認
  - 異なる場合は `karabiner-wezterm.json` のパスを修正

### Windows
- **スクリプトが動作しない**
  - AutoHotkey v2.0がインストールされているか確認
  - タスクバーにAutoHotkeyアイコンが表示されているか確認

- **Weztermが見つからない**
  - `wezterm-gui.exe` がPATHに含まれているか確認
  - コマンドプロンプトで `where wezterm-gui` を実行して確認

- **権限エラー**
  - スクリプトを右クリック → "管理者として実行"

- **スクリプトを停止したい**
  - タスクバーのAutoHotkeyアイコンを右クリック → "Exit"
  - またはタスクマネージャーから終了

## 📚 参考

- [Karabiner-Elements公式ドキュメント](https://karabiner-elements.pqrs.org/)
- [AutoHotkey v2.0公式ドキュメント](https://www.autohotkey.com/docs/v2/)
- [Original macOS Gist](https://gist.github.com/svallory/0cc08750e5ae837adad3ee3dde3599c9)
- [Original Windows Gist](https://gist.github.com/makubo/979f90dd4ff910be8a84f74b0b153695)
