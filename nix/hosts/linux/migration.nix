{ lib, ... }:
{
  home.activation.removeLegacyConfigSymlinks = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    for link in "$HOME/.config/hypr" "$HOME/.config/waybar" "$HOME/.config/quickshell" "$HOME/.config/rofi"; do
      if [ -L "$link" ]; then
        run rm "$link"
      fi
    done
  '';
}
