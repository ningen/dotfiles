{ pkgs, ... }:
let
  emacsClientWsl = pkgs.writeShellScriptBin "emacsclient-wsl" ''
    set -eu
    if [ "$#" -ne 0 ]; then
      echo "usage: emacsclient-wsl" >&2
      exit 64
    fi
    ${pkgs.systemd}/bin/systemctl --user start emacs-default.service
    exec ${pkgs.emacs}/bin/emacsclient --socket-name=default --create-frame --no-wait
  '';
  orgProtocolClient = pkgs.writeShellScriptBin "org-protocol-client" ''
    set -eu
    if [ "$#" -ne 1 ]; then
      echo "usage: org-protocol-client org-protocol://..." >&2
      exit 64
    fi
    url="$1"
    client="${pkgs.emacs}/bin/emacsclient"
    if ! "$client" --socket-name=default --eval t >/dev/null 2>&1; then
      ${pkgs.systemd}/bin/systemctl --user start emacs-default.service
    fi
    attempts=0
    until "$client" --socket-name=default --eval t >/dev/null 2>&1; do
      attempts=$((attempts + 1))
      if [ "$attempts" -ge 60 ]; then
        echo "timed out waiting for Emacs daemon default" >&2
        exit 1
      fi
      ${pkgs.coreutils}/bin/sleep 0.5
    done
    exec "$client" --socket-name=default --no-wait "$url"
  '';
in
{
  home.packages = [
    pkgs.emacs
    emacsClientWsl
    orgProtocolClient
  ];
  systemd.user.services.emacs-default = {
    Unit = {
      Description = "Emacs daemon (default)";
      After = [ "graphical-session-pre.target" ];
    };
    Service = {
      Type = "notify";
      ExecStart = "${pkgs.emacs}/bin/emacs --fg-daemon=default";
      ExecStop = "${pkgs.emacs}/bin/emacsclient --socket-name=default --eval (kill-emacs)";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "default.target" ];
  };
  home.sessionVariables.BROWSER = "wsl-open";
  home.file.".local/bin/win-copy" = {
    executable = true;
    text = ''
      #!${pkgs.bash}/bin/bash
      exec clip.exe
    '';
  };
  home.file.".local/bin/win-paste" = {
    executable = true;
    text = ''
      #!${pkgs.bash}/bin/bash
      exec powershell.exe -NoProfile -Command Get-Clipboard -Raw
    '';
  };
  home.file.".local/bin/wsl-open" = {
    executable = true;
    text = ''
      #!${pkgs.bash}/bin/bash
      set -eu
      [ "$#" -eq 1 ] || { echo "usage: wsl-open PATH_OR_URL" >&2; exit 64; }
      case "$1" in
        http://*|https://*|mailto:*) exec cmd.exe /c start "" "$1" ;;
        *)
          windows_path="$(wslpath -w "$1")"
          if [ -d "$1" ]; then exec explorer.exe "$windows_path"
          else exec cmd.exe /c start "" "$windows_path"
          fi
          ;;
      esac
    '';
  };
  home.sessionPath = [ "$HOME/.local/bin" ];
}
