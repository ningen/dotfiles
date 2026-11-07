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

  programs.zsh.shellAliases.dsh =
    "LD_PRELOAD=$HOME/.local/share/dsh-nix-fix/libdsh-getter-fix.so npx @deepseek-ai/dsh";

  # Linux 固有の追加パッケージはここへ。
  home.packages = with pkgs; [
    # playerctl
  ];
}
