{ pkgs, ... }:
{
  home.packages = with pkgs; [
    neovim
    zsh
    volta
    uv
    docker
    direnv
    ghc
    go
    gcc
    lazygit
    tmux
    awscli2
    emacs
  ];
}
