$key = 'HKCU:\Software\Classes\org-protocol'
if (Test-Path $key) { Remove-Item -LiteralPath $key -Recurse -Force }
Write-Host 'Unregistered org-protocol for the current user.'
