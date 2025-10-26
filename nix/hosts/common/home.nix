{
  config,
  pkgs,
  ...
}:

{
  home.stateVersion = "25.05";
  home.username = "ningen";
  home.homeDirectory = if pkgs.stdenv.isDarwin then "/Users/ningen" else "/home/ningen";

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
    initContent = ''
      	    export PATH=~/.ghcup/bin/:$PATH
      	  '';
    shellAliases = {
      g = "git";
    };
  };

  # Let Home Manager install and manage itself.
  # programs.home-manager.enable = true;
}
