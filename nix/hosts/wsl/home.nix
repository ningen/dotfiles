{ config, pkgs, ... }:
let
  emacsPackage = config.dotfiles.emacs.package;
  emacsClientWsl = pkgs.writeShellScriptBin "emacsclient-wsl" ''
    set -eu
    client="${emacsPackage}/bin/emacsclient"
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
    exec "$client" --socket-name=default --create-frame --no-wait "$@"
  '';
  orgProtocolClient = pkgs.writeShellScriptBin "org-protocol-client" ''
    set -eu
    if [ "$#" -ne 1 ]; then
      echo "usage: org-protocol-client org-protocol://..." >&2
      exit 64
    fi
    url="$1"
    client="${emacsPackage}/bin/emacsclient"
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
  # Use Emacs's own Mozc input method so Japanese conversion does not depend on
  # WSLg forwarding composition events from the Windows IME.
  dotfiles.emacs.package = (pkgs.emacsPackagesFor pkgs.emacs-pgtk).emacsWithPackages (epkgs: [
    epkgs.mozc
  ]);

  home.packages = [
    emacsClientWsl
    orgProtocolClient
    pkgs.nerd-fonts.jetbrains-mono
    pkgs.noto-fonts-cjk-sans
    pkgs.noto-fonts-cjk-serif
    pkgs.noto-fonts-color-emoji
  ];
  fonts.fontconfig.enable = true;
  # Use the same daemon from both the WSL shell and the Windows launcher so
  # buffers and loaded configuration cannot diverge between launch paths.
  programs.zsh.shellAliases.emacs = "emacsclient-wsl";
  systemd.user.services.emacs-default = {
    Unit = {
      Description = "Emacs daemon (default)";
      After = [ "graphical-session-pre.target" ];
    };
    Service = {
      Type = "notify";
      ExecStart = "${emacsPackage}/bin/emacs --fg-daemon=default";
      ExecStop = "${emacsPackage}/bin/emacsclient --socket-name=default --eval (kill-emacs)";
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
  home.file.".local/bin/win-paste-image" = {
    executable = true;
    text = ''
      #!${pkgs.bash}/bin/bash
      set -eu
      [ "$#" -eq 1 ] || { echo "usage: win-paste-image OUTPUT.png" >&2; exit 64; }

      windows_path="$(/usr/bin/wslpath -w -- "$1")"
      script_path="$(/usr/bin/wslpath -w -- "$HOME/.local/share/dotfiles/win-paste-image.ps1")"
      exec /mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe \
        -NoLogo -NoProfile -NonInteractive -STA -ExecutionPolicy Bypass \
        -File "$script_path" "$windows_path"
    '';
  };
  home.file.".local/share/dotfiles/win-paste-image.ps1".text = ''
    param(
      [Parameter(Mandatory = $true)]
      [string] $OutputPath
    )

    Add-Type -AssemblyName System.Drawing
    Add-Type -AssemblyName System.Windows.Forms

    $image = [System.Windows.Forms.Clipboard]::GetImage()
    if ($null -eq $image) {
      [Console]::Error.WriteLine("Windows clipboard does not contain an image.")
      exit 1
    }

    try {
      $image.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally {
      $image.Dispose()
    }
  '';
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
