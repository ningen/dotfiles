{pkgs, ...}: {

  # nix自体の設定
  nix = {
    optimise.automatic = true;
    settings = {
      experimental-features = "nix-command flakes";
      max-jobs = 8;
    };
  };
  services.nix-daemon.enable = true;

  system.stateVersion = 5;

  # システムの設定（nix-darwinが効いているかのテスト）
  system = {
    defaults = {
      NSGlobalDomain.AppleShowAllExtensions = true;
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

  homebrew.enable = true;
  homebrew.onActivation = {
      autoUpdate = true;
      # !! 注意 !!
      cleanup = "uninstall";
  };

  homebrew.casks = [
    "visual-studio-code"
  ];
}