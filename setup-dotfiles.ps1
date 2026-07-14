[CmdletBinding()]
param(
    [switch]$DryRun,
    [string]$ConfigPath = (Join-Path $PSScriptRoot 'dotfiles-links.yaml')
)
$ErrorActionPreference = 'Stop'
$DotfilesDir = $PSScriptRoot
$ConfigDir = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { $env:APPDATA }
$VSCodeConfigDir = Join-Path $env:APPDATA 'Code\User'
$StateDir = Join-Path $env:LOCALAPPDATA 'ningen-dotfiles'
$StatePath = Join-Path $StateDir 'setup-state.json'

function Expand-Target([string]$Value) {
    $Value = $Value.Replace('$CONFIG_DIR', $ConfigDir).Replace('$VSCODE_CONFIG_DIR', $VSCodeConfigDir)
    $Value = $Value.Replace('$HOME', $env:USERPROFILE)
    if ($Value.StartsWith('~')) { $Value = $env:USERPROFILE + $Value.Substring(1) }
    return $Value
}
function Read-Section([string]$Name) {
    $items = @(); $active = $false; $item = $null
    foreach ($line in Get-Content -LiteralPath $ConfigPath) {
        if ($line -match '^([a-z_]+):(?:\s*\[\])?\s*$') {
            if ($active -and $item -and $item.source -and $item.target -and $item.type) { $items += $item }
            $active = $Matches[1] -eq $Name; $item = $null; continue
        }
        if (-not $active -or $line.Trim() -eq '' -or $line.TrimStart().StartsWith('#')) { continue }
        if ($line -match '^\s*-\s+source:\s*(.+?)\s*$') {
            if ($item -and $item.source -and $item.target -and $item.type) { $items += $item }
            $item = [ordered]@{ source = $Matches[1]; target = $null; type = $null }
        } elseif ($line -match '^\s+target:\s*(.+?)\s*$') { $item.target = $Matches[1] }
        elseif ($line -match '^\s+type:\s*(.+?)\s*$') { $item.type = $Matches[1] }
    }
    if ($active -and $item -and $item.source -and $item.target -and $item.type) { $items += $item }
    return $items
}
function Get-BaselineState {
    if (Test-Path -LiteralPath $StatePath) { return Get-Content $StatePath -Raw | ConvertFrom-Json }
    $gitValue = git config --global --get core.autocrlf 2>$null
    return [ordered]@{
        version = 1
        environment = [ordered]@{
            DOTFILES_WSL_DISTRO = [Environment]::GetEnvironmentVariable('DOTFILES_WSL_DISTRO', 'User')
            DOTFILES_WSL_USER = [Environment]::GetEnvironmentVariable('DOTFILES_WSL_USER', 'User')
        }
        git = [ordered]@{ coreAutocrlf = if ($LASTEXITCODE -eq 0) { "$gitValue" } else { $null } }
        terminal = [ordered]@{ originalBackup = $null }
        wslconfig = [ordered]@{ createdBySetup = $null }
    }
}

if (-not (Test-Path -LiteralPath $ConfigPath)) { throw "Config not found: $ConfigPath" }
$links = @((Read-Section 'windows_only') + (Read-Section 'vscode'))
$missing = @()
foreach ($link in $links) {
    $source = Join-Path $DotfilesDir $link.source
    if (-not (Test-Path -LiteralPath $source)) { $missing += $source }
    if ($link.type -notin @('file', 'directory')) { $missing += "invalid type $($link.type): $source" }
}
if ($missing.Count) { $missing | ForEach-Object { Write-Error "Missing/invalid source: $_" }; throw 'Preflight failed; no changes made.' }

$distro = 'Ubuntu-24.04'; $user = 'ningen'
$terminalTemplate = Join-Path $DotfilesDir 'windows\terminal\profile.template.json'
$wslTemplate = Join-Path $DotfilesDir 'windows\wsl\.wslconfig.example'
foreach ($required in @($terminalTemplate, $wslTemplate)) { if (-not (Test-Path $required)) { throw "Missing source: $required" } }

if ($DryRun) {
    Write-Host "SET user environment DOTFILES_WSL_DISTRO=$distro"
    Write-Host "SET user environment DOTFILES_WSL_USER=$user"
} else {
    $state = Get-BaselineState
    New-Item -ItemType Directory -Force -Path $StateDir | Out-Null
    # Persist the first baseline before any managed mutation so an interrupted
    # setup remains rollback-capable. Existing state is never overwritten here.
    if (-not (Test-Path -LiteralPath $StatePath)) {
        $state | ConvertTo-Json -Depth 8 | Set-Content $StatePath -Encoding utf8NoBOM
    }
    [Environment]::SetEnvironmentVariable('DOTFILES_WSL_DISTRO', $distro, 'User')
    [Environment]::SetEnvironmentVariable('DOTFILES_WSL_USER', $user, 'User')
    $env:DOTFILES_WSL_DISTRO = $distro; $env:DOTFILES_WSL_USER = $user
    git config --global core.autocrlf false
}

foreach ($link in $links) {
    $source = Join-Path $DotfilesDir $link.source; $target = Expand-Target $link.target
    if (Test-Path -LiteralPath $target) {
        $existing = Get-Item -LiteralPath $target -Force
        if (-not ($existing.Attributes -band [IO.FileAttributes]::ReparsePoint)) { Write-Warning "SKIP existing non-symlink: $target"; continue }
    }
    if ($DryRun) { Write-Host "LINK $target -> $source"; continue }
    $parent = Split-Path -Parent $target; New-Item -ItemType Directory -Force -Path $parent | Out-Null
    if (Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target -Force }
    New-Item -ItemType SymbolicLink -Path $target -Target $source | Out-Null
    Write-Host "LINKED $target -> $source"
}

$fragment = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\Fragments\ningen\wsl.json'
$rendered = (Get-Content $terminalTemplate -Raw).Replace('__DISTRO__', $distro).Replace('__USER__', $user)
if ($DryRun) { Write-Host "WRITE Windows Terminal fragment $fragment" }
else {
    if ((Test-Path $fragment) -and -not $state.terminal.originalBackup) {
        $backup = Join-Path $StateDir 'terminal-wsl.original.json'; Copy-Item $fragment $backup
        $state.terminal.originalBackup = $backup
    }
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $fragment) | Out-Null
    Set-Content -LiteralPath $fragment -Value $rendered -Encoding utf8NoBOM
}

$wslTarget = Join-Path $env:USERPROFILE '.wslconfig'
if ($DryRun) { if (Test-Path $wslTarget) { Write-Host "SKIP existing $wslTarget" } else { Write-Host "COPY $wslTemplate -> $wslTarget" } }
elseif ($null -eq $state.wslconfig.createdBySetup) {
    if (Test-Path $wslTarget) { $state.wslconfig.createdBySetup = $false }
    else { Copy-Item $wslTemplate $wslTarget; $state.wslconfig.createdBySetup = $true }
}
if (-not $DryRun) { $state | ConvertTo-Json -Depth 8 | Set-Content $StatePath -Encoding utf8NoBOM }
if ($DryRun) { & (Join-Path $DotfilesDir 'windows\emacs\register-launcher.ps1') -DryRun }
else { & (Join-Path $DotfilesDir 'windows\emacs\register-launcher.ps1') }
Write-Host ($(if ($DryRun) { 'Dry run complete; no changes made.' } else { 'Windows dotfiles setup complete.' }))
