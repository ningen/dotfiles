[CmdletBinding()]
param([switch]$DryRun)
$ErrorActionPreference = 'Stop'

$shortcutPath = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Emacs (WSL).lnk'
$invokeScript = Join-Path $PSScriptRoot 'invoke-wsl-emacsclient.ps1'
$pwsh = (Get-Command pwsh.exe -ErrorAction Stop).Source

if ($DryRun) {
    Write-Host "WRITE Start Menu shortcut $shortcutPath"
    exit 0
}

$shell = New-Object -ComObject WScript.Shell
if (Test-Path -LiteralPath $shortcutPath) {
    $existing = $shell.CreateShortcut($shortcutPath)
    if ($existing.Description -ne 'ningen-dotfiles: WSL Emacs client') {
        Write-Warning "SKIP existing unmanaged shortcut: $shortcutPath"
        exit 0
    }
}

$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $pwsh
$shortcut.Arguments = "-NoProfile -WindowStyle Hidden -File `"$invokeScript`""
$shortcut.WorkingDirectory = $env:USERPROFILE
$shortcut.Description = 'ningen-dotfiles: WSL Emacs client'
$shortcut.Save()
Write-Host "Registered PowerToys/Start Menu launcher: $shortcutPath"
