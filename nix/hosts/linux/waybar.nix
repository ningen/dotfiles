{ ... }:
{
  programs.waybar = {
    enable = true;
    settings = [
      (builtins.fromJSON (builtins.readFile ../../../_config/waybar/config.jsonc))
    ];
    style = builtins.readFile ../../../_config/waybar/style.css;
  };
}
