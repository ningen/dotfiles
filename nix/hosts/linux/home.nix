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

  # Linux 固有の追加パッケージはここへ。
  home.packages = with pkgs; [
    # playerctl
  ];
}
