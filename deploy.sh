#!/bin/sh

function create_symbolic_link() {
  ln -snfv "$(pwd)/config" "$HOME/.config"
}

create_symbolic_link

