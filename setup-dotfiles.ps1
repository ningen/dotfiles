[CmdletBinding()]
param(
    [switch]$DryRun,
    [string]$ConfigPath = (Join-Path $PSScriptRoot 'dotfiles-links.yaml'),
    [string]$WslDistro,
    [string]$WslUser
)

$ErrorActionPreference = 'Stop'

if ($PSVersionTable.PSVersion.Major -lt 7) {
    throw 'PowerShell 7 or later is required. Run this script with pwsh.exe.'
}

$DotfilesDir = [IO.Path]::GetFullPath($PSScriptRoot)
$ConfigDir = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { $env:APPDATA }
$VSCodeConfigDir = Join-Path $env:APPDATA 'Code\User'
$StateDir = Join-Path $env:LOCALAPPDATA 'ningen-dotfiles'
$StatePath = Join-Path $StateDir 'setup-state.json'
$script:BackupRoot = $null

function Write-Action([string]$Action, [string]$Message) {
    Write-Host ('{0,-8} {1}' -f $Action, $Message)
}

function Test-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-DeveloperMode {
    $key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock'
    try {
        return (Get-ItemPropertyValue -Path $key -Name AllowDevelopmentWithoutDevLicense -ErrorAction Stop) -eq 1
    } catch { return $false }
}

function Normalize-Path([string]$Path) {
    return [IO.Path]::GetFullPath($Path).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
}

function Expand-Target([string]$Value) {
    $Value = $Value.Replace('$CONFIG_DIR', $ConfigDir).Replace('$VSCODE_CONFIG_DIR', $VSCodeConfigDir)
    $Value = $Value.Replace('$HOME', $env:USERPROFILE)
    if ($Value.StartsWith('~')) { $Value = $env:USERPROFILE + $Value.Substring(1) }
    return Normalize-Path $Value
}

function Read-Section([string]$Name) {
    $items = @()
    $active = $false
    $item = $null
    foreach ($line in Get-Content -LiteralPath $ConfigPath) {
        if ($line -match '^([a-z_]+):(?:\s*\[\])?\s*$') {
            if ($active -and $item -and $item.source -and $item.target -and $item.type) { $items += $item }
            $active = $Matches[1] -eq $Name
            $item = $null
            continue
        }
        if (-not $active -or $line.Trim() -eq '' -or $line.TrimStart().StartsWith('#')) { continue }
        if ($line -match '^\s*-\s+source:\s*(.+?)\s*$') {
            if ($item -and $item.source -and $item.target -and $item.type) { $items += $item }
            $item = [ordered]@{ source = $Matches[1]; target = $null; type = $null }
        } elseif ($line -match '^\s+target:\s*(.+?)\s*$') {
            $item.target = $Matches[1]
        } elseif ($line -match '^\s+type:\s*(.+?)\s*$') {
            $item.type = $Matches[1]
        }
    }
    if ($active -and $item -and $item.source -and $item.target -and $item.type) { $items += $item }
    return $items
}

function Get-LinkDestination($Item) {
    if (-not ($Item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { return $null }
    $destination = if ($Item.LinkTarget) { "$($Item.LinkTarget)" } elseif ($Item.Target) { "$(@($Item.Target)[0])" } else { return $null }
    if (-not [IO.Path]::IsPathRooted($destination)) {
        $destination = Join-Path (Split-Path -Parent $Item.FullName) $destination
    }
    return Normalize-Path $destination
}

function Test-CorrectLink([string]$Target, [string]$Source) {
    $item = Get-Item -LiteralPath $Target -Force -ErrorAction SilentlyContinue
    if (-not $item) { return $false }
    $destination = Get-LinkDestination $item
    return $null -ne $destination -and $destination -ieq (Normalize-Path $Source)
}

function Get-BackupPath([string]$Target) {
    if (-not $script:BackupRoot) {
        $script:BackupRoot = Join-Path $StateDir ('backups\' + [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffffffZ'))
    }
    $relative = [IO.Path]::GetRelativePath($env:USERPROFILE, $Target)
    if ($relative.StartsWith('..')) { $relative = $Target -replace '[:*?"<>|]', '_' }
    $backup = Join-Path $script:BackupRoot $relative
    if (Get-Item -LiteralPath $backup -Force -ErrorAction SilentlyContinue) {
        $backup += '.' + [Guid]::NewGuid().ToString('N')
    }
    return $backup
}

function Backup-ExistingItem([string]$Target) {
    $backup = Get-BackupPath $Target
    Write-Action 'BACKUP' "$Target -> $backup"
    if ($DryRun) { return $backup }
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $backup) | Out-Null
    Move-Item -LiteralPath $Target -Destination $backup
    return $backup
}

