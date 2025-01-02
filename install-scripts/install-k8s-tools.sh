#!/bin/bash

DEST_PATH="$HOME/custom/bin"
cd $DEST_PATH

OS=$(uname -s)
ARCH=$(uname -m)

# Download kubectl, based on current architecture
if [ "$ARCH" == "x86_64" ]; then
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
elif [ "$ARCH" == "arm64" ] && [ "$OS" == "Darwin" ]; then
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/arm64/kubectl"
fi
chmod +x kubectl

# Download k9s, based on current architecture
if [ "$ARCH" == "x86_64" ]; then
    wget https://github.com/derailed/k9s/releases/download/v0.32.5/k9s_Linux_amd64.tar.gz -O "$HOME/downloads/k9s.tar.gz"
elif [ "$ARCH" == "arm64" ] && [ "$OS" == "Darwin" ]; then
    wget https://github.com/derailed/k9s/releases/download/v0.32.5/k9s_Darwin_arm64.tar.gz -O "$HOME/downloads/k9s.tar.gz"
fi

tar -zxvf "$HOME/downloads/k9s.tar.gz" k9s
