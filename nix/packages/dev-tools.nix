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
      direnv
      go
      gcc
      gnumake
      gh
      lazygit
      tmux
      awscli2
      bitwarden-cli
      jq
      ripgrep
      ghq
      fzf
      fd
      pnpm
      nodejs_24
      bun
      gopls
      gotools
      gofumpt
      golangci-lint
      devenv
      claude-code
      nixd
      yazi
      helix
      rustup
      codex
      tree-sitter
      pandoc
      sbcl
      herdr
      google-cloud-sdk
      opencode
      chromium
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      # Codex CLI Linux sandbox dependency
      bubblewrap
    ];
}
