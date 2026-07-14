[CmdletBinding()]
param([Parameter(Mandatory = $true, Position = 0)][string]$Url)
$ErrorActionPreference = 'Stop'
$stateDir = Join-Path $env:LOCALAPPDATA 'ningen-dotfiles'
$log = Join-Path $stateDir 'org-protocol.log'
New-Item -ItemType Directory -Force -Path $stateDir | Out-Null
function Write-Stage([string]$Stage, [int]$Code) {
  Add-Content -LiteralPath $log -Value "$(Get-Date -Format o) stage=$Stage exit=$Code"
}
try {
  if (-not $env:DOTFILES_WSL_DISTRO -or -not $env:DOTFILES_WSL_USER) { throw 'DOTFILES_WSL_DISTRO/DOTFILES_WSL_USER are not set.' }
  Write-Stage 'start' 0
  $client = "/home/$($env:DOTFILES_WSL_USER)/.local/bin/org-protocol-client"
  $start = [System.Diagnostics.ProcessStartInfo]::new()
  $start.FileName = 'wsl.exe'; $start.UseShellExecute = $false; $start.CreateNoWindow = $true
  foreach ($argument in @('-d', $env:DOTFILES_WSL_DISTRO, '-u', $env:DOTFILES_WSL_USER, '--', $client, $Url)) { [void]$start.ArgumentList.Add($argument) }
  $process = [System.Diagnostics.Process]::Start($start)
  if (-not $process.WaitForExit(45000)) { $process.Kill(); throw 'WSL org-protocol client timed out.' }
  $code = $process.ExitCode; Write-Stage 'wsl-client' $code
  if ($code -ne 0) { throw "WSL org-protocol client failed with exit code $code." }
  exit 0
} catch {
  Write-Stage 'error' 1
  Add-Type -AssemblyName PresentationFramework
  [System.Windows.MessageBox]::Show($_.Exception.Message, 'org-protocol error', 'OK', 'Error') | Out-Null
  exit 1
}
