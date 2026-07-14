[CmdletBinding()]
param()
$ErrorActionPreference = 'Continue'
$packages = @(
  'wez.wezterm', 'Microsoft.VisualStudioCode', 'Docker.DockerDesktop',
  'Google.Chrome', 'Microsoft.PowerShell', 'Git.Git', 'Microsoft.WindowsTerminal',
  'Obsidian.Obsidian', 'Discord.Discord', 'DEVCOM.JetBrainsMonoNerdFont'
)
$failed = @()
foreach ($id in $packages) {
  winget list --exact --id $id --accept-source-agreements | Out-Null
  if ($LASTEXITCODE -eq 0) { Write-Host "SKIP installed: $id"; continue }
  winget install --exact --id $id --accept-package-agreements --accept-source-agreements --silent
  if ($LASTEXITCODE -ne 0) { $failed += $id }
}
$codeCandidates = @(
  (Join-Path $env:LOCALAPPDATA 'Programs\Microsoft VS Code\bin\code.cmd'),
  (Join-Path $env:ProgramFiles 'Microsoft VS Code\bin\code.cmd')
)
$codeCommand = Get-Command code.cmd -ErrorAction SilentlyContinue
$codePath = if ($codeCommand) { $codeCommand.Source } else { $codeCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1 }
if ($codePath) {
  & $codePath --install-extension ms-vscode-remote.remote-wsl --force
  if ($LASTEXITCODE -ne 0) { $failed += 'VSCode extension: ms-vscode-remote.remote-wsl' }
} else { $failed += 'VSCode CLI unavailable' }
if ($failed.Count) { Write-Error ('Installation failed: ' + ($failed -join ', ')); exit 1 }
Write-Host 'Package installation complete. Run setup-dotfiles.ps1 next.'
