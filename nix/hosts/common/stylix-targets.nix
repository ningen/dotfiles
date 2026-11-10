{
  lib,
  pkgs,
  ...
}:
{
  stylix.targets = {
    gtk.enable = lib.mkDefault pkgs.stdenv.hostPlatform.isLinux;
    emacs.enable = false;
    helix.enable = false;
    kitty.enable = false;
    neovim.enable = false;
    sway.enable = false;
    tmux.enable = false;
    wezterm.enable = false;
    x11.enable = false;
    yazi.enable = false;
  };
}
