{ pkgs, ... }: {
  home.packages = with pkgs; [
    stylua
    black
    prettier
    prettierd
    nixfmt
  ];
}
