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
- [ ] Windows Developer Mode enabled

Rollback: reinstall NixOS from the verified media, check out the recorded commit,
run `sudo nixos-rebuild switch --flake .#myNixOS`, apply the `ningen@nixos` Home
Manager output, then restore Org, source repositories, and keys from the locations
above. Test this documentation before deleting any NixOS output.

## Windows bootstrap

Open **Windows PowerShell as Administrator** and run the following command. It is
safe to rerun: after a restart or Ubuntu first-launch prompt, execute the same
command again and it continues from the completed state.

This command downloads code from this repository's `main` branch and runs it as
Administrator. Before reinstalling Windows, commit and push the reviewed migration
changes; otherwise the URL will not contain the bootstrap script.

```powershell
$script = "$env:TEMP\ningen-dotfiles-bootstrap.ps1"
Invoke-WebRequest https://raw.githubusercontent.com/ningen/dotfiles/main/windows/bootstrap.ps1 -OutFile $script
powershell -ExecutionPolicy Bypass -File $script
```

The script enables Developer Mode, installs applications, clones both checkouts,
configures Windows/WSL, installs Nix and Home Manager, applies dotfiles, and
registers org-protocol. Windows restart and Ubuntu's username/password prompt
remain interactive. Use username `ningen`; the password is never stored.

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