function Get-BaselineState {
    if (Test-Path -LiteralPath $StatePath) { return Get-Content $StatePath -Raw | ConvertFrom-Json }
    $gitValue = git config --global --get core.autocrlf 2>$null
    return [ordered]@{
        version = 2
        environment = [ordered]@{
            DOTFILES_WINDOWS_REPO = [Environment]::GetEnvironmentVariable('DOTFILES_WINDOWS_REPO', 'User')
            DOTFILES_WSL_DISTRO = [Environment]::GetEnvironmentVariable('DOTFILES_WSL_DISTRO', 'User')
            DOTFILES_WSL_USER = [Environment]::GetEnvironmentVariable('DOTFILES_WSL_USER', 'User')
        }
        git = [ordered]@{ coreAutocrlf = if ($LASTEXITCODE -eq 0) { "$gitValue" } else { $null } }
        terminal = [ordered]@{ originalBackup = $null }
        wslconfig = [ordered]@{ createdBySetup = $null }
    }
}

function Resolve-WslSettings {
    if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) { throw 'wsl.exe is unavailable.' }
    $distros = @(& wsl.exe --list --quiet) | ForEach-Object { ($_ -replace "`0", '').Trim() } |
        Where-Object { $_ -and $_ -notlike 'docker-desktop*' }
    if ($LASTEXITCODE -ne 0) { throw 'Could not enumerate WSL distributions.' }

    if (-not $script:WslDistro) {
        $script:WslDistro = [Environment]::GetEnvironmentVariable('DOTFILES_WSL_DISTRO', 'User')
    }
    if (-not $script:WslDistro) {
        $script:WslDistro = if ('Ubuntu-24.04' -in $distros) { 'Ubuntu-24.04' } else { $distros | Select-Object -First 1 }
    }
    if (-not $script:WslDistro -or $script:WslDistro -notin $distros) {
        throw "WSL distribution not found. Available: $($distros -join ', ')"
    }

    if (-not $script:WslUser) {
        $script:WslUser = [Environment]::GetEnvironmentVariable('DOTFILES_WSL_USER', 'User')
    }
    if (-not $script:WslUser) {
        $script:WslUser = (& wsl.exe -d $script:WslDistro -- sh -lc 'id -un').Trim()
        if ($LASTEXITCODE -ne 0 -or -not $script:WslUser) { throw "Could not detect the default user for $script:WslDistro." }
    }
}

if (-not (Test-Path -LiteralPath $ConfigPath -PathType Leaf)) { throw "Config not found: $ConfigPath" }
Resolve-WslSettings

$links = @((Read-Section 'windows_only') + (Read-Section 'vscode'))
$missing = @()
foreach ($link in $links) {
    $source = Normalize-Path (Join-Path $DotfilesDir $link.source)
    if ($link.type -eq 'file' -and -not (Test-Path -LiteralPath $source -PathType Leaf)) {
        $missing += "missing/non-file source: $source"
    } elseif ($link.type -eq 'directory' -and -not (Test-Path -LiteralPath $source -PathType Container)) {
        $missing += "missing/non-directory source: $source"
    } elseif ($link.type -notin @('file', 'directory')) {
        $missing += "invalid type $($link.type): $source"
    }
}
$terminalTemplate = Join-Path $DotfilesDir 'windows\terminal\profile.template.json'
$wslTemplate = Join-Path $DotfilesDir 'windows\wsl\.wslconfig.example'
$emacsRegistrar = Join-Path $DotfilesDir 'windows\emacs\register-launcher.ps1'
foreach ($required in @($terminalTemplate, $wslTemplate, $emacsRegistrar)) {
    if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { $missing += "missing required file: $required" }
}
if ($missing.Count) {
    $missing | ForEach-Object { Write-Error "Missing/invalid source: $_" }
    throw 'Preflight failed; no changes made.'
}

$linksNeedingChanges = @($links | Where-Object {
    -not (Test-CorrectLink -Target (Expand-Target $_.target) -Source (Join-Path $DotfilesDir $_.source))
})
if (-not $DryRun -and $linksNeedingChanges.Count -and -not (Test-DeveloperMode) -and -not (Test-Administrator)) {
    throw 'Creating symbolic links requires Windows Developer Mode or an elevated PowerShell. Enable Developer Mode manually in Settings, or rerun pwsh as Administrator.'
}

