export PATH=~/.ghcup/bin/:$PATH

function ghq-fzf() {
  local repo
  repo=$(ghq list -p | fzf) && z "$repo"
  zle clear-screen
}
zle -N ghq-fzf
bindkey '^g' ghq-fzf
