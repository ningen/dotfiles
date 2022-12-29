#!/bin/bash -e

function install_dependencies() { 
  echo_message "install dependency packages"
  sudo apt-add-repository -y ppa:fish-shell/release-3
  sudo apt-add-repository -y ppa:neovim-ppa/stable
  sudo apt update
  sudo apt install -y fish neovim make git
  
  # setting packer.nvim 
  packer_dir=~/.local/share/nvim/site/pack/packer/start/packer.nvim
  if [ -d $packer_dir ]; then
    echo_message "Exists neovim package manager 'packer.nvim'"
  else
    echo_message "Install neovim package manager 'packer.nvim'"
    mkdir -p $packer_dir
    git clone --depth 1 https://github.com/wbthomason/packer.nvim "$packer_dir"
  fi
}

function link_dotfiles() {
  echo_message "Create synbolic link"

  IGNORE_PATTERN="^\.(git|travis)$"

  echo "Create dotfile links."
  for dotfile in .??*; do
      [[ $dotfile =~ $IGNORE_PATTERN ]] && continue
      ln -snfv "$(pwd)/$dotfile" "$HOME/$dotfile"
  done
}

function set_default_shell() {
  if [ $SHELL != "/usr/bin/fish" ]; then
    echo_message "Set default shell to 'fish'"
    chsh -s $(which fish)
    echo_message "Changed default shell to 'fish'"
  fi
}

function echo_message() {
  echo '============================================='
  echo $1 
  echo '============================================='
}


action="${1:-all}"

case "$action" in
  all ) 
    install_dependencies
    link_dotfiles
    set_default_shell ;;
  install )
    install_dependencies ;;
  link )
    link_dotfiles ;;
  sh )
    set_default_shell ;;
  * )
    echo 'invalid action' ;;
esac