if ($DryRun) {
    Write-Action 'SET' "DOTFILES_WINDOWS_REPO=$DotfilesDir"
    Write-Action 'SET' "DOTFILES_WSL_DISTRO=$script:WslDistro"
    Write-Action 'SET' "DOTFILES_WSL_USER=$script:WslUser"
    Write-Action 'SET' 'git core.autocrlf=false'
} else {
    $state = Get-BaselineState
    New-Item -ItemType Directory -Force -Path $StateDir | Out-Null
    $stateChanged = -not (Test-Path -LiteralPath $StatePath)
    if ($state.environment.PSObject.Properties.Name -notcontains 'DOTFILES_WINDOWS_REPO') {
        $state.environment | Add-Member -NotePropertyName DOTFILES_WINDOWS_REPO `
            -NotePropertyValue ([Environment]::GetEnvironmentVariable('DOTFILES_WINDOWS_REPO', 'User'))
        $stateChanged = $true
    }
    if ($state.version -lt 2) { $state.version = 2; $stateChanged = $true }
    if ($stateChanged) {
        $state | ConvertTo-Json -Depth 8 | Set-Content $StatePath -Encoding utf8NoBOM
    }
    [Environment]::SetEnvironmentVariable('DOTFILES_WINDOWS_REPO', $DotfilesDir, 'User')
    [Environment]::SetEnvironmentVariable('DOTFILES_WSL_DISTRO', $script:WslDistro, 'User')
    [Environment]::SetEnvironmentVariable('DOTFILES_WSL_USER', $script:WslUser, 'User')
    $env:DOTFILES_WINDOWS_REPO = $DotfilesDir
    $env:DOTFILES_WSL_DISTRO = $script:WslDistro
    $env:DOTFILES_WSL_USER = $script:WslUser
    git config --global core.autocrlf false
    if ($LASTEXITCODE -ne 0) { throw 'Could not set git core.autocrlf.' }
}

foreach ($link in $links) {
    $source = Normalize-Path (Join-Path $DotfilesDir $link.source)
    $target = Expand-Target $link.target
    if (Test-CorrectLink -Target $target -Source $source) {
        Write-Action 'NOOP' "$target -> $source"
        continue
    }

    $existing = Get-Item -LiteralPath $target -Force -ErrorAction SilentlyContinue
    if ($existing) { Backup-ExistingItem -Target $target | Out-Null }
    Write-Action 'LINK' "$target -> $source"
    if ($DryRun) { continue }

    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
    New-Item -ItemType SymbolicLink -Path $target -Target $source | Out-Null
}

$fragment = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\Fragments\ningen\wsl.json'
$rendered = (Get-Content $terminalTemplate -Raw).Replace('__DISTRO__', $script:WslDistro).Replace('__USER__', $script:WslUser)
$currentFragment = if (Test-Path -LiteralPath $fragment) { Get-Content $fragment -Raw } else { $null }
if ($currentFragment -ceq $rendered) {
    Write-Action 'NOOP' "Windows Terminal fragment $fragment"
} elseif ($DryRun) {
    Write-Action 'WRITE' "Windows Terminal fragment $fragment"
} else {
    if ((Test-Path -LiteralPath $fragment) -and -not $state.terminal.originalBackup) {
        $backup = Join-Path $StateDir 'terminal-wsl.original.json'
        Copy-Item -LiteralPath $fragment -Destination $backup
        $state.terminal.originalBackup = $backup
    }
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $fragment) | Out-Null
    Set-Content -LiteralPath $fragment -Value $rendered -Encoding utf8NoBOM -NoNewline
    Write-Action 'WRITE' "Windows Terminal fragment $fragment"
}

$wslTarget = Join-Path $env:USERPROFILE '.wslconfig'
if (Test-Path -LiteralPath $wslTarget) {
    Write-Action 'NOOP' "Preserved existing $wslTarget"
} elseif ($DryRun) {
    Write-Action 'COPY' "$wslTemplate -> $wslTarget"
} elseif ($null -eq $state.wslconfig.createdBySetup) {
    Copy-Item -LiteralPath $wslTemplate -Destination $wslTarget
    $state.wslconfig.createdBySetup = $true
    Write-Action 'COPY' "$wslTemplate -> $wslTarget"
}

if ($DryRun) {
    & (Join-Path $DotfilesDir 'windows\emacs\register-launcher.ps1') -DryRun
} else {
    $state | ConvertTo-Json -Depth 8 | Set-Content $StatePath -Encoding utf8NoBOM
    & (Join-Path $DotfilesDir 'windows\emacs\register-launcher.ps1')
}

Write-Host ($(if ($DryRun) { 'Dry run complete; no changes made.' } else { 'Windows dotfiles setup complete.' }))
