{
  config,
  pkgs,
  ...
}:
let
  repo = "${config.home.homeDirectory}/ghq/github.com/ningen/dotfiles";
in
{
  # stylix の rofi ターゲットにテーマ（config.rasi）を生成させるための有効化。
  # 現在の nixpkgs では rofi 本体に Wayland 対応が統合済みなので、
  # パッケージの差し替えは不要（次回の再ビルドで Wayland ネイティブになる）。
  programs.rofi = {
    enable = true;
    package = pkgs.rofi;
  };

  # cheatsheet のテーマはリポジトリからシンボリックリンクで配信する。
  # （ディレクトリ丸ごとのリンクは config.rasi 生成と競合するため廃止）
  xdg.configFile."rofi/cheatsheet.rasi".source =
    config.lib.file.mkOutOfStoreSymlink "${repo}/_config/rofi/cheatsheet.rasi";
}
