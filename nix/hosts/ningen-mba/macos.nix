{ lib, pkgs, ... }:
{

  # nix自体の設定
  nix = {
    optimise.automatic = true;
    settings = {
      experimental-features = "nix-command flakes";
      max-jobs = 8;
    };
  };

  system.stateVersion = 6;
  system.primaryUser = "ningen";

  # システムの設定（nix-darwinが効いているかのテスト）
  system = {
    defaults = {
      NSGlobalDomain = {
        AppleShowAllExtensions = true;
        ApplePressAndHoldEnabled = false;
        "com.apple.keyboard.fnState" = true;
        NSDisableAutomaticTermination = true;
      };
      finder = {
        AppleShowAllFiles = true;
        AppleShowAllExtensions = true;
      };
      dock = {
        autohide = true;
        show-recents = false;
        orientation = "bottom";
      };
      screensaver = {
        askForPassword = false;
        askForPasswordDelay = 0;
      };
    };
  };

  # Codex appをスマホから操作している間にMac本体が寝ると接続が切れるため、
  # 充電中を含めて本体の自動スリープを無効化する。画面は10分で消してよい。
  power.sleep = {
    computer = "never";
    display = 10;
    harddisk = "never";
  };
  system.activationScripts.power.text = lib.mkAfter ''
    /usr/bin/pmset -c disablesleep 1
  '';

  fonts = {
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      nerd-fonts.symbols-only
      symbola
    ];
  };

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "uninstall";
    };
    # macos cli apps
    brews = [
      "ghcup" # TODO: recovered nix package, move dev-tools.nix.
      "libvterm" # emacs vterm dependency
      "libtool" # emacs vterm build dependency (provides glibtool)
    ];
    # macos gui apps
    casks = [
      "visual-studio-code"
      "wezterm"
      "discord"
      "google-chrome"
      "aquaskk"
      "floorp"
      "notion"
      "ghostty"
      "cursor"
      "obsidian"
      "raycast"
      "kitty"
      "rectangle"
      "tailscale-app"
      "zen"
      "docker-desktop"
      "cmux"
    ];
  };
}
