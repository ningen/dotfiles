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
}

-- アクティブペインの移動系
for key, direction in pairs(hjkl) do
	table.insert(keys, { key = key, mods = "CMD", action = act.ActivatePaneDirection(direction) })
end

-- アクティブペインのサイズ変更
for key, direction in pairs(hjkl) do
	table.insert(keys, { key = string.upper(key), mods = "CMD|SHIFT", action = act.AdjustPaneSize({ direction, 5 }) })
end

-- 数字キーでタブ移動（1-9）
for i = 1, 9 do
	table.insert(keys, { key = tostring(i), mods = "CMD", action = act.ActivateTab(i - 1) })
end

return keys
