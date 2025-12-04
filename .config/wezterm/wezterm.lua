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

return config
