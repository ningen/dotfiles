{
  config,
  pkgs,
  lib,
  ...
}:
let
  emacsGoTreesitGrammars = pkgs.runCommand "emacs-go-treesit-grammars" { } ''
    mkdir -p "$out/lib"
    ln -s ${pkgs.tree-sitter-grammars.tree-sitter-go}/parser "$out/lib/libtree-sitter-go.so"
    ln -s ${pkgs.tree-sitter-grammars.tree-sitter-gomod}/parser "$out/lib/libtree-sitter-gomod.so"
    ln -s ${pkgs.tree-sitter-grammars.tree-sitter-gowork}/parser "$out/lib/libtree-sitter-gowork.so"
  '';
in
{
  options.dotfiles.emacs.package = lib.mkOption {
    type = lib.types.package;
    default = pkgs.emacs;
    description = "Emacs package used by this Home Manager configuration.";
  };

  config.home.packages =
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
      config.dotfiles.emacs.package
      emacsGoTreesitGrammars
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
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      # Linux only: emacs vterm dependencies
      libvterm-neovim
      libtool
      # Codex CLI Linux sandbox dependency
      bubblewrap
    ];
}
