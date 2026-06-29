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
  '';
  end4Ipc = pkgs.writeShellScriptBin "end4-ipc" ''
    exec ${end4Qs}/bin/end4-qs ipc -c ii --any-display call "$@"
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
      awww
      wallust
      matugen
      cliphist
      grim
      swappy
      wl-clipboard
      jq
      imagemagick
      wf-recorder
      hyprpicker
      ddcutil
      brightnessctl
      libqalculate
      qt6Packages.fcitx5-configtool
      fuzzel
      wlogout
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
      end4Ipc
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

  xdg.configFile."quickshell/ii".source = "${end4DotsHyprland}/dots/.config/quickshell/ii";
}
