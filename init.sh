#!/bin/bash -e

function install() { 
  echo_message "install dependency packages"
  
  mkdir -p ~/.npm-global

  sudo apt-add-repository -y ppa:fish-shell/release-3
  curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
  sudo apt update
  sudo apt install -y fish make git zip unzip nodejs python3 python3-pip automake bison build-essential pkg-config libevent-dev libncurses5-dev

  # install neovim(v0.8.2)
  # apt-add-repository でrepositoryを追加する方法はバージョンが古かったため、curlで直接取ってくる
  curl -LO 'https://github.com/neovim/neovim/releases/download/v0.8.2/nvim-linux64.deb'
  sudo apt install ./nvim-linux64.deb
  rm ./nvim-linux64.deb

  # install tmux(latest)
  current_dir=$(pwd)

  sudo git clone https://github.com/tmux/tmux /usr/local/src/tmux

  cd /usr/local/src/tmux
  sudo ./autogen.sh
  sudo ./configure --prefix=/usr/local
  sudo make

  cd "$current_dir"

  # setting packer.nvim 
  packer_dir=~/.local/share/nvim/site/pack/packer/start/packer.nvim
  if [ -d $packer_dir ]; then
    echo_message "Exists neovim package manager 'packer.nvim'"
  else
    echo_message "Install neovim package manager 'packer.nvim'"
    mkdir -p $packer_dir
    git clone --depth 1 https://github.com/wbthomason/packer.nvim "$packer_dir"
  fi

  # deno: deno
  echo_message "Install deno"
  curl -fsSL https://deno.land/x/install/install.sh | sh

  source ./.profile

  # install yarn, typescript, typescript-language-server
  sudo npm install -g yarn typescript typescript-language-server 
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
    link_dotfiles
    install 
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
