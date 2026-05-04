export PATH=~/.ghcup/bin/:$PATH

function ghq-fzf() {
  local repo
  repo=$(ghq list -p | fzf) && cd "$repo"
  zle reset-prompt
}
zle -N ghq-fzf
bindkey '^g' ghq-fzf
