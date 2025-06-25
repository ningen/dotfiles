{ pkgs, ... }: {
  home.packages = with pkgs; [
    stylua
    black
    prettierd
    nixfmt-rfc-style
  ];
}
