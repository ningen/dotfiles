# Windows 11 + Ubuntu WSL 2 migration runbook

This runbook intentionally keeps the NixOS configuration until seven consecutive
acceptance days have passed. Never store recovery keys, private keys, tokens, Org
content, browser profiles, or Docker credentials in this repository.

## Recovery gate (Phase 0)

Record locations without recording secrets:

- [ ] Pushed NixOS rollback commit: `________________`
- [ ] `~/org` backup verified at: `________________`
- [ ] `~/ghq` backup verified at: `________________`
- [ ] SSH/GPG backup verified at: `________________`
- [ ] Browser/Bitwarden export or sync verified at: `________________`
- [ ] `git@github.com:ningen/org.git` restored in a second clone
- [ ] BitLocker recovery key location verified: `________________`
- [ ] Windows 11 installation media verified
- [ ] Target CPU reports x86_64
- [ ] Windows Developer Mode enabled, or an elevated PowerShell is available for link creation

Rollback: reinstall NixOS from the verified media, check out the recorded commit,
run `sudo nixos-rebuild switch --flake .#myNixOS`, apply the `ningen@nixos` Home
Manager output, then restore Org, source repositories, and keys from the locations
above. Test this documentation before deleting any NixOS output.

## Windows bootstrap

Clone the repository anywhere on Windows, open PowerShell 7 in that clone, and run
the bootstrap below. The script resolves the repository from its own location;
neither the drive nor clone directory is fixed. Inspect the dry-run before applying.

```powershell
pwsh -NoProfile -File .\windows\bootstrap.ps1 -DryRun
pwsh -NoProfile -File .\windows\bootstrap.ps1
```

Normal runs install missing winget packages and preserve installed versions. To
ask winget and VS Code to update managed packages/extensions, run:

```powershell
pwsh -NoProfile -File .\windows\bootstrap.ps1 -Upgrade
```

The bootstrap does not clone, pull, change Developer Mode, restart Windows, shut
down WSL, or create Linux users. Developer Mode allows current-user symlinks; when
it is disabled, only link creation needs an elevated PowerShell. The package
installer and current-user registry integration do not require elevation.

The Windows layer manages GUI applications and integrations. WSL's Nix/Home
Manager output remains responsible for shells, editors, language runtimes, and
CLI tools. Oh My Posh is intentionally omitted because Starship already provides
the prompt in WSL. GlazeWM and YASB provide the Windows-native equivalents of the
NixOS tiling-window/status-bar layer. YASB v2 generates its initial configuration
with its first-run wizard; do not commit API keys or machine-specific values from
that generated file.

`setup-dotfiles.ps1` links these repository files:

| Source | Windows target |
| --- | --- |
| `.config/wezterm` | `%APPDATA%\wezterm` |
| `windows/glazewm/config.yaml` | `%USERPROFILE%\.glzr\glazewm\config.yaml` |
| `windows/powershell/Microsoft.PowerShell_profile.ps1` | `%USERPROFILE%\Documents\PowerShell\Microsoft.PowerShell_profile.ps1` |
| `.config/vscode/settings.json` | `%APPDATA%\Code\User\settings.json` |
| `.config/vscode/keybindings.json` | `%APPDATA%\Code\User\keybindings.json` |

Correct links are logged as `NOOP`. Any regular file, directory, or different
link is moved intact to
`%LOCALAPPDATA%\ningen-dotfiles\backups\<UTC timestamp>` before replacement.
Rerun the same dry-run and apply commands after updates; a second apply should
show only `NOOP` for links and installed/current packages.

## Manual WSL bootstrap (fallback)

```powershell
wsl --install -d Ubuntu-24.04
wsl -l -v
wsl -d Ubuntu-24.04 -u ningen -- whoami
```

Create `/etc/wsl.conf` inside Ubuntu, then shut WSL down from Windows:

```ini
[boot]
systemd=true

[user]
default=ningen
```

```bash
sudo apt update && sudo apt upgrade
sudo apt install -y curl git
sh <(curl -L https://nixos.org/nix/install) --daemon
git clone https://github.com/ningen/dotfiles.git ~/ghq/github.com/ningen/dotfiles
cd ~/ghq/github.com/ningen/dotfiles
nix --extra-experimental-features 'nix-command flakes' run .#switch-wsl
./setup-dotfiles.sh --dry-run
./setup-dotfiles.sh
```

Restore SSH/GPG keys into WSL with strict permissions, authenticate `gh`, verify
`ssh -T git@github.com`, and only then clone `git@github.com:ningen/org.git` to
`~/org`. Keep source and Org data in the WSL filesystem, not `/mnt/c`.

## Integration checks

Enable Docker Desktop's WSL 2 backend and integration for `Ubuntu-24.04`, then run:

```bash
docker version
docker context ls
docker run --rm hello-world
docker compose version
printf '日本語\nmultiple lines\n' | win-copy
win-paste
nvim '+checkhealth clipboard'
DOOMPROFILE=default emacsclient --socket-name=default --create-frame
```

Generate the Chrome bookmarklet with
`pwsh -File windows/org-protocol/get-bookmarklet.ps1`. Test capture with WSL and
Emacs both stopped, WSL only running, and the `default` daemon running. Include
`&`, `%`, quotes, spaces, Japanese, and selection text. Confirm exactly one entry
in `~/org/links.org`. The diagnostic log contains only timestamp, stage, and exit
code at `%LOCALAPPDATA%\ningen-dotfiles\org-protocol.log`.

## macOS regression

```bash
nix build '.#homeConfigurations."ningen@ningen-mba.local".activationPackage'
nix build .#darwinConfigurations.ningen.system
bash -n setup-dotfiles.sh
./setup-dotfiles.sh --dry-run
```

Verify zsh, Doom Emacs, Neovim, tmux, WezTerm, VS Code links, and the existing
macOS org-protocol handler.

## Seven-day acceptance log

Start date: `____________`  Earliest completion date: `____________`

| Day | Date | Windows/WSL daily work | Git cross-machine | Docker/network/VPN | org capture | Sleep/restart/update | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | | [ ] | [ ] | [ ] | [ ] | [ ] | |
| 2 | | [ ] | [ ] | [ ] | [ ] | [ ] | |
| 3 | | [ ] | [ ] | [ ] | [ ] | [ ] | |
| 4 | | [ ] | [ ] | [ ] | [ ] | [ ] | |
| 5 | | [ ] | [ ] | [ ] | [ ] | [ ] | |
| 6 | | [ ] | [ ] | [ ] | [ ] | [ ] | |
| 7 | | [ ] | [ ] | [ ] | [ ] | [ ] | |

Final gate:

- [ ] Home Manager reapplies successfully in WSL
- [ ] Shell/editor/language tools work from the WSL filesystem
- [ ] Docker has exactly one daemon/socket/context path
- [ ] Clipboard and opener preserve Japanese, multiline content, trailing newline, and spaced paths
- [ ] All three org-protocol startup states work without duplicate captures
- [ ] macOS regression checks pass
- [ ] No secrets or Org content appear in `git status` or repository history
- [ ] Seven consecutive dated rows above are complete

Only after every item is checked should Phase 7 begin. Windows rollback is
`pwsh -File .\windows\rollback.ps1`; it restores captured environment/Git/Terminal
baselines and removes `.wslconfig` only when setup created it.
