{
  config,
  pkgs,
  inputs,
  ...
}:
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
  };
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };
  xdg.portal.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };
  security.rtkit.enable = true;

  # --- Gaming ---
  programs.steam.enable = true;
  programs.gamemode.enable = true;

  # --- Memory ---
  zramSwap.enable = true;

  # --- Fonts ---
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
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
  ];

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
