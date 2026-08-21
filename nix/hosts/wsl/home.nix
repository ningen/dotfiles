{ config, pkgs, ... }:
let
  emacsPackage = config.dotfiles.emacs.package;
  importWslInteropEnvironment = ''
    if [ -n "''${WSL_INTEROP:-}" ]; then
      if ! ${pkgs.systemd}/bin/systemctl --user import-environment WSL_INTEROP WSL_DISTRO_NAME; then
        echo "warning: could not refresh the systemd WSL environment" >&2
      fi
    fi
  '';
  emacsClientWsl = pkgs.writeShellScriptBin "emacsclient-wsl" ''
    set -eu
    ${importWslInteropEnvironment}
    exec ${emacsPackage}/bin/emacsclient \
      --alternate-editor=false --create-frame --no-wait "$@"
  '';
  orgProtocolClient = pkgs.writeShellScriptBin "org-protocol-client" ''
    set -eu
    if [ "$#" -ne 1 ]; then
      echo "usage: org-protocol-client org-protocol://..." >&2
      exit 64
    fi
    ${importWslInteropEnvironment}
    url="$1"
    exec ${emacsPackage}/bin/emacsclient \
      --alternate-editor=false --no-wait "$url"
  '';
  refreshEmacsWsl = pkgs.writeShellScriptBin "refresh-emacs-wsl" ''
    set -eu
    client="${emacsPackage}/bin/emacsclient"

    # Migrate the former named daemon without risking unsaved buffers.
    if ${pkgs.systemd}/bin/systemctl --user is-active --quiet emacs-default.service; then
      if ! modified="$("$client" --socket-name=default \
        --eval "(seq-some #'buffer-modified-p (buffer-list))" 2>/dev/null)"; then
        echo "Could not query the legacy Emacs daemon; it was not stopped." >&2
        exit 1
      fi
      if [ "$modified" != "nil" ]; then
        echo "Cannot stop the legacy Emacs daemon because it has modified buffers." >&2
        echo "Save them and rerun refresh-emacs-wsl." >&2
        exit 1
      fi
      ${pkgs.systemd}/bin/systemctl --user stop emacs-default.service
    fi

    ${pkgs.systemd}/bin/systemctl --user start emacs.socket
    if ${pkgs.systemd}/bin/systemctl --user is-active --quiet emacs.service; then
      if ! modified="$("$client" \
        --eval "(seq-some #'buffer-modified-p (buffer-list))" 2>/dev/null)"; then
        echo "Could not query the Emacs daemon; it was not restarted." >&2
        exit 1
      fi
      if [ "$modified" = "nil" ]; then
        ${pkgs.systemd}/bin/systemctl --user restart emacs.service
      else
        echo "Emacs restart skipped because it has modified buffers." >&2
        echo "Save them, then run: systemctl --user restart emacs.service" >&2
      fi
    fi
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
    refreshEmacsWsl
    pkgs.nerd-fonts.jetbrains-mono
    pkgs.noto-fonts-cjk-sans
    pkgs.noto-fonts-cjk-serif
    pkgs.noto-fonts-color-emoji
  ];
  fonts.fontconfig.enable = true;
  # The shell and Windows launcher both connect to Home Manager's standard
  # socket. systemd starts the daemon on the first client connection.
  programs.zsh.shellAliases.emacs = "emacsclient-wsl";
  programs.zsh.shellAliases.onvim = "NVIM_APPNAME=old-nvim nvim";

  services.emacs = {
    enable = true;
    package = emacsPackage;
    socketActivation.enable = true;
    startWithUserSession = false;
    defaultEditor = true;
  };

  home.sessionVariables.BROWSER = "wsl-open";
  # Windows invokes this stable path directly. The source remains a Nix store
  # script, while the public path does not depend on profile package linking.
  home.file.".local/bin/org-protocol-client" = {
    executable = true;
    source = "${orgProtocolClient}/bin/org-protocol-client";
  };
  home.file.".local/bin/win-copy" = {
    executable = true;
    text = ''
      #!${pkgs.bash}/bin/bash
      set -o pipefail
      ${pkgs.glibc.bin}/bin/iconv -f UTF-8 -t UTF-16LE | \
        /mnt/c/Windows/System32/clip.exe
    '';
  };
  home.file.".local/bin/win-paste" = {
    executable = true;
    text = ''
      #!${pkgs.bash}/bin/bash
      exec /mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe \
        -NoLogo -NoProfile -NonInteractive \
        -Command '[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false); [Console]::Out.Write((Get-Clipboard -Raw))'
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
        http://*|https://*|mailto:*)
          exec rundll32.exe url.dll,FileProtocolHandler "$1"
          ;;
        *)
          windows_path="$(wslpath -w -- "$1")"
          if [ -d "$1" ]; then exec explorer.exe "$windows_path"
          else exec rundll32.exe url.dll,FileProtocolHandler "$windows_path"
          fi
          ;;
      esac
    '';
  };
  home.sessionPath = [ "$HOME/.local/bin" ];
}
