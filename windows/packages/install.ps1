[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$Upgrade,
    [string]$ManifestPath = (Join-Path $PSScriptRoot 'packages.psd1')
)

$ErrorActionPreference = 'Stop'

if ($PSVersionTable.PSVersion.Major -lt 7) {
    throw 'PowerShell 7 or later is required. Run this script with pwsh.exe.'
}
if (-not (Get-Command winget.exe -ErrorAction SilentlyContinue)) {
    throw 'winget is unavailable. Install or update App Installer, then rerun.'
}
if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) {
    throw "Package manifest not found: $ManifestPath"
}

$manifest = Import-PowerShellDataFile -LiteralPath $ManifestPath
$failed = [Collections.Generic.List[string]]::new()

function Invoke-WingetList([string]$Id) {
    $arguments = @(
        'list', '--exact', '--id', $Id, '--source', 'winget',
        '--accept-source-agreements', '--disable-interactivity'
    )
    & winget.exe @arguments *> $null
    return $LASTEXITCODE -eq 0
}

$upgradeInventory = @()
if ($Upgrade) {
    $upgradeInventory = @(& winget.exe upgrade --source winget --accept-source-agreements --disable-interactivity)
    if ($LASTEXITCODE -ne 0) { throw "Could not query winget upgrades (exit $LASTEXITCODE)." }
}

function Get-InstalledId($Package) {
    $candidateIds = if ($Package.InstalledIds) { @($Package.InstalledIds) } else { @($Package.Id) }
    foreach ($candidateId in $candidateIds) {
        if (Invoke-WingetList -Id $candidateId) { return $candidateId }
    }
    return $null
}

foreach ($package in $manifest.Packages) {
    $installedId = Get-InstalledId -Package $package
    if (-not $installedId) {
        if ($DryRun) {
            Write-Host "INSTALL $($package.Name) [$($package.Id)]"
            continue
        }

        Write-Host "INSTALL $($package.Name) [$($package.Id)]"
        & winget.exe install --exact --id $package.Id --source winget `
            --accept-package-agreements --accept-source-agreements --silent --disable-interactivity
        if ($LASTEXITCODE -ne 0) { $failed.Add("$($package.Name) [$($package.Id)]") }
        continue
    }

    if (-not $Upgrade) {
        Write-Host "NOOP installed $($package.Name) [$installedId]"
        continue
    }

    $upgradePattern = '(?i)(^|\s)' + [regex]::Escape($installedId) + '(\s|$)'
    if (-not ($upgradeInventory -match $upgradePattern)) {
        Write-Host "NOOP current $($package.Name) [$installedId]"
        continue
    }

    if ($DryRun) {
        Write-Host "UPGRADE $($package.Name) [$installedId]"
        continue
    }

    Write-Host "UPGRADE $($package.Name) [$installedId]"
    & winget.exe upgrade --exact --id $installedId --source winget `
        --accept-package-agreements --accept-source-agreements --silent --disable-interactivity
    if ($LASTEXITCODE -ne 0) { $failed.Add("$($package.Name) [$installedId]") }
}

$codeCandidates = @(
    (Join-Path $env:LOCALAPPDATA 'Programs\Microsoft VS Code\bin\code.cmd'),
    (Join-Path $env:ProgramFiles 'Microsoft VS Code\bin\code.cmd')
)
$codeCommand = Get-Command code.cmd -ErrorAction SilentlyContinue
$codePath = if ($codeCommand) { $codeCommand.Source } else {
    $codeCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
}

foreach ($extension in $manifest.VSCodeExtensions) {
    if (-not $codePath) {
        $failed.Add("VS Code extension $extension (code.cmd unavailable until PATH refresh)")
        continue
    }

    $installedExtensions = @(& $codePath --list-extensions 2>$null)
    if ($LASTEXITCODE -ne 0) {
        $failed.Add("VS Code extension inventory $extension")
        continue
    }

    if ($extension -in $installedExtensions -and -not $Upgrade) {
        Write-Host "NOOP installed VS Code extension [$extension]"
        continue
    }

    $action = if ($extension -in $installedExtensions) { 'UPDATE' } else { 'INSTALL' }
    if ($DryRun) {
        Write-Host "$action VS Code extension [$extension]"
        continue
    }

    Write-Host "$action VS Code extension [$extension]"
    & $codePath --install-extension $extension --force
    if ($LASTEXITCODE -ne 0) { $failed.Add("VS Code extension $extension") }
}

if ($failed.Count) {
    $failed | ForEach-Object { Write-Error "FAILED $_" }
    throw "Package installation failed for $($failed.Count) item(s)."
}

Write-Host ($(if ($DryRun) { 'Package dry run complete; no changes made.' } else { 'Package installation complete.' }))
