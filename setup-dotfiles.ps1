# PowerShell script for Windows dotfiles setup
# Requires Administrator privileges for creating symlinks

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "=================================================" -ForegroundColor Yellow
    Write-Host "WARNING: Not running as Administrator" -ForegroundColor Yellow
    Write-Host "Symlink creation may fail without admin privileges" -ForegroundColor Yellow
    Write-Host "=================================================" -ForegroundColor Yellow
    Write-Host ""
}

# Get script directory
$DotfilesDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigFile = Join-Path $DotfilesDir "dotfiles-links.yaml"

# Set CONFIG_DIR based on XDG_CONFIG_HOME or default
if ($env:XDG_CONFIG_HOME) {
    $ConfigDir = $env:XDG_CONFIG_HOME
} elseif ($env:APPDATA) {
    $ConfigDir = $env:APPDATA
} else {
    $ConfigDir = Join-Path $env:USERPROFILE "AppData\Roaming"
}

# Set VSCode config directory
if ($env:APPDATA) {
    $VSCodeConfigDir = Join-Path $env:APPDATA "Code\User"
} else {
    $VSCodeConfigDir = Join-Path $env:USERPROFILE "AppData\Roaming\Code\User"
}

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Dotfiles Setup (Windows)" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Config directory: $ConfigDir"
Write-Host "VSCode directory: $VSCodeConfigDir"
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Create config directories
New-Item -ItemType Directory -Force -Path $ConfigDir | Out-Null
New-Item -ItemType Directory -Force -Path $VSCodeConfigDir | Out-Null

# Function to expand variables in string
function Expand-Variables {
    param([string]$String)

    $result = $String -replace '\$CONFIG_DIR', $ConfigDir
    $result = $result -replace '\$VSCODE_CONFIG_DIR', $VSCodeConfigDir

    return $result
}

# Function to create symlink
function New-DotfileLink {
    param(
        [string]$Source,
        [string]$Target,
        [string]$Type
    )

    # Expand source path (relative to dotfiles directory)
    $sourcePath = Join-Path $DotfilesDir $Source

    # Expand variables in target path
    $targetPath = Expand-Variables $Target

    # Create parent directory if it doesn't exist
    $parentDir = Split-Path -Parent $targetPath
    if (-not (Test-Path $parentDir)) {
        New-Item -ItemType Directory -Force -Path $parentDir | Out-Null
    }

    # Check if target already exists
    if (Test-Path $targetPath) {
        $item = Get-Item $targetPath -Force
        if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
            # It's a symlink, remove it
            Remove-Item $targetPath -Force
        } else {
            # It's a real file/directory
            Write-Host "⚠ Warning: $targetPath already exists and is not a symlink. Skipping." -ForegroundColor Yellow
            return $false
        }
    }

    # Create symlink
    try {
        if ($Type -eq "directory") {
            New-Item -ItemType SymbolicLink -Path $targetPath -Target $sourcePath -Force | Out-Null
        } else {
            New-Item -ItemType SymbolicLink -Path $targetPath -Target $sourcePath -Force | Out-Null
        }
        Write-Host "✓ Linked: $targetPath -> $sourcePath" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "✗ Failed to link: $targetPath" -ForegroundColor Red
        Write-Host "  Error: $_" -ForegroundColor Red
        return $false
    }
}

# Simple YAML parser
function Parse-YamlSection {
    param(
        [string]$Section
    )

    $content = Get-Content $ConfigFile -Raw
    # Handle both Unix (LF) and Windows (CRLF) line endings
    $lines = $content -split "\r?\n"

    $currentSection = ""
    $inTargetSection = $false
    $items = @()
    $currentItem = @{}

    foreach ($line in $lines) {
        # Trim the line to handle whitespace
        $trimmedLine = $line.Trim()

        # Skip comments and empty lines
        if ($trimmedLine -match '^#' -or $trimmedLine -eq '') {
            continue
        }

        # Check for section header (no leading spaces in original line)
        if ($line -match '^([a-z_]+):\s*$') {
            # Save current item from previous section if exists
            if ($inTargetSection -and $currentItem.Count -gt 0 -and $currentItem.source -and $currentItem.target -and $currentItem.type) {
                $items += $currentItem
            }

            $currentSection = $matches[1]
            $currentItem = @{}

            if ($currentSection -eq $Section) {
                $inTargetSection = $true
            } else {
                $inTargetSection = $false
            }
            continue
        }

        if (-not $inTargetSection) {
            continue
        }

        # Parse list items
        if ($line -match '^\s+-\s+source:\s*(.+?)\s*$') {
            # New item, save previous if exists
            if ($currentItem.Count -gt 0 -and $currentItem.source -and $currentItem.target -and $currentItem.type) {
                $items += $currentItem
            }
            $currentItem = @{
                source = $matches[1].Trim()
            }
        }
        elseif ($line -match '^\s+target:\s*(.+?)\s*$') {
            $currentItem.target = $matches[1].Trim()
        }
        elseif ($line -match '^\s+type:\s*(.+?)\s*$') {
            $currentItem.type = $matches[1].Trim()
        }
    }

    # Add last item if exists
    if ($inTargetSection -and $currentItem.Count -gt 0 -and $currentItem.source -and $currentItem.target -and $currentItem.type) {
        $items += $currentItem
    }

    return $items
}

# Process common links
Write-Host "Creating common links..." -ForegroundColor Cyan
$commonLinks = Parse-YamlSection "common"
Write-Host "Found $($commonLinks.Count) common links" -ForegroundColor Gray

if ($commonLinks.Count -eq 0) {
    Write-Host "⚠ No common links found. Check YAML file format." -ForegroundColor Yellow
} else {
    foreach ($link in $commonLinks) {
        New-DotfileLink -Source $link.source -Target $link.target -Type $link.type
    }
}
Write-Host ""

# Skip unix_only links on Windows

# Process VSCode links
Write-Host "Creating VSCode links..." -ForegroundColor Cyan
$vscodeLinks = Parse-YamlSection "vscode"
Write-Host "Found $($vscodeLinks.Count) VSCode links" -ForegroundColor Gray

if ($vscodeLinks.Count -eq 0) {
    Write-Host "⚠ No VSCode links found. Check YAML file format." -ForegroundColor Yellow
} else {
    foreach ($link in $vscodeLinks) {
        New-DotfileLink -Source $link.source -Target $link.target -Type $link.type
    }
}

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "✓ Dotfiles setup completed!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
