# lazy.nvim → vim.pack 移行計画

対象: `.config/nvim`（Neovim 0.12.4 / nix, `~/.config/nvim` はこのリポジトリへの symlink）

実装前に方針を確認するためのメモ。実装はまだ行っていない。

## 現状

| 項目 | 内容 |
| --- | --- |
| プラグイン | oil.nvim, mini.icons のみ（両方 eager ロード、遅延ロード未使用） |
| LSP | ネイティブ `vim.lsp.config` / `vim.lsp.enable`（lua_ls） |
| colorscheme | catppuccin — **0.12 で runtime 同梱済み**（`$VIMRUNTIME/colors/catppuccin.vim` を実機確認）。プラグイン不要 |
| lazy.nvim 由来ファイル | `lua/config/lazy.lua`（bootstrap）、`lazy-lock.json`、`lua/plugins/filer.lua` |

## vim.pack の要点（0.12.4 実機のローカルヘルプで確認済み）

- インストール先: `stdpath('data')/site/pack/core/opt/<name>`（lazy とは別ディレクトリなので共存可能）
- `vim.pack.add()` で rtp 追加 + `:packadd`。初回のみ同期 clone（並列）、2 回目以降は高速
- **lockfile あり**: 初回 `vim.pack.add()` 時に `$XDG_CONFIG_HOME/nvim/nvim-pack-lock.json` を自動生成。
  - JSON 形式、VCS 管理推奨（lazy-lock.json と同じ運用）
  - lockfile があると、そのリビジョンで一括インストールされる（再現性 OK）
  - 手編集禁止・破損時は自動修復
- 更新: `vim.pack.update()` → 確認バッファで差分表示 → `:write` で適用 / `:quit` で取消
- ロールバック: `git checkout HEAD -- nvim-pack-lock.json` → `vim.pack.update(nil, { target = 'lockfile' })`
- 一時固定（freeze）: spec の `version = '<コミットハッシュ>'` にすると更新されない。解除は `version = nil` に戻す

### 0.12.4 には無いもの（master のドキュメントとの差分）

- `:packupdate` コマンド → Lua API (`vim.pack.update()`) で運用する
- `'packlockfile'` オプション → lockfile パスは `~/.config/nvim/nvim-pack-lock.json` 固定

### `vim.pack.add(specs, opts)` の挙動で注意する点

- `opts.confirm`: デフォルト `true` で**初回インストール時に対話確認が出る**。lazy.nvim と同じ挙動（サイレント導入）にするなら `{ confirm = false }` を明示
- `opts.load`: init.lua 読み込み中はデフォルト `false`（rtp への追加のみで `plugin/` スクリプトは source しない）。今回は setup() を明示的に呼ぶので問題ないが、`:Oil` コマンドが setup 由来か plugin/ 由来かは要検証（下記「動作確認」で確認）

## ステップ 1: 機械的移行

やることだけやり、構造は変えない。

### 変更内容

1. `init.lua`: `require('config.lazy')` → `require('plugins')`
2. 新規 `lua/plugins/init.lua`:

```lua
vim.pack.add({
  { src = 'https://github.com/nvim-mini/mini.icons' },
  { src = 'https://github.com/stevearc/oil.nvim' },
}, { confirm = false })

require('mini.icons').setup({})
require('oil').setup({})
```

3. 削除: `lua/config/lazy.lua`, `lua/plugins/filer.lua`, `lazy-lock.json`

### 動作確認

```bash
# エラーなく起動し、lockfile が生成されることを確認
nvim --headless +qa && cat .config/nvim/nvim-pack-lock.json

# :Oil コマンドが存在するか（setup 由来で生えるはず）
nvim --headless +'lua print(vim.fn.exists(":Oil"))' +qa  # 期待値: 1

# ディレクトリを開いて filetype が oil になるか
nvim --headless +'edit /tmp' +'lua print(vim.bo.filetype)' +qa  # 期待値: oil
```

`:Oil` が存在しない場合は `vim.pack.add(..., { confirm = false, load = true })` に変更して再確認。

### コミット

- `refactor(nvim): replace lazy.nvim with native vim.pack` 相当
- lockfile（`nvim-pack-lock.json`）は生成されていれば一緒にコミット（VCS 管理推奨のため）

## ステップ 2: プラグインごとのファイル分割

「spec と setup を 1 ファイルに閉じ込める」規約。新しいプラグイン = ファイル 1 枚追加。

### 規約

- `lua/plugins/<plugin名>.lua` は `pack`（vim.pack.Spec）と `setup`（関数 or nil）を持つテーブルを return
- `lua/plugins/init.lua` が順序リストに沿って集約し、`add` → 全 `setup` の順に実行

```lua
-- lua/plugins/mini-icons.lua
return {
  pack = { src = 'https://github.com/nvim-mini/mini.icons' },
  setup = function()
    require('mini.icons').setup({})
  end,
}
```

```lua
-- lua/plugins/oil.lua
return {
  pack = { src = 'https://github.com/stevearc/oil.nvim' },
  setup = function()
    require('oil').setup({})
  end,
}
```

```lua
-- lua/plugins/init.lua
local order = { 'mini-icons', 'oil' }

local mods = {}
for _, name in ipairs(order) do
  mods[#mods + 1] = require('plugins.' .. name)
end

local specs = {}
for _, m in ipairs(mods) do
  specs[#specs + 1] = m.pack
end
vim.pack.add(specs, { confirm = false })

for _, m in ipairs(mods) do
  if m.setup then
    m.setup()
  end
end
```

- 依存関係は `order` の並びで表現（依存される側を先）
- colorscheme など setup 不要のものは `setup` を省略できる
- バージョン固定したくなったらそのファイルの `pack.version` に書く（freeze もファイル単位）

### プラグイン追加の手順（この規約の運用）

1. `lua/plugins/<name>.lua` を新規作成（pack + 必要なら setup）
2. `order` に追記
3. nvim 再起動で自動インストール → lockfile 更新は `vim.pack.update()` 後にコミット

## 移行後の日々の操作

| 操作 | lazy.nvim | vim.pack (0.12.4) |
| --- | --- | --- |
| 更新 | `:Lazy update` | `vim.pack.update()`（確認バッファで `:write` / `:quit`） |
| 状態確認 | `:Lazy` | `vim.pack.get({ info = true })`（rev と rev_to 比較で更新有無がわかる） |
| 削除 | spec から消して sync | spec から消して再起動後 `vim.pack.del({ '<name>' })` |
| 再現 | lockfile 自動 | lockfile 自動（`nvim-pack-lock.json`） |

## 後片付け・注意点

- lazy.nvim の実体は残るので、動作確認後に任意で削除: `rm -rf ~/.local/share/nvim/lazy ~/.local/state/nvim/lazy`
- 初回起動時に clone が走るためネットワーク必須（2 回目以降はオフライン起動可）
- `~/.config/nvim` が symlink のため、lockfile はこのリポジトリ内に生成される（commit 対象になるのは意図通り）
