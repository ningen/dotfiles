[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$Upgrade,
    [switch]$SkipPackages,
    [switch]$SkipDotfiles,
    [string]$WslDistro,
    [string]$WslUser
)

$ErrorActionPreference = 'Stop'

if ($PSVersionTable.PSVersion.Major -lt 7) {
    throw 'PowerShell 7 or later is required. Run this script with pwsh.exe.'
}

$RepositoryRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))

function Write-Step([string]$Message) {
    Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Test-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-DeveloperMode {
    try {
        return (Get-ItemPropertyValue `
            -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' `
            -Name AllowDevelopmentWithoutDevLicense -ErrorAction Stop) -eq 1
    } catch { return $false }
}

function Invoke-ChildScript([string]$Path, [hashtable]$Arguments) {
    & $Path @Arguments
    if (-not $?) { throw "Script failed: $Path" }
}

Write-Host "Repository: $RepositoryRoot"
Write-Host "Mode:       $(if ($DryRun) { 'dry-run' } else { 'apply' })"
Write-Host "Packages:   $(if ($Upgrade) { 'install and upgrade' } else { 'install missing; keep installed versions' })"

if (-not $SkipDotfiles -and -not (Test-DeveloperMode) -and -not (Test-Administrator)) {
    Write-Warning @'
Developer Mode is disabled and this shell is not elevated. Existing correct links
will still be accepted, but creating or replacing links will fail. Enable Developer
Mode manually in Windows Settings (System > Advanced > For developers), or run
PowerShell as Administrator. This script never changes Developer Mode itself.
'@
}

if (-not $SkipPackages) {
    Write-Step 'Install or inspect Windows packages'
    $packageArguments = @{ DryRun = $DryRun; Upgrade = $Upgrade }
    Invoke-ChildScript -Path (Join-Path $RepositoryRoot 'windows\packages\install.ps1') -Arguments $packageArguments
    $env:PATH = "$env:ProgramFiles\Git\cmd;$env:ProgramFiles\PowerShell\7;$env:PATH"
}

if (-not $SkipDotfiles) {
    Write-Step 'Apply Windows dotfiles'
    $dotfileArguments = @{ DryRun = $DryRun }
    if ($WslDistro) { $dotfileArguments.WslDistro = $WslDistro }
    if ($WslUser) { $dotfileArguments.WslUser = $WslUser }
    Invoke-ChildScript -Path (Join-Path $RepositoryRoot 'setup-dotfiles.ps1') -Arguments $dotfileArguments

    Write-Step 'Register org-protocol for the current user'
    if ($DryRun) {
        Write-Host 'REGISTER HKCU:\Software\Classes\org-protocol'
    } else {
        Invoke-ChildScript -Path (Join-Path $RepositoryRoot 'windows\org-protocol\register.ps1') -Arguments @{}
    }
}

Write-Host @"

Bootstrap complete.

No reboot or logout was requested. Newly installed command paths may require a new
PowerShell session. GlazeWM and YASB startup can be enabled from their tray menus
after their first successful launch.
"@ -ForegroundColor Green
