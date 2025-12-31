local wezterm = require("wezterm")
local act = wezterm.action

local hjkl = {
	h = "Left",
	j = "Down",
	k = "Up",
	l = "Right",
}

local keys = {
	-- 垂直分割
	{ key = "v", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	-- 水平分割
	{ key = "h", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	-- プロファイル選択（Windows で launch_menu を表示）
	{ key = "p", mods = "LEADER", action = act.ShowLauncherArgs({ flags = "LAUNCH_MENU_ITEMS" }) },
}

-- ペイン移動
for key, direction in pairs(hjkl) do
	table.insert(keys, { key = key, mods = "ALT", action = act.ActivatePaneDirection(direction) })
end

-- アクティブペインのサイズ変更
for key, direction in pairs(hjkl) do
	table.insert(keys, { key = string.upper(key), mods = "CTRL|SHIFT", action = act.AdjustPaneSize({ direction, 5 }) })
end

-- 数字キーでタブ移動（1-9）
for i = 1, 9 do
	table.insert(keys, { key = tostring(i), mods = "CMD", action = act.ActivateTab(i - 1) })
	table.insert(keys, { key = tostring(i), mods = "SUPER", action = act.ActivateTab(i - 1) })
end

return keys
