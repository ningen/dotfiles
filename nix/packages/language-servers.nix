{ pkgs, ... }: {
  home.packages = with pkgs; [
    lua-language-server
    astro-language-server
    typescript-language-server
    pyright
    nil
  ];
}
