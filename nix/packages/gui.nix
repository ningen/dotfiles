{ pkgs, ... }: {
  home.packages = with pkgs; [
    firefox
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
}