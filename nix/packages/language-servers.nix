{ pkgs, ... }: {
  home.packages = with pkgs; [
    lua-language-server
    typescript-language-server
    pyright
    nil
  ];
}
