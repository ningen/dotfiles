{ pkgs, ... }:
let
  orgProtocolClient = pkgs.writeShellScriptBin "org-protocol-client" ''
    exec ${pkgs.emacs}/bin/emacsclient -n -a "" "$@"
  '';
in
{
  xdg.enable = true;
  xdg.desktopEntries.org-protocol = {
    name = "Org Protocol";
    exec = "${orgProtocolClient}/bin/org-protocol-client %u";
    terminal = false;
    type = "Application";
    mimeType = [ "x-scheme-handler/org-protocol" ];
  };
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "x-scheme-handler/org-protocol" = "org-protocol.desktop";
    };
  };
}
