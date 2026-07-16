@{
    Packages = @(
        @{ Id = 'wez.wezterm'; Name = 'WezTerm' }
        @{ Id = 'Microsoft.VisualStudioCode'; Name = 'Visual Studio Code' }
        @{ Id = 'Docker.DockerDesktop'; Name = 'Docker Desktop' }
        @{ Id = 'Google.Chrome'; Name = 'Google Chrome'; InstalledIds = @('Google.Chrome', 'Google.Chrome.EXE') }
        @{ Id = 'Microsoft.PowerShell'; Name = 'PowerShell 7' }
        @{ Id = 'Git.Git'; Name = 'Git' }
        @{ Id = 'Microsoft.WindowsTerminal'; Name = 'Windows Terminal' }
        @{ Id = 'Obsidian.Obsidian'; Name = 'Obsidian' }
        @{ Id = 'Discord.Discord'; Name = 'Discord' }
        @{ Id = 'Microsoft.PowerToys'; Name = 'PowerToys' }
        @{ Id = 'DEVCOM.JetBrainsMonoNerdFont'; Name = 'JetBrains Mono Nerd Font' }
        @{ Id = 'glzr-io.glazewm'; Name = 'GlazeWM' }
        @{ Id = 'AmN.yasb'; Name = 'YASB Reborn' }
    )
    VSCodeExtensions = @(
        'ms-vscode-remote.remote-wsl'
    )
}
