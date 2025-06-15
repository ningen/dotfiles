{pkgs, ...}: {

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
      NSGlobalDomain.AppleShowAllExtensions = true;
      NSGlobalDomain.ApplePressAndHoldEnabled = false;
      finder = {
        AppleShowAllFiles = true;
        AppleShowAllExtensions = true;
      };
      dock = {
        autohide = true;
        show-recents = false;
        orientation = "bottom";
      };
    };
  };


  fonts = {
    packages = with pkgs; [
      jetbrains-mono
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
    ];
    # macos gui apps
    casks = [
      "visual-studio-code"
      # "wezterm"
      "discord"
      "google-chrome"
      "aquaskk"
      "floorp"
      "notion"
      "ghostty"
      "cursor"
      "obsidian"
      "raycast"
    ];
  };
}
