#!/bin/bash

DEST_PATH="$HOME/.local/share/nvim/site/pack/packer/start/packer.nvim"

[ ! -d "$DEST_PATH" ] && git clone --depth 1 https://github.com/wbthomason/packer.nvim "$DEST_PATH" || echo "Packer dir exists, skipping install..."
