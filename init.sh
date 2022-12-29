#!/bin/bash -e

function install_dependencies() { 
  echo_message "install dependency packages"
  sudo apt-add-repository -y ppa:fish-shell/release-3
  sudo apt-add-repository -y ppa:neovim-ppa/stable
  sudo apt update
  sudo apt install -y fish neovim make git
}

function link_dotfiles() {
  echo_message "Create synbolic link"

  IGNORE_PATTERN="^\.(git|travis)"

  echo "Create dotfile links."
  for dotfile in .??*; do
      [[ $dotfile =~ $IGNORE_PATTERN ]] && continue
      ln -snfv "$(pwd)/$dotfile" "$HOME/$dotfile"
  done
}

function set_default_shell() {
  echo_message "Set default shell to 'fish'"
  chsh -s $(which fish)
  echo_message "Changed default shell to 'fish'"
}


function install_neovim_package_manager() {
  packer_dir=~/.local/share/nvim/site/pack/packer/start/packer.nvim
  if [ -d $packer_dir ]; then
    echo_message "Exists neovim package manager 'packer.nvim'"
  else
    echo_message "Install neovim package manager 'packer.nvim'"
    mkdir -p $packer_dir
    git clone --depth 1 https://github.com/wbthomason/packer.nvim "$packer_dir"
  fi
}

function echo_message() {
  echo '============================================='
  echo $1 
  echo '============================================='
}


function main() {
  install_dependencies
  link_dotfiles
  install_neovim_package_manager
  set_default_shell
}

main
