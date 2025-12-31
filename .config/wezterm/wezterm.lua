local wezterm = require("wezterm")
local keys = require("keymap")

local config = {
	leader = { key = ";", mods = "CTRL" },
	keys = keys,
	
	-- Font settings
	font = wezterm.font_with_fallback({
		{ family = "JetBrains Mono", weight = "Medium" },
		"Noto Color Emoji",
	}),
	font_size = 14.0,
	line_height = 1.2,
	harfbuzz_features = { "calt=1", "clig=1", "liga=1" }, -- Enable ligatures
	
	-- Color scheme
	color_scheme = "Tokyo Night",
	
	-- Window appearance
	window_background_opacity = 0.85,
	text_background_opacity = 0.8,
	window_padding = {
		left = 16,
		right = 16,
		top = 16,
		bottom = 16,
	},
	
	-- Tab bar
	use_fancy_tab_bar = false,
	tab_bar_at_bottom = false,
	show_new_tab_button_in_tab_bar = false,
	hide_tab_bar_if_only_one_tab = false,
	show_tab_index_in_tab_bar = false,
	tab_max_width = 32,
	
	-- Window decorations
	window_decorations = "RESIZE",
	window_close_confirmation = "NeverPrompt",
	
	-- Cursor
	default_cursor_style = "BlinkingBlock",
	cursor_blink_rate = 500,
	
	-- Scrollback
	scrollback_lines = 10000,
	
	-- Other
	treat_left_ctrlalt_as_altgr = false,
	enable_scroll_bar = false,
	audible_bell = "Disabled",
}

-- Custom color overrides for better aesthetics
config.colors = {
	tab_bar = {
		background = "rgba(15, 15, 20, 0.95)",
		active_tab = {
			bg_color = "#bb9af7",
			fg_color = "#1a1b26",
			intensity = "Bold",
		},
		inactive_tab = {
			bg_color = "rgba(65, 72, 104, 0.8)",
			fg_color = "#a9b1d6",
		},
		inactive_tab_hover = {
			bg_color = "rgba(86, 95, 137, 0.9)",
			fg_color = "#c0caf5",
		},
		new_tab = {
			bg_color = "rgba(15, 15, 20, 0.95)",
			fg_color = "#565f89",
		},
		new_tab_hover = {
			bg_color = "#414868",
			fg_color = "#7aa2f7",
		},
	},
}

-- Custom tab title formatting
wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
	local edge_background = "#0f0f14"
	local background = "#414868"
	local foreground = "#a9b1d6"
	
	if tab.is_active then
		background = "#bb9af7"
		foreground = "#1a1b26"
	elseif hover then
		background = "#565f89"
		foreground = "#c0caf5"
	end
	
	local edge_foreground = background
	local title = tab.active_pane.title
	local process = string.gsub(tab.active_pane.foreground_process_name, "(.*[/\\])(.*)", "%2")
	
	-- Truncate title if too long
	if #title > 20 then
		title = string.sub(title, 1, 17) .. "..."
	end
	
	-- Add process name if different from title
	if process and process ~= "" and not string.find(title, process) then
		title = process .. ": " .. title
	end
	
	-- Add tab index
	local tab_index = tab.tab_index + 1
	local formatted_title = string.format(" %d: %s ", tab_index, title)
	
	return {
		{ Background = { Color = edge_background } },
		{ Foreground = { Color = edge_foreground } },
		{ Text = "" },
		{ Background = { Color = background } },
		{ Foreground = { Color = foreground } },
		{ Text = formatted_title },
		{ Background = { Color = edge_background } },
		{ Foreground = { Color = edge_foreground } },
		{ Text = "" },
	}
end)

-- Status line with battery, time, and system info
wezterm.on("update-right-status", function(window, pane)
	local date = wezterm.strftime("%a %b %-d %H:%M ")
	local bat = ""
	
	-- Try to get battery info (Linux/macOS)
	local success, battery_info = pcall(function()
		local handle = io.popen("cat /sys/class/power_supply/BAT*/capacity 2>/dev/null || pmset -g batt | grep -o '[0-9]*%' | head -1")
		local result = handle:read("*a")
		handle:close()
		return result:gsub("\n", "")
	end)
	
	if success and battery_info and battery_info ~= "" then
		bat = "🔋 " .. battery_info .. "% "
	end
	
	window:set_right_status(wezterm.format({
		{ Background = { Color = "#414868" } },
		{ Foreground = { Color = "#c0caf5" } },
		{ Text = " " .. bat .. date },
	}))
end)

-- Add workspace indicator
wezterm.on("format-window-title", function(tab, pane, tabs, panes, config)
	local zoomed = ""
	if tab.active_pane.is_zoomed then
		zoomed = "[Z] "
	end
	
	local index = ""
	if #tabs > 1 then
		index = string.format("[%d/%d] ", tab.tab_index + 1, #tabs)
	end
	
	return zoomed .. index .. tab.active_pane.title
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
