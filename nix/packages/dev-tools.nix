{ pkgs, ... }:
{
  home.packages = with pkgs; [
    neovim
    zsh
    volta
    uv
    docker
    docker-compose
    direnv
    go
    gcc
    gh
    lazygit
    tmux
    awscli2
    emacs
    ripgrep
  ];
}
