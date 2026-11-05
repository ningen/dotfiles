{
  pkgs,
  ...
}:
{
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    BROWSER = "chromium";
  };

  # Linux 固有の追加パッケージはここへ。
  home.packages = with pkgs; [
    # playerctl
  ];
}
