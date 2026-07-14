$ErrorActionPreference = 'Stop'
$statePath = Join-Path $env:LOCALAPPDATA 'ningen-dotfiles\setup-state.json'
if (-not (Test-Path $statePath)) { throw "Setup state not found: $statePath" }
$state = Get-Content $statePath -Raw | ConvertFrom-Json
[Environment]::SetEnvironmentVariable('DOTFILES_WSL_DISTRO', $state.environment.DOTFILES_WSL_DISTRO, 'User')
[Environment]::SetEnvironmentVariable('DOTFILES_WSL_USER', $state.environment.DOTFILES_WSL_USER, 'User')
if ($null -eq $state.git.coreAutocrlf) { git config --global --unset core.autocrlf 2>$null }
else { git config --global core.autocrlf "$($state.git.coreAutocrlf)" }
$fragment = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\Fragments\ningen\wsl.json'
if ($state.terminal.originalBackup -and (Test-Path $state.terminal.originalBackup)) { Copy-Item $state.terminal.originalBackup $fragment -Force }
elseif (Test-Path $fragment) { Remove-Item $fragment -Force }
$wslconfig = Join-Path $env:USERPROFILE '.wslconfig'
if ($state.wslconfig.createdBySetup -eq $true -and (Test-Path $wslconfig)) { Remove-Item $wslconfig -Force }
& (Join-Path $PSScriptRoot 'org-protocol\unregister.ps1')
& (Join-Path $PSScriptRoot 'emacs\unregister-launcher.ps1')
Write-Host 'Managed Windows settings rolled back. Existing non-managed files were preserved.'
