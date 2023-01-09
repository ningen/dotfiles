if status is-interactive
    # Commands to run in interactive sessions can go here
end

# aliases
alias g='git'
alias python='python3'

# setting environment
set -gx XDG_CONFIG_HOME $HOME/.config

## Deno
set -gx DENO_INSTALL $HOME/.deno
fish_add_path $DENO_INSTALL/bin

## tmux
set -gx TMUX_SOURCE_DIR /usr/local/src/tmux
fish_add_path $TMUX_SOURCE_DIR
