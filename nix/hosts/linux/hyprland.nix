{
  config,
  ...
}:
let
  repo = "${config.home.homeDirectory}/ghq/github.com/ningen/dotfiles";
in
{
  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";
    package = null;
    portalPackage = null;
    systemd.enable = true;
    extraLuaFiles."dotfiles".content =
      config.lib.file.mkOutOfStoreSymlink "${repo}/_config/hypr/hyprland.lua";
  };

  xdg.configFile = {
    "hypr/scripts/audio-panel.sh".source =
      config.lib.file.mkOutOfStoreSymlink "${repo}/_config/hypr/scripts/audio-panel.sh";
    "hypr/scripts/cheatsheet.sh".source =
      config.lib.file.mkOutOfStoreSymlink "${repo}/_config/hypr/scripts/cheatsheet.sh";
    "hypr/scripts/clipboard.sh".source =
      config.lib.file.mkOutOfStoreSymlink "${repo}/_config/hypr/scripts/clipboard.sh";
    "hypr/scripts/screenshot.sh".source =
      config.lib.file.mkOutOfStoreSymlink "${repo}/_config/hypr/scripts/screenshot.sh";
  };
}
