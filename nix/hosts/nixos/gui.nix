{
  pkgs,
  ...
}:

{
  # GUI の application
  home.packages = with pkgs; [
    slack
    discord
    bitwarden-desktop
  ];
}
