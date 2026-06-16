{
  config,
  pkgs,
  lib,
  ...
}:
{
  home.stateVersion = "25.05";
  home.username = "ningen";
  home.homeDirectory = if pkgs.stdenv.isDarwin then "/Users/ningen" else "/home/ningen";

  # Fonts (Linux/WSL用)
  home.packages = [
    (pkgs.writeShellScriptBin "doom" ''
      exec "$HOME/.config/emacs/bin/doom" "$@"
    '')
  ]
  ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
    pkgs.noto-fonts-cjk-sans
    pkgs.noto-fonts-cjk-serif
    pkgs.nerd-fonts.jetbrains-mono
    pkgs.nerd-fonts.symbols-only
    pkgs.symbola
  ];

  fonts.fontconfig.enable = pkgs.stdenv.isLinux;

  programs.starship = {
    enable = true;
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
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
  home.sessionPath = [
    "$HOME/.config/emacs/bin"
  ];

  home.activation.installDoomEmacs = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    doom_target="$HOME/.config/emacs"
    doom_repo="https://github.com/doomemacs/doomemacs.git"

    if [ -e "$doom_target" ] && [ ! -L "$doom_target" ] && [ ! -x "$doom_target/bin/doom" ]; then
      echo "Refusing to replace non-Doom Emacs config at $doom_target"
      exit 1
    fi

    mkdir -p "$HOME/.config"

    if [ -L "$doom_target" ]; then
      rm "$doom_target"
    fi

    if [ ! -d "$doom_target" ]; then
      ${pkgs.git}/bin/git clone --depth 1 --recurse-submodules "$doom_repo" "$doom_target"
    elif [ -d "$doom_target/.git" ]; then
      echo "Doom Emacs already installed at $doom_target"
      ${pkgs.git}/bin/git -C "$doom_target" submodule update --init --recursive
    else
      echo "Replacing non-git Doom Emacs copy at $doom_target with a git clone"
      doom_tmp="$(${pkgs.coreutils}/bin/mktemp -d)"
      ${pkgs.git}/bin/git clone --depth 1 --recurse-submodules "$doom_repo" "$doom_tmp/emacs"

      if [ -d "$doom_target/.local" ]; then
        mv "$doom_target/.local" "$doom_tmp/local"
      fi

      chmod -R u+w "$doom_target"
      rm -rf "$doom_target"
      mv "$doom_tmp/emacs" "$doom_target"

      if [ -d "$doom_tmp/local" ]; then
        mv "$doom_tmp/local" "$doom_target/.local"
      fi

      rm -rf "$doom_tmp"
    fi
  '';

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      font-name = "JetBrainsMono Nerd Font 11";
      document-font-name = "JetBrainsMono Nerd Font 11";
      monospace-font-name = "JetBrainsMono Nerd Font 11";
    };

    "org/gnome/desktop/wm/keybindings" = {
      switch-input-source = "@as []";
      switch-input-source-backward = "@as []";
    };

    "org/gnome/settings-daemon/plugins/media-keys" = {
      ulauncher-toggle = [ "<Super>space" ];
    };
  };

  programs.zsh = {
    enable = true;
    initContent = builtins.readFile ./zshrc.zsh;
    shellAliases = {
      g = "git";
    };
  };

  # Let Home Manager install and manage itself.
  # programs.home-manager.enable = true;
}
