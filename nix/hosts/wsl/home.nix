{ pkgs, ... }:
let
  orgProtocolClient = pkgs.writeShellScriptBin "org-protocol-client" ''
    set -eu
    if [ "$#" -ne 1 ]; then
      echo "usage: org-protocol-client org-protocol://..." >&2
      exit 64
    fi
    url="$1"
    export DOOMPROFILE=default
    client="${pkgs.emacs}/bin/emacsclient"
    if ! "$client" --socket-name=default --eval t >/dev/null 2>&1; then
      ${pkgs.emacs}/bin/emacs --daemon=default >/dev/null 2>&1 &
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
    orgProtocolClient
  ];
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
