{ pkgs, lib, ... }:
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
    # emacs vterm dependencies
    ripgrep
    ghq
    fzf
    pnpm
    nodejs_24
    bun
    go
    gopls
    devenv
    claude-code
    nixd
  ];
}
