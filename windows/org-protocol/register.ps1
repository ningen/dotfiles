$ErrorActionPreference = 'Stop'
$handler = Join-Path $PSScriptRoot 'invoke-wsl-emacs.ps1'
$pwsh = (Get-Command pwsh.exe).Source
$root = 'HKCU:\Software\Classes\org-protocol'
New-Item -Path $root -Force | Out-Null
Set-Item -Path $root -Value 'URL:Org Protocol'
New-ItemProperty -Path $root -Name 'URL Protocol' -Value '' -PropertyType String -Force | Out-Null
$command = New-Item -Path "$root\shell\open\command" -Force
Set-Item -Path $command.PSPath -Value ('"{0}" -NoProfile -File "{1}" "%1"' -f $pwsh, $handler)
Write-Host 'Registered org-protocol for the current user.'
