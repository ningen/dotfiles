{
  pkgs,
  ...
}:
{
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    BROWSER = "google-chrome-stable";
  };

  programs.zsh.shellAliases.dsh = "LD_PRELOAD=$HOME/.local/share/dsh-nix-fix/libdsh-getter-fix.so npx @deepseek-ai/dsh";

  services.mako = {
    enable = true;
    settings = {
      anchor = "top-right";
      "default-timeout" = 5000;
      "max-visible" = 5;
      layer = "overlay";
      margin = 12;
      padding = 10;
      width = 360;
      height = 180;
      icons = true;
      markup = true;
      actions = true;
      "border-size" = 2;
      "border-radius" = 12;
    };
  };

  systemd.user.services.mako = {
    Unit = {
      Description = "Mako notification daemon";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.mako}/bin/mako";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  services.cliphist = {
    enable = true;
    allowImages = true;
  };

  services.wl-clip-persist = {
    enable = true;
    clipboardType = "regular";
  };
}
