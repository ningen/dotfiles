{
  pkgs,
  ...
}:

{
  # GUI の application
  home.packages = with pkgs; [
    slack
    bitwarden-desktop
  ];
}
