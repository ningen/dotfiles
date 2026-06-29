# end-4 Quickshell Daily Driver Notes

This records the promotion from a reversible preview to the primary NixOS
Hyprland shell.

## Decision

Use `end-4/dots-hyprland` as the primary desktop shell, but keep it pinned
through Nix instead of running the upstream installer or editing the upstream
tree in place.

The mutable end-4 user configuration is tracked separately at:

```bash
.config/illogical-impulse/config.json
```

At runtime, this is delivered to:

```bash
~/.config/illogical-impulse/config.json
```

The upstream Quickshell config remains a read-only Home Manager source:

```bash
~/.config/quickshell/ii
```

## What Changed

- `end4-qs` wraps `qs` with the Qt/KDE QML import paths required by end-4.
- `end4-launcher` opens the end-4 overview/search via Quickshell IPC.
- `end4-ipc` is a small wrapper for common end-4 IPC calls.
- `Super + Space` now opens end-4 overview/search.
- Old fallback UI paths were removed:
  - Waybar
  - EWW keymap overlay
  - Hyprshell autostart fallback
  - Ulauncher service and GNOME `Super + Space` binding
  - Rofi launcher fallback
- Hyprland keybinds now use end-4 IPC for:
  - right sidebar: `Super + N`
  - left sidebar: `Super + Shift + N`
  - wallpaper selector: `Super + W`
  - random wallpaper: `Super + Shift + W`
  - session screen: `Super + Escape`
  - region screenshot: `Print`
  - region recording: `Shift + Print`
  - image search screenshot: `Ctrl + Print`
  - lock: `Super + L`

## Update Procedure

1. Update the pinned upstream revision in `nix/packages/gui.nix`:

   ```nix
   end4DotsHyprland = pkgs.fetchFromGitHub {
     owner = "end-4";
     repo = "dots-hyprland";
     rev = "<new commit>";
     hash = "<new hash>";
     fetchSubmodules = true;
   };
   ```

2. Let Nix report the expected hash, then replace it.
3. Build Home Manager:

   ```bash
   nix build .#homeConfigurations."ningen@nixos".activationPackage
   ```

4. Build the NixOS system when system packages changed:

   ```bash
   nix build .#nixosConfigurations.myNixOS.config.system.build.toplevel
   ```

5. Apply Home Manager:

   ```bash
   nix run .#switch
   ```

6. Apply NixOS only when system-level packages or services changed:

   ```bash
   sudo nixos-rebuild switch --flake .#myNixOS
   ```

7. Restart Quickshell:

   ```bash
   end4-qs kill -c ii --any-display
   end4-qs -d -c ii
   ```

8. Check:

   ```bash
   pgrep -a qs
   hyprctl configerrors
   end4-qs ipc -c ii --any-display show
   ```

## Rollback

Rollback is mainly a Nix rollback:

```bash
git revert <end4-change-commit>
nix run .#switch
sudo nixos-rebuild switch --flake .#myNixOS
```

For an immediate session fallback, stop Quickshell and restore a previous
Hyprland generation or git revision:

```bash
end4-qs kill -c ii --any-display
git checkout <known-good-revision> -- .config/hypr nix/packages/gui.nix nix/hosts/nixos/configuration.nix
nix run .#switch
hyprctl reload config-only
```

## Blog Notes

Useful points for a later write-up:

- The upstream installer was intentionally avoided because this dotfiles repo
  already owns Hyprland and Home Manager state.
- The trial started as an isolated Hyprland include plus manual Quickshell smoke
  tests, then moved to a pinned Nix source.
- The biggest practical fix was adding Qt/KDE QML runtime paths through
  `end4-qs`.
- Material Symbols had to be installed so icon names like `memory` rendered as
  icons instead of text.
- Treating upstream Quickshell config as read-only and tracking
  `illogical-impulse/config.json` separately gives a clean update/rollback
  boundary.
- Promoting to daily driver mostly meant deleting fallback UI paths and making
  Hyprland keybinds call Quickshell IPC directly.
