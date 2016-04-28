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
echo "Installing vim plugins"
# Wait for user to see this message
sleep 3
tmux new "vim -c PluginInstall -c quitall"
echo "Installing YCM with C++ support, may take some time"
echo "Press ctrl + c to abort"
# Wait for user to see this message
sleep 3
tmux new "~/.vim/bundle/YouCompleteMe/install.py --clang-completer"
if [ -d "~/custom/scripts" ]; then
    cp ./scripts/* ~/custom/scripts
fi
echo "Done"

