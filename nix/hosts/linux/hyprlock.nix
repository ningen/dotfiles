{
  config,
  ...
}:
{
  # hyprlock の設定は Nix で生成し、stylix のターゲットから
  # パレット色（background / input-field の色）を注入してもらう。
  # パッケージは NixOS 側でインストール済み（security.pam.services.hyprlock も設定済み）。
  programs.hyprlock = {
    enable = true;
    package = null;
    settings = {
      general.hide_cursor = false;
      background = {
        # stylix が path（壁紙）と color を注入する。ここではブラーだけ指定。
        blur_passes = 3;
        blur_size = 8;
      };
      input-field = {
        size = "320, 60";
        outline_thickness = 2;
        rounding = 12;
        fade_on_empty = false;
        dots_spacing = 0.3;
        placeholder_text = "Password...";
        fail_text = "Wrong password";
        font_family = "JetBrainsMono Nerd Font";
        position = "0, 0";
        halign = "center";
        valign = "center";
      };
      label = {
        text = "$TIME";
        color = "rgb(${config.lib.stylix.colors.base06})";
        font_size = 88;
        font_family = "JetBrainsMono Nerd Font";
        position = "0, 120";
        halign = "center";
        valign = "top";
      };
    };
    # animations 節は構文が特殊なので生の hyprconf で保持
    extraConfig = ''
      animations {
          enabled = true
          bezier = linear, 1, 1, 0, 0
          animation = fadeIn, 1, 5, linear
          animation = fadeOut, 1, 5, linear
          animation = inputFieldDots, 1, 2, linear
      }
    '';
  };
}
