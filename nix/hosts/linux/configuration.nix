{
  config,
  pkgs,
  inputs,
  ...
}:
let
  # SDDM のセッション一覧から uwsm 版を隠し、素の Hyprland だけにする
  plainHyprlandSession =
    (pkgs.runCommand "hyprland-session" { } ''
      mkdir -p $out/share/wayland-sessions
      ln -s ${config.programs.hyprland.package}/share/wayland-sessions/hyprland.desktop \
        $out/share/wayland-sessions/hyprland.desktop
    '')
    // {
      providedSessions = [ "hyprland" ];
    };
in
{
  # --- Nix ---
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [
      "root"
      "ningen"
    ];
  };
  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [ inputs.neovim-nightly-overlay.overlays.default ];

  # --- Boot ---
  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 10;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  # --- Locale ---
  time.timeZone = "Asia/Tokyo";
  i18n.defaultLocale = "ja_JP.UTF-8";
  console.keyMap = "us";

  # --- Networking ---
  networking.hostName = "ningen-desktop";
  networking.networkmanager.enable = true;

  # --- Graphics: RTX 3060 Ti (i5-12400F has no iGPU) ---
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # Steam / Proton
  };
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    open = false;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
  boot.kernelParams = [ "nvidia-drm.modeset=1" ];

  # --- Desktop ---
  services.xserver.enable = true;
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    theme = "${pkgs.sddm-astronaut}/share/sddm/themes/sddm-astronaut-theme";
    extraPackages = [ pkgs.sddm-astronaut ];
  };
  services.displayManager.defaultSession = "hyprland";
  services.displayManager.sessionPackages = pkgs.lib.mkForce [ plainHyprlandSession ];
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    withUWSM = true;
  };
  xdg.portal.enable = true;

  # --- AirPlay receiver (UxPlay) for iPhone screen mirroring ---
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
    publish = {
      enable = true;
      userServices = true;
    };
  };
  networking.firewall.allowedTCPPorts = [
    7000
    7001
    7100
  ];
  networking.firewall.allowedUDPPorts = [
    6000
    6001
    7011
  ];

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };
  security.rtkit.enable = true;

  # --- Japanese input (fcitx5 + Mozc) ---
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      waylandFrontend = true;
      addons = [ pkgs.fcitx5-mozc ];
      settings.inputMethod = {
        "Groups/0" = {
          Name = "Default";
          "Default Layout" = "us";
          DefaultIM = "keyboard-us";
        };
        "Groups/0/Items/0" = {
          Name = "keyboard-us";
          Layout = "";
        };
        "Groups/0/Items/1" = {
          Name = "mozc";
          Layout = "";
        };
        "GroupOrder" = {
          "0" = "Default";
        };
      };
    };
  };

  # --- Gaming ---
  programs.steam.enable = true;
  programs.gamemode.enable = true;

  # --- Memory ---
  zramSwap.enable = true;

  # --- Fonts ---
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    udev-gothic-nf
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-color-emoji
  ];

  # --- User ---
  users.users.ningen = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "audio"
      "input"
    ];
    shell = pkgs.zsh;
    initialPassword = "changeme";
  };
  programs.zsh.enable = true;

  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    curl
    kitty
    wezterm
    rofi
    waybar
    hyprlock
    qt6Packages.fcitx5-configtool
    discord
    slack
    google-chrome
    bitwarden-desktop
    emacs-pgtk
    uxplay
  ];

  security.pam.services.hyprlock = { };

  system.stateVersion = "26.05";

  # --- Secure Boot (LoL / Vanguard が要求) ---
  # lanzaboote を入れるときに有効化する。flake に input 追加が必要:
  #
  #   inputs.lanzaboote.url = "github:nix-community/lanzaboote/v1.0.0";
  #
  # boot.lanzaboote = {
  #   enable = true;
  #   pkiBundle = "/var/lib/sbctl";
  # };
  # boot.loader.systemd-boot.enable = lib.mkForce false;
}
