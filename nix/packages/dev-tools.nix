{ pkgs, ... }:
{
  home.packages = with pkgs; [
    neovim
    zsh
    volta
    uv
    docker
    direnv
    go
    gcc
    lazygit
    tmux
    awscli2
    emacs
  ];
}
