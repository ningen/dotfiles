if status is-interactive
    # Commands to run in interactive sessions can go here
end

# aliases
alias g='git'


# setting environment
set -gx XDG_CONFIG_HOME $HOME/.config

## volta
set -gx VOLTA_HOME $HOME/.volta
fish_add_path $VOLTA_HOME/bin

## Deno
set -gx DENO_INSTALL $HOME/.deno
fish_add_path $DENO_INSTALL/bin
