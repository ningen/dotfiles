{ pkgs, ... }:
let
  end4QtRuntimePackages = with pkgs; [
    qt6Packages.qt5compat
    qt6Packages.qtpositioning
    qt6Packages.qtmultimedia
    qt6Packages.qtsensors
    qt6Packages.qtsvg
    kdePackages.syntax-highlighting
    kdePackages.kirigami.unwrapped
  ];
  end4QmlImportPath = pkgs.lib.makeSearchPath "lib/qt-6/qml" end4QtRuntimePackages;
  end4QtPluginPath = pkgs.lib.makeSearchPath "lib/qt-6/plugins" end4QtRuntimePackages;
  end4Qs = pkgs.writeShellScriptBin "end4-qs" ''
    export QML2_IMPORT_PATH="${end4QmlImportPath}''${QML2_IMPORT_PATH:+:}''${QML2_IMPORT_PATH:-}"
    export QT_PLUGIN_PATH="${end4QtPluginPath}''${QT_PLUGIN_PATH:+:}''${QT_PLUGIN_PATH:-}"
    exec ${pkgs.quickshell}/bin/qs "$@"
  '';
  end4Launcher = pkgs.writeShellScriptBin "end4-launcher" ''
    if ${end4Qs}/bin/end4-qs ipc -c ii --any-display call search toggle; then
      exit 0
    fi

    if ! ${end4Qs}/bin/end4-qs -c ii list --all | ${pkgs.gnugrep}/bin/grep -q "Config path: .*quickshell/ii/shell.qml"; then
      ${end4Qs}/bin/end4-qs -d -c ii
      ${pkgs.coreutils}/bin/sleep 0.4

      if ${end4Qs}/bin/end4-qs ipc -c ii --any-display call search open; then
        exit 0
      fi
    fi

    exec ${pkgs.rofi}/bin/rofi -show drun
  '';
  end4DotsHyprland = pkgs.fetchFromGitHub {
    owner = "end-4";
    repo = "dots-hyprland";
    rev = "c04b0bbc8143a2b2166c1f699f7583cb28ff78fe";
    hash = "sha256-UxCPWLQYFlPEyqqOJ+Xxv+SvYTo0JRA9d3DFqPtNCmg=";
    fetchSubmodules = true;
  };
in
{
  home.packages =
    (with pkgs; [
      discord
      hyprland
      xdg-desktop-portal-hyprland
      hypridle
      hyprlock
      quickshell
      (waybar.override { cavaSupport = true; })
      awww
      eww
      wallust
      matugen
      cliphist
      swappy
      hyprpicker
      ddcutil
      brightnessctl
      libqalculate
      qt6Packages.fcitx5-configtool
      fuzzel
      wlogout
      # rofi-wayland
      rofi
      obs-studio
      vlc
      alacritty
      ghostty
      playerctl
      slack
      google-chrome
      adwaita-icon-theme
    ])
    ++ end4QtRuntimePackages
    ++ [
      end4Qs
      end4Launcher
    ];

  home.pointerCursor = {
    package = pkgs.adwaita-icon-theme;
    name = "Adwaita";
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  # Firefox設定（MPRIS対応）
  programs.firefox = {
    enable = true;
    configPath = ".mozilla/firefox";
    profiles.default = {
      settings = {
        # MPRIS (Media Player Remote Interfacing Specification) 有効化
        "media.hardwaremediakeys.enabled" = true;
        "dom.media.mediasession.enabled" = true;
        "media.mediasession.enabled" = true;
      };
    };
  };

  xdg.configFile."eww/eww.yuck".text = ''
    (defwindow hypr-keymap
      :monitor 0
      :geometry (geometry
        :x "28px"
        :y "58px"
        :width "360px"
        :height "520px"
        :anchor "top left")
      :stacking "bg"
      :exclusive false
      :focusable false
      :namespace "hypr-keymap"
      (box :class "keymap" :orientation "v" :space-evenly false
        (label :class "title" :xalign 0 :text "Hyprland keys")
        (box :class "section" :orientation "v" :space-evenly false
          (label :class "section-title" :xalign 0 :text "Apps")
          (label :xalign 0 :text "Super + Q      Terminal")
          (label :xalign 0 :text "Super + Space  Launcher")
          (label :xalign 0 :text "Super + E      File manager")
          (label :xalign 0 :text "Super + L      Lock")
          (label :xalign 0 :text "Ctrl + Space   Toggle Mozc"))
        (box :class "section" :orientation "v" :space-evenly false
          (label :class "section-title" :xalign 0 :text "Windows")
          (label :xalign 0 :text "Super + C      Close")
          (label :xalign 0 :text "Super + V      Floating")
          (label :xalign 0 :text "Super + P      Pseudo")
          (label :xalign 0 :text "Super + J      Split")
          (label :xalign 0 :text "Super + Arrows Focus"))
        (box :class "section" :orientation "v" :space-evenly false
          (label :class "section-title" :xalign 0 :text "Workspaces")
          (label :xalign 0 :text "Super + 1..0       Switch")
          (label :xalign 0 :text "Super + Shift + N  Move")
          (label :xalign 0 :text "Super + S          Scratch")
          (label :xalign 0 :text "Super + Shift + S  Send scratch"))
        (box :class "section" :orientation "v" :space-evenly false
          (label :class "section-title" :xalign 0 :text "Screenshots")
          (label :xalign 0 :text "Print        Active")
          (label :xalign 0 :text "Shift+Print  Area")
          (label :xalign 0 :text "Ctrl+Print   Screen"))))
  '';

  xdg.configFile."eww/eww.scss".text = ''
    * {
      all: unset;
      font-family: "JetBrainsMono Nerd Font", "Noto Sans CJK JP", sans-serif;
    }

    .keymap {
      background: rgba(0, 0, 0, 0.44);
      border: 1px solid rgba(229, 233, 240, 0.22);
      border-radius: 8px;
      color: rgba(229, 233, 240, 0.88);
      padding: 16px 18px;
    }

    .title {
      color: #eceff4;
      font-size: 19px;
      font-weight: 700;
      margin-bottom: 12px;
    }

    .section {
      margin-top: 10px;
    }

    .section-title {
      color: #88c0d0;
      font-size: 15px;
      font-weight: 700;
      margin-bottom: 4px;
    }

    label {
      font-size: 13px;
      line-height: 1.42;
    }
  '';

  xdg.configFile."quickshell/ii".source = "${end4DotsHyprland}/dots/.config/quickshell/ii";
}
