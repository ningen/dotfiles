$ErrorActionPreference = 'Stop'
$shortcutPath = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Emacs (WSL).lnk'
if (-not (Test-Path -LiteralPath $shortcutPath)) { exit 0 }
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
if ($shortcut.Description -eq 'ningen-dotfiles: WSL Emacs client') {
    Remove-Item -LiteralPath $shortcutPath -Force
    Write-Host 'Removed managed Emacs (WSL) launcher.'
}
