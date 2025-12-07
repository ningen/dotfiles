{ pkgs, ... }:
{
  home.packages = with pkgs; [
    git
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
    ghq
    fzf
  ];
}
