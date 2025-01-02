#!/bin/bash

UTILITIES="curl wget htop glances jq"

# Use apt-get on Ubuntu/Debian and brew on MacOS
if [ "$(uname)" == "Darwin" ]; then
  brew install $UTILITIES
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
  sudo apt-get update
  sudo apt-get install -y $UTILITIES
fi
