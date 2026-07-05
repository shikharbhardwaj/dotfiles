#!/bin/bash

UTILITIES="curl wget htop glances jq fish neovim"

# Use apt-get on Ubuntu/Debian and brew on MacOS
if [ "$(uname)" == "Darwin" ]; then
  brew install $UTILITIES
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
  sudo apt-get update
  # build-essential is needed for nvim-treesitter to compile parsers
  sudo apt-get install -y $UTILITIES build-essential
fi
