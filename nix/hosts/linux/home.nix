{
  pkgs,
  ...
}:
{
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    BROWSER = "google-chrome-stable";
  };

  home.pointerCursor = {
    enable = true;
    package = pkgs.adwaita-icon-theme;
    name = "Adwaita";
    size = 24;
  };

  # Linux 固有の追加パッケージはここへ。
  home.packages = with pkgs; [
    # playerctl
  ];
}
