export PATH=~/.ghcup/bin/:$PATH

e() { emacsclient -c -a "" "$@"; }
et() { emacsclient -t -a "" "$@"; }

function ghq-fzf() {
  local repo
  repo=$(ghq list -p | fzf) && z "$repo"
  zle clear-screen
}
zle -N ghq-fzf
bindkey '^g' ghq-fzf
bindkey -M viins '^R' history-incremental-search-backward
