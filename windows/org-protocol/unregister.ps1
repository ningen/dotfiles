$ErrorActionPreference = 'Stop'
$key = 'HKCU:\Software\Classes\org-protocol'
if (-not (Test-Path -LiteralPath $key)) { exit 0 }
$owner = try {
  Get-ItemPropertyValue -LiteralPath $key -Name 'ningen-dotfiles' -ErrorAction Stop
} catch {
  $null
}
if ($owner -ne 'org-protocol-v1') {
  Write-Warning "Preserved unmanaged org-protocol handler: $key"
  exit 0
}
Remove-Item -LiteralPath $key -Recurse -Force
Write-Host 'Unregistered managed org-protocol handler for the current user.'
