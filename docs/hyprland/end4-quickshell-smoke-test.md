# end-4 Quickshell Smoke Test

This note keeps the first end-4/dots-hyprland Quickshell trial outside of the
managed Hyprland startup path. Do not run the upstream installer directly.

## Upstream Shape

- Repository: `end-4/dots-hyprland`
- Checked HEAD: `c04b0bbc8143a2b2166c1f699f7583cb28ff78fe`
- Quickshell config root: `dots/.config/quickshell/ii`
- Entry point: `dots/.config/quickshell/ii/shell.qml`
- Upstream launch pattern: `qs -c $qsConfig`
- Upstream install target: `$XDG_CONFIG_HOME/quickshell/ii`
- Local wrapper: `end4-qs`

The shell is not just a bar. It includes bar/panel families, notification UI,
dock, overview, sidebars, wallpaper handling, clipboard integration, settings,
session UI, and multiple helper scripts.

The local `end4-qs` wrapper sets the extra Qt/KDE QML import paths required by
the upstream config. Use it instead of calling `qs` directly for this config.

## Manual Test

Use a temporary clone first:

```bash
git clone --depth 1 https://github.com/end-4/dots-hyprland.git /tmp/dots-hyprland-end4
git -C /tmp/dots-hyprland-end4 submodule update --init --recursive
```

From an active Hyprland session, run one of these:

```bash
end4-qs -p /tmp/dots-hyprland-end4/dots/.config/quickshell/ii/shell.qml
```

or copy/symlink the config to the standard Quickshell location and use the
upstream-style command:

```bash
mkdir -p ~/.config/quickshell
ln -sfn /tmp/dots-hyprland-end4/dots/.config/quickshell/ii ~/.config/quickshell/ii
end4-qs -c ii
```

Stop it with:

```bash
pkill qs
```

If Nix wraps the executable name differently, inspect processes and stop the
matching Quickshell process manually.

## 2026-06-28 Result

`end4-qs -p /tmp/dots-hyprland-end4/dots/.config/quickshell/ii/shell.qml`
reached `Configuration Loaded` in a 15 second smoke test.

Fixed during the smoke test:

- added Qt/KDE runtime QML imports through the `end4-qs` wrapper
- initialized the upstream `rounded-polygon-qmljs` submodule
- added `ddcutil`, `brightnessctl`, and `libqalculate`
- enabled the NixOS `UPower` service

Remaining warnings were runtime state rather than load blockers:

- generated material color and wallpaper files do not exist yet
- local `illogical-impulse` translation override does not exist
- BlueZ DBus is unavailable or inactive
- `cliphist` refresh returned no usable history
- `playerctld` has no active player

## Expected Conflicts

- `waybar`: overlaps with end-4 bar/panels.
- `eww hypr-keymap`: overlaps with end-4 shell overlay/sidebar surfaces.
- `hyprshell`: overlaps with end-4 overview/launcher/search behavior.
- notification daemons: end-4 provides its own notification implementation.
- wallpaper/color tooling: end-4 expects its own material color pipeline and
  helper scripts.

For the current preview, `waybar`, `eww`, and `hyprshell` autostart entries are
commented out and `end4-qs -c ii` is active. Re-enable individual entries only
if the Quickshell preview is not usable enough for daily work.

## Promotion Path

1. Run the temporary clone manually inside Hyprland.
2. Record missing commands or QML import errors.
3. Add only the missing Nix packages that are required for the selected
   components.
4. Decide whether to vendor `dots/.config/quickshell/ii` or maintain a smaller
   local Quickshell config.
5. After promotion, keep `exec-once = end4-qs -c ii &` active in
   `.config/hypr/hyprland.conf`.
