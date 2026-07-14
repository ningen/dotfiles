[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$RepositoryUrl = 'https://github.com/ningen/dotfiles.git'
$Distro = 'Ubuntu-24.04'
$WslUser = 'ningen'
$RepoDir = Join-Path $env:USERPROFILE 'ghq\github.com\ningen\dotfiles'

function Write-Step([string]$Message) {
    Write-Host "`n==> $Message" -ForegroundColor Cyan
}
function Test-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}
function Install-WingetPackage([string]$Id) {
    winget list --exact --id $Id --accept-source-agreements | Out-Null
    if ($LASTEXITCODE -eq 0) { Write-Host "Already installed: $Id"; return }
    winget install --exact --id $Id --accept-package-agreements --accept-source-agreements --silent
    if ($LASTEXITCODE -ne 0) { throw "winget failed for $Id (exit $LASTEXITCODE)" }
}
function Invoke-Native([scriptblock]$Command, [string]$FailureMessage) {
    & $Command
    if ($LASTEXITCODE -ne 0) { throw "$FailureMessage (exit $LASTEXITCODE)" }
}

if (-not [Environment]::Is64BitOperatingSystem -or $env:PROCESSOR_ARCHITECTURE -notin @('AMD64', 'ARM64')) {
    throw 'This bootstrap requires 64-bit Windows. The migration plan expects x86_64/AMD64.'
}
if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') {
    throw 'ARM64 was detected, but the migration plan is fixed to x86_64. Stop and revise PLAN.md first.'
}
if (-not (Test-Administrator)) {
    throw 'Open PowerShell as Administrator and run this command again.'
}
if (-not (Get-Command winget.exe -ErrorAction SilentlyContinue)) {
    throw 'winget is unavailable. Install/update App Installer from Microsoft Store, then rerun.'
}

Write-Step 'Enable Windows Developer Mode'
$developerKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock'
New-Item -Path $developerKey -Force | Out-Null
New-ItemProperty -Path $developerKey -Name AllowDevelopmentWithoutDevLicense -Value 1 -PropertyType DWord -Force | Out-Null

Write-Step 'Install Git and PowerShell 7'
Install-WingetPackage 'Git.Git'
Install-WingetPackage 'Microsoft.PowerShell'
$env:PATH = "$env:ProgramFiles\Git\cmd;$env:ProgramFiles\PowerShell\7;$env:PATH"
if (-not (Get-Command git.exe -ErrorAction SilentlyContinue)) { throw 'Git was installed but is not visible in PATH. Restart Windows and rerun.' }
if (-not (Get-Command pwsh.exe -ErrorAction SilentlyContinue)) { throw 'PowerShell 7 was installed but is not visible in PATH. Restart Windows and rerun.' }

Write-Step 'Clone or update the Windows dotfiles checkout'
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $RepoDir) | Out-Null
if (Test-Path (Join-Path $RepoDir '.git')) {
    Invoke-Native { git -C $RepoDir pull --ff-only } 'Could not update the Windows dotfiles checkout'
} else {
    Invoke-Native { git clone --recurse-submodules $RepositoryUrl $RepoDir } 'Could not clone the dotfiles repository'
}
Invoke-Native { git -C $RepoDir submodule update --init --recursive } 'Could not initialize dotfiles submodules'

Write-Step 'Install Windows applications'
Invoke-Native { pwsh.exe -NoProfile -File (Join-Path $RepoDir 'windows\packages\install.ps1') } 'Windows package installation failed'

Write-Step 'Apply Windows dotfiles and register org-protocol'
Invoke-Native { pwsh.exe -NoProfile -File (Join-Path $RepoDir 'setup-dotfiles.ps1') -DryRun } 'Windows dotfiles dry-run failed'
Invoke-Native { pwsh.exe -NoProfile -File (Join-Path $RepoDir 'setup-dotfiles.ps1') } 'Windows dotfiles setup failed'
Invoke-Native { pwsh.exe -NoProfile -File (Join-Path $RepoDir 'windows\org-protocol\register.ps1') } 'org-protocol registration failed'

Write-Step "Install/check WSL distribution $Distro"
$installedDistros = @(& wsl.exe --list --quiet) | ForEach-Object { ($_ -replace "`0", '').Trim() }
if ($Distro -notin $installedDistros) {
    & wsl.exe --install --distribution $Distro --no-launch
    if ($LASTEXITCODE -ne 0) { throw "WSL installation failed (exit $LASTEXITCODE)" }
    Write-Host @"

WSL was installed. Restart Windows, then run this same bootstrap command again.
The script will continue from the next step.
"@ -ForegroundColor Yellow
    exit 0
}

Write-Step "Ensure the WSL user '$WslUser' exists"
& wsl.exe -d $Distro -u $WslUser -- whoami *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Host @"
Ubuntu will open now. Create the Linux user exactly as follows:
  username: $WslUser
  password: choose a Linux password (it is not shown while typing)

When the shell appears, type 'exit'. Bootstrap will then continue.
"@ -ForegroundColor Yellow
    & wsl.exe -d $Distro
    & wsl.exe -d $Distro -u $WslUser -- whoami *> $null
    if ($LASTEXITCODE -ne 0) { throw "WSL user '$WslUser' was not created. Rerun after completing Ubuntu's first-launch prompt." }
}

Write-Step 'Configure systemd and the default WSL user (sudo may ask for the Linux password)'
$wslConf = "[boot]`nsystemd=true`n`n[user]`ndefault=$WslUser`n"
$encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($wslConf))
Invoke-Native {
    wsl.exe -d $Distro -u $WslUser -- bash -lc "echo '$encoded' | base64 -d | sudo tee /etc/wsl.conf >/dev/null"
} 'Could not write /etc/wsl.conf'
& wsl.exe --shutdown

Write-Step 'Bootstrap Ubuntu, Nix, Home Manager, and Unix dotfiles'
$windowsBootstrap = Join-Path $RepoDir 'windows\wsl\bootstrap.sh'
$wslBootstrap = (& wsl.exe -d $Distro -u $WslUser -- wslpath -u $windowsBootstrap).Trim()
if (-not $wslBootstrap) { throw 'Could not translate the WSL bootstrap path.' }
Invoke-Native { wsl.exe -d $Distro -u $WslUser -- bash $wslBootstrap } 'WSL bootstrap failed'

Write-Host @"

Bootstrap completed.

Manual steps that cannot be automated safely:
1. Open Docker Desktop and enable WSL Integration for $Distro.
2. Restore SSH/GPG private keys into WSL; do not place them in this repository.
3. In WSL run: gh auth login
4. Verify SSH, then clone the private Org repository:
   ssh -T git@github.com
   git clone git@github.com:ningen/org.git ~/org
5. Generate the Chrome bookmarklet:
   pwsh -File "$RepoDir\windows\org-protocol\get-bookmarklet.ps1"
6. Start the seven-day log in docs/windows-wsl.md.
"@ -ForegroundColor Green
