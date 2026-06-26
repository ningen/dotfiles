{ pkgs, lib, ... }:
{
  home.packages =
    with pkgs;
    [
      git
      neovim
      zsh
      volta
      uv
      python3
      docker
      docker-compose
      direnv
      go
      gcc
      gnumake
      gh
      lazygit
      tmux
      awscli2
      bitwarden-cli
      emacs
      # emacs vterm dependencies (cross-platform)
      cmake
      ripgrep
      ghq
      fzf
      fd
      pnpm
      nodejs_24
      bun
      go
      gopls
      devenv
      claude-code
      nixd
      yazi
      helix
      rustup
      codex
      tree-sitter
      pandoc
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      # Linux only: emacs vterm dependencies
      libvterm
      libtool
    ];
}
