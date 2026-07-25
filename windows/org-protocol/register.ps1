[CmdletBinding()]
param([switch]$DryRun)
$ErrorActionPreference = 'Stop'
$handler = Join-Path $PSScriptRoot 'invoke-wsl-emacs.ps1'
$pwsh = (Get-Command pwsh.exe).Source
$root = 'HKCU:\Software\Classes\org-protocol'
$commandPath = "$root\shell\open\command"

if (Test-Path -LiteralPath $root) {
  $owner = try {
    Get-ItemPropertyValue -LiteralPath $root -Name 'ningen-dotfiles' -ErrorAction Stop
  } catch {
    $null
  }
  $currentCommand = if (Test-Path -LiteralPath $commandPath) {
    (Get-Item -LiteralPath $commandPath).GetValue('')
  } else {
    $null
  }
  $isLegacyManaged = $currentCommand -and
    ($currentCommand.Contains($handler, [StringComparison]::OrdinalIgnoreCase) -or
     $currentCommand -match '[\\/]windows[\\/]org-protocol[\\/]invoke-wsl-emacs\.ps1')
  if ($owner -ne 'org-protocol-v1' -and -not $isLegacyManaged) {
    throw "Refusing to overwrite an unmanaged org-protocol handler at $root."
  }
}

if ($DryRun) {
  Write-Host "REGISTER managed org-protocol handler -> $handler"
  exit 0
}

New-Item -Path $root -Force | Out-Null
Set-Item -Path $root -Value 'URL:Org Protocol'
New-ItemProperty -Path $root -Name 'URL Protocol' -Value '' -PropertyType String -Force | Out-Null
New-ItemProperty -Path $root -Name 'ningen-dotfiles' -Value 'org-protocol-v1' -PropertyType String -Force | Out-Null
$command = New-Item -Path $commandPath -Force
Set-Item -Path $command.PSPath -Value ('"{0}" -NoProfile -File "{1}" "%1"' -f $pwsh, $handler)
Write-Host 'Registered org-protocol for the current user.'
