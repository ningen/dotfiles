#!/bin/bash -e

function install_dependencies() { 
  apt-add-repository ppa:fish-shell/release-3
  apt update
  apt install -y fish
}

function link_dotfiles() {
  IGNORE_PATTERN="^\.(git|travis)"

  echo "Create dotfile links."
  for dotfile in .??*; do
      [[ $dotfile =~ $IGNORE_PATTERN ]] && continue
      ln -snfv "$(pwd)/$dotfile" "$HOME/$dotfile"
  done
  echo "Success"
}


function main() {
  install_dependencies
  link_dotfiles
}

main
