#!/bin/bash

DEST_PATH="$HOME/custom/bin"
cd $DEST_PATH

# Download kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl

# Download k9s
wget https://github.com/derailed/k9s/releases/download/v0.32.5/k9s_Linux_amd64.tar.gz -O "$HOME/downloads/k9s.tar.gz"
tar -zxvf "$HOME/downloads/k9s.tar.gz" k9s
