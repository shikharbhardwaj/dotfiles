#!/bin/bash
echo "Installing setup..."
echo "Bash"
cp ./bash/bashrc ~/.bashrc
echo "Zsh"
cp ./zsh/zshrc ~/.zshrc
cp ./zsh/agnoster_mod.zsh-theme ~/.oh-my-zsh/themes
echo "tmux"
cp ./tmux/tmux.conf ~/.tmux.conf
echo "Vim"
cp -ar ./fonts ~/.fonts
cp -ar ./vim ~/.vim
cp -ar ./scripts/ ~/custom/scripts
echo "Done"

