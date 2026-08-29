{ pkgs, ... }:
{
  home.packages = [
    pkgs.nerd-fonts.jetbrains-mono
    pkgs.noto-fonts-cjk-sans
    pkgs.noto-fonts-cjk-serif
    pkgs.noto-fonts-color-emoji
  ];
  fonts.fontconfig.enable = true;
  home.sessionVariables.EDITOR = "nvim";
  home.sessionVariables.VISUAL = "nvim";

  home.sessionVariables.BROWSER = "wsl-open";
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
