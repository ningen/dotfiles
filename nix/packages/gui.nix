{ pkgs, ... }: {
  home.packages = with pkgs; [
    discord
    hyprland
    xdg-desktop-portal-hyprland
    waybar
    swww
    rofi-wayland
    obs-studio
    vlc
    alacritty
    playerctl
  ];

  # Firefox設定（MPRIS対応）
  programs.firefox = {
    enable = true;
    profiles.default = {
      settings = {
        # MPRIS (Media Player Remote Interfacing Specification) 有効化
        "media.hardwaremediakeys.enabled" = true;
        "dom.media.mediasession.enabled" = true;
        "media.mediasession.enabled" = true;
      };
    };
  };
}