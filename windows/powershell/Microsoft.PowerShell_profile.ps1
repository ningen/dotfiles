function Enter-DotfilesWsl {
  wsl.exe -d $env:DOTFILES_WSL_DISTRO -u $env:DOTFILES_WSL_USER --cd '~'
}

function Get-DotfilesWindowsRepository {
  $repository = [Environment]::GetEnvironmentVariable('DOTFILES_WINDOWS_REPO', 'User')
  if (-not $repository -or -not (Test-Path -LiteralPath (Join-Path $repository '.git'))) {
    throw 'DOTFILES_WINDOWS_REPO is unset or invalid. Rerun setup-dotfiles.ps1 from the Windows clone.'
  }
  return $repository
}

function Update-DotfilesWindows {
  $repository = Get-DotfilesWindowsRepository
  git -C $repository pull --ff-only
  if ($LASTEXITCODE -ne 0) { throw 'Could not update the Windows dotfiles clone.' }
  & (Join-Path $repository 'setup-dotfiles.ps1')
}

function Update-DotfilesWsl {
  wsl.exe -d $env:DOTFILES_WSL_DISTRO -u $env:DOTFILES_WSL_USER -- bash -lc @'
set -euo pipefail
repo="$(ghq root)/github.com/ningen/dotfiles"
git -C "$repo" pull --ff-only
cd "$repo"
nix run .#switch-wsl
./setup-dotfiles.sh
if systemctl --user is-active --quiet emacs-default.service; then
  modified_buffers="$(emacsclient --socket-name=default --eval "(seq-some #'buffer-modified-p (buffer-list))" 2>/dev/null || true)"
  if [[ "$modified_buffers" == "nil" ]]; then
    systemctl --user restart emacs-default.service
  else
    echo 'Emacs daemon restart skipped because it has modified buffers.' >&2
    echo 'Save them, then run: systemctl --user restart emacs-default.service' >&2
  fi
else
  systemctl --user start emacs-default.service
fi
'@
  if ($LASTEXITCODE -ne 0) { throw 'Could not update the WSL dotfiles clone.' }
}
