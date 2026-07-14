function Enter-DotfilesWsl { wsl.exe -d $env:DOTFILES_WSL_DISTRO -u $env:DOTFILES_WSL_USER --cd '~' }
function Update-DotfilesWindows {
  git -C "$env:USERPROFILE\ghq\github.com\ningen\dotfiles" pull --ff-only
  & "$env:USERPROFILE\ghq\github.com\ningen\dotfiles\setup-dotfiles.ps1"
}
function Update-DotfilesWsl {
  wsl.exe -d $env:DOTFILES_WSL_DISTRO -u $env:DOTFILES_WSL_USER -- bash -lc 'cd ~/ghq/github.com/ningen/dotfiles && git pull --ff-only && nix run .#switch-wsl && ./setup-dotfiles.sh'
}
