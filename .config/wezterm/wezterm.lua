local wezterm = require("wezterm")
local keys = require("keymap")

local config = {
	leader = { key = ";", mods = "CTRL" },
	keys = keys,
	font = wezterm.font("JetBrains Mono"), -- font の設定
	color_scheme = "Kanagawa (Gogh)",
	window_background_opacity = 0.95,
	text_background_opacity = 0.9,
	use_fancy_tab_bar = false,
	show_new_tab_button_in_tab_bar = false,
}

config.font = wezterm.font("JetBrains Mono") -- font の設定
config.color_scheme = "Kanagawa (Gogh)" -- カラースキーマの設定

-- 透明度の設定
config.window_background_opacity = 0.95
config.text_background_opacity = 0.9

config.use_fancy_tab_bar = false
config.show_new_tab_button_in_tab_bar = false

-- ウィンドウの装飾を統合ボタンスタイルに（macOSスタイルのコンパクトなボタン）
config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"

-- タブのタイトルをシンプルな形式にカスタマイズ
wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
	local title = tab.active_pane.title
	-- プロセス名を取得してシンプルに表示
	local process_name = title:match("([^/\\]+)%s*$") or title
	return {
		{ Text = " " .. process_name .. " " },
	}
end)

-- Windows 固有の設定
if wezterm.target_triple == "x86_64-pc-windows-msvc" or wezterm.target_triple == "aarch64-pc-windows-msvc" then
	-- WSL をデフォルトプロファイルに設定
	config.default_prog = { "wsl.exe", "~" }

	-- 起動プロファイル一覧
	config.launch_menu = {
		{
			label = "WSL (Ubuntu)",
			args = { "wsl.exe", "~" },
		},
		{
			label = "PowerShell",
			args = { "powershell.exe", "-NoLogo" },
		},
		{
			label = "Command Prompt",
			args = { "cmd.exe" },
		},
		{
			label = "Git Bash",
			args = { "C:\\Program Files\\Git\\bin\\bash.exe", "-l" },
		},
	}
end

return config
