[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'

if (-not $env:DOTFILES_WSL_DISTRO -or -not $env:DOTFILES_WSL_USER) {
    throw 'DOTFILES_WSL_DISTRO/DOTFILES_WSL_USER are not set.'
}

$client = "/home/$($env:DOTFILES_WSL_USER)/.nix-profile/bin/emacsclient-wsl"
$start = [System.Diagnostics.ProcessStartInfo]::new()
$start.FileName = 'wsl.exe'
$start.UseShellExecute = $false
$start.CreateNoWindow = $true
foreach ($argument in @('-d', $env:DOTFILES_WSL_DISTRO, '-u', $env:DOTFILES_WSL_USER, '--', $client)) {
    [void]$start.ArgumentList.Add($argument)
}
$process = [System.Diagnostics.Process]::Start($start)
$process.WaitForExit()
exit $process.ExitCode
