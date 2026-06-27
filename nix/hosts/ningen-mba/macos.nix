{ lib, pkgs, ... }:
let
  karabinerConfig = pkgs.writeText "karabiner.json" (
    builtins.toJSON {
      global = {
        check_for_updates_on_startup = true;
        show_in_menu_bar = true;
        show_profile_name_in_menu_bar = false;
      };
      profiles = [
        {
          name = "Default profile";
          selected = true;
          simple_modifications = [ ];
          fn_function_keys = [ ];
          complex_modifications = {
            parameters = { };
            rules = [ ];
          };
          virtual_hid_keyboard = {
            keyboard_type = "ansi";
            caps_lock_delay_milliseconds = 0;
          };
          devices = [
            {
              identifiers = {
                is_keyboard = true;
                is_pointing_device = false;
                is_built_in_keyboard = false;
              };
              ignore = false;
              manipulate_caps_lock_led = true;
              disable_built_in_keyboard_if_exists = true;
            }
          ];
        }
      ];
    }
  );
in
{
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "symbola" ];

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
  system.activationScripts.karabiner.text = lib.mkAfter ''
    /bin/mkdir -p /Users/ningen/.config/karabiner
    /usr/bin/install -m 0644 -o ningen -g staff ${karabinerConfig} /Users/ningen/.config/karabiner/karabiner.json
  '';
  system.activationScripts.doomProfile.text = lib.mkAfter ''
    /bin/launchctl asuser 501 /bin/launchctl setenv DOOMPROFILE default
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
      "notion"
      "ghostty"
      "cursor"
      "obsidian"
      "raycast"
      "kitty"
      "rectangle"
      "tailscale-app"
      "cmux"
      "docker-desktop"
      "karabiner-elements"
    ];
  };
}
