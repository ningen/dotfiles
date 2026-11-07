{
  config,
  ...
}:
let
  repo = "${config.home.homeDirectory}/ghq/github.com/ningen/dotfiles";
in
{
  programs.quickshell = {
    enable = true;
    package = null;
    configs.audio = config.lib.file.mkOutOfStoreSymlink "${repo}/_config/quickshell/audio";
    activeConfig = "audio";
  };
}
