{
  config,
  pkgs,
  ...
}:

let
  nodePkgs = pkgs.callPackage ./node2nix { inherit pkgs; };
in
{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.

  targets.genericLinux.enable = true;

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.05"; # Please read the comment before changing.

  home.username = "ningen";
  home.homeDirectory = if pkgs.stdenv.isDarwin then "/Users/ningen" else "/home/ningen";

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs;
    let
      dev-tools = [
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
      ];
      language-servers = [
        lua-language-server
        typescript-language-server
        pyright
        nil
      ];
      formatters = [
        stylua
        black
        prettierd
        nixfmt-rfc-style
      ];
      node-packages = [
        nodePkgs."@anthropic-ai/claude-code"
        nodePkgs."@google/gemini-cli"
      ];
    in
    dev-tools ++ language-servers ++ formatters ++ node-packages;

  programs.starship = {
    enable = true;
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = { };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/ningen/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  programs.zsh = {
    enable = true;
    initContent = '''';
  };

  # Let Home Manager install and manage itself.
  # programs.home-manager.enable = true;
}
