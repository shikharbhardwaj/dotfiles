set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath
source ~/.vim/vimrc

call plug#begin('~/.vim/plugged')

" Use release branch (Recommend)
Plug 'neoclide/coc.nvim', {'branch': 'release'}

call plug#end()

