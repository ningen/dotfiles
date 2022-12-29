#!/bin/bash -e

function install() { 
  echo_message "install dependency packages"
  sudo apt-add-repository -y ppa:fish-shell/release-3
  sudo apt-add-repository -y ppa:neovim-ppa/stable
  sudo apt update
  sudo apt install -y fish neovim make git zip unzip
  
  # setting packer.nvim 
  packer_dir=~/.local/share/nvim/site/pack/packer/start/packer.nvim
  if [ -d $packer_dir ]; then
    echo_message "Exists neovim package manager 'packer.nvim'"
  else
    echo_message "Install neovim package manager 'packer.nvim'"
    mkdir -p $packer_dir
    git clone --depth 1 https://github.com/wbthomason/packer.nvim "$packer_dir"
  fi

  # install languages 
  # nodejs: volta
  echo_message "Install node version manager 'volta'"
  curl https://get.volta.sh | bash -s -- --skip-setup 
  # deno: deno
  echo_message "Install deno"
  curl -fsSL https://deno.land/x/install/install.sh | sh
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
    install 
    link_dotfiles
    set_default_shell ;;
  install )
    install ;;
  link )
    link_dotfiles ;;
  sh )
    set_default_shell ;;
  * )
    echo 'invalid action' ;;
esac
