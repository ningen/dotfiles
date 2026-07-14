{ pkgs, ... }:
let
  orgProtocolClient = pkgs.writeShellScriptBin "org-protocol-client" ''
    exec ${pkgs.emacs}/bin/emacsclient -n --alternate-editor=false "$@"
  '';
in
{
  home.packages = with pkgs; [
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    material-symbols
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
    symbola
  ];
  fonts.fontconfig.enable = true;

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      font-name = "JetBrainsMono Nerd Font 11";
      document-font-name = "JetBrainsMono Nerd Font 11";
      monospace-font-name = "JetBrainsMono Nerd Font 11";
    };
    "org/gnome/desktop/wm/keybindings" = {
      switch-input-source = "@as []";
      switch-input-source-backward = "@as []";
    };
  };

  xdg.enable = true;
  xdg.dataFile."applications/org-protocol.desktop".text = ''
    [Desktop Entry]
    Name=Org Protocol
    Exec=${orgProtocolClient}/bin/org-protocol-client %u
    MimeType=x-scheme-handler/org-protocol;
    Terminal=false
    Type=Application
    Version=1.5
  '';
  xdg.dataFile."applications/mimeinfo.cache".text = ''
    [MIME Cache]
    x-scheme-handler/org-protocol=org-protocol.desktop;
  '';
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/x-extension-htm" = "firefox.desktop";
      "application/x-extension-html" = "firefox.desktop";
      "application/x-extension-shtml" = "firefox.desktop";
      "application/x-extension-xht" = "firefox.desktop";
      "application/x-extension-xhtml" = "firefox.desktop";
      "application/xhtml+xml" = "firefox.desktop";
      "text/html" = "google-chrome.desktop";
      "x-scheme-handler/about" = "google-chrome.desktop";
      "x-scheme-handler/chrome" = "firefox.desktop";
      "x-scheme-handler/claude-cli" = "claude-code-url-handler.desktop";
      "x-scheme-handler/http" = "google-chrome.desktop";
      "x-scheme-handler/https" = "google-chrome.desktop";
      "x-scheme-handler/org-protocol" = "org-protocol.desktop";
      "x-scheme-handler/unknown" = "google-chrome.desktop";
    };
    associations.added = {
      "application/x-extension-htm" = "firefox.desktop";
      "application/x-extension-html" = "firefox.desktop";
      "application/x-extension-shtml" = "firefox.desktop";
      "application/x-extension-xht" = "firefox.desktop";
      "application/x-extension-xhtml" = "firefox.desktop";
      "application/xhtml+xml" = "firefox.desktop";
      "text/html" = "firefox.desktop";
      "x-scheme-handler/chrome" = "firefox.desktop";
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "x-scheme-handler/org-protocol" = "org-protocol.desktop";
    };
    associations.removed = {
      "x-scheme-handler/org-protocol" = "emacsclient.desktop";
    };
  };
  xdg.configFile."mimeapps.list".force = true;
  xdg.dataFile."applications/mimeapps.list".force = true;
}
