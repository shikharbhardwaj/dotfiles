set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim

call vundle#begin()

Plugin 'VundleVim/Vundle.vim'
Plugin 'tpope/vim-fugitive'
Plugin 'tpope/vim-sensible'
Plugin 'tpope/vim-surround'
Plugin 'jiangmiao/auto-pairs'
Plugin 'SirVer/ultisnips'
Plugin 'rhysd/vim-clang-format'
Plugin 'kien/ctrlp.vim'
Plugin 'ervandew/supertab'
Plugin 'majutsushi/tagbar'
Plugin 'scrooloose/nerdcommenter'
Plugin 'scrooloose/nerdtree'
Plugin 'Valloric/YouCompleteMe'
Plugin 'vim-scripts/indentpython.vim'
Plugin 'chriskempson/base16-vim'
Plugin 'altercation/vim-colors-solarized'
Plugin 'itchyny/lightline.vim'
Plugin 'octol/vim-cpp-enhanced-highlight'
Plugin 'LucHermitte/local_vimrc'
Plugin 'LucHermitte/lh-vim-lib'
Bundle 'christoomey/vim-tmux-navigator'

call vundle#end()            " required
filetype plugin indent on    " required
" Enable line numbering
set nu
" Remove clutter from the GUI
set guioptions=aem
" Font (required for lightline)
if has('gui_running')
    set guifont=Source\ Code\ Pro\ for\ Powerline\ Medium\ 10
endif
" Map Esc to something reachable
ino jk <esc>
cno jk <c-c>
vno v <esc>
" Use shift+arrows to copy above or below
nmap <S-Down> 0v$"+yojk"+gPddk
nmap <S-Up> 0v$"+yOjk"+gPddk
" Select the colorscheme
colorscheme solarized
" We use a 256 color terminal
let base16colorspace=256
set background=dark
set cursorline
" Global indentation settings
set expandtab
set tabstop=4
set shiftwidth=4
set softtabstop=4
" Special settings for HTML files
autocmd FileType html setlocal shiftwidth=2 tabstop=2

set autoread " File change detection
set t_Co=256
set textwidth=80
" Mark the maximum width allowed
set colorcolumn=81
highlight colorcolumn ctermbg=darkgrey
" Line padding while scrolling
set scrolloff=5
" Clipboard setting
set clipboard=unnamed
" Lightline settings(no git for a reason)
let g:lightline = {
            \ 'colorscheme': 'powerline',
            \ 'active': {
            \   'left': [ [ 'mode', 'paste' ],
            \             [ 'filename' ] ]
            \ },
            \ 'component_function': {
            \   'readonly': 'LightLineReadonly',
            \   'modified': 'LightLineModified',
            \   'filename': 'LightLineFilename'
            \ },
            \ 'separator': { 'left': '', 'right': '' },
            \ 'subseparator': { 'left': '', 'right': '' }
            \ }
function! LightLineModified()
    if &filetype == "help"
        return ""
    elseif &modified
        return "+"
    elseif &modifiable
        return ""
    else
        return ""
    endif
endfunction
function! LightLineReadonly()
    if &filetype == "help"
        return ""
    elseif &readonly
        return ""
    else
        return ""
    endif
endfunction
function! LightLineFilename()
    return ('' != LightLineReadonly() ? LightLineReadonly() . ' ' : '') .
                \ ('' != expand('%:t') ? expand('%:t') : '[No Name]') .
                \ ('' != LightLineModified() ? ' ' . LightLineModified() : '')
endfunction
" Split shortcuts
nnoremap <C-v> :vsp<CR>
nnoremap <C-a> :sp<CR>
set splitbelow
set splitright
" Split navigation with ctrl
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>
" Text movement with arrow keys
nmap <Up> [e
nmap <Down> ]e
vmap <Up> [egv
vmap <Down> ]egv
nmap <Left> <<
nmap <Right> >>
vmap <Left> <gv
vmap <Right> >gv
" tab completetion on paths
set wildmode=full
" Enable status line
set laststatus=2
" Code folding settings
set foldmethod=syntax " fold based on indent
set foldnestmax=10 " deepest fold is 10 levels
set nofoldenable " don't fold by default
set foldlevel=1
" Wrap settings
set wrap "turn on line wrapping
set wrapmargin=8 " wrap lines when coming within n characters from side
set linebreak " set soft wrapping
set showbreak=… " show ellipsis at breaking
" Map leader to ,
let mapleader=","
" Settings for NERDTree
let g:NERDTreeWinPos = "left"
nnoremap <F9> :NERDTreeToggle<CR>
"
" YouCompleteMe options
"
" Check if the configuration file exists in the project
" for custom configs for each project
if filereadable("../cfg/ycm_extra_conf.py")
    let g:ycm_global_ycm_extra_conf = '../cfg/ycm_extra_conf.py'
else
    let g:ycm_global_ycm_extra_conf = '~/.vim/ycm_extra_conf.py'
endif
" Window title
let &titlestring = "Vim"
if &term == "screen"
    set t_ts=^[k
    set t_fs=^[\
endif
if &term == "screen"
    set title
endif
" Ctags
set tags=tags;
" CtrlP
set runtimepath^=~/.vim/bundle/ctrlp.vim
let g:ctrlp_map = '<c-p>'
let g:ctrlp_cmd = 'CtrlP'
nnoremap <leader>. :CtrlPTag<cr>
" Tagbar
set runtimepath^=~/.vim/bundle/tagbar
nnoremap <silent> <Leader>b :TagbarToggle<CR>
let g:tagbar_width = 30
let s:width = 80
" Escape/unescape & < > HTML entities in range (default current line).
function! HtmlEntities(line1, line2, action)
    let search = @/
    let range = 'silent ' . a:line1 . ',' . a:line2
    if a:action == 0  " must convert &amp; last
        execute range . 'sno/&lt;/</eg'
        execute range . 'sno/&gt;/>/eg'
        execute range . 'sno/&amp;/&/eg'
    else              " must convert & first
        execute range . 'sno/&/&amp;/eg'
        execute range . 'sno/</&lt;/eg'
        execute range . 'sno/>/&gt;/eg'
    endif
    nohl
    let @/ = search
endfunction
command! -range -nargs=1 Entities call HtmlEntities(<line1>, <line2>, <args>)
noremap <silent> \h :Entities 0<CR>
noremap <silent> \H :Entities 1<CR>
" Make shift+arrow work on tmux
if &term =~ '^screen'
    " tmux will send xterm-style keys when its xterm-keys option is on
    execute "set <xUp>=\e[1;*A"
    execute "set <xDown>=\e[1;*B"
    execute "set <xRight>=\e[1;*C"
    execute "set <xLeft>=\e[1;*D"
endif

" Enable editing encrypted files
" Transparent editing of gpg encrypted files.
augroup encrypted
au!
" First make sure nothing is written to ~/.viminfo while editing
" an encrypted file.
autocmd BufReadPre,FileReadPre      *.gpg set viminfo=
" We don't want a swap file, as it writes unencrypted data to disk
autocmd BufReadPre,FileReadPre      *.gpg set noswapfile
" Switch to binary mode to read the encrypted file
autocmd BufReadPre,FileReadPre      *.gpg set bin
autocmd BufReadPre,FileReadPre      *.gpg let ch_save = &ch|set ch=2
autocmd BufReadPre,FileReadPre      *.gpg let shsave=&sh
autocmd BufReadPre,FileReadPre      *.gpg let &sh='sh'
autocmd BufReadPre,FileReadPre      *.gpg let ch_save = &ch|set ch=2
autocmd BufReadPost,FileReadPost    *.gpg '[,']!gpg --decrypt --default-recipient-self 2> /dev/null
autocmd BufReadPost,FileReadPost    *.gpg let &sh=shsave
" Switch to normal mode for editing
autocmd BufReadPost,FileReadPost    *.gpg set nobin
autocmd BufReadPost,FileReadPost    *.gpg let &ch = ch_save|unlet ch_save
autocmd BufReadPost,FileReadPost    *.gpg execute ":doautocmd BufReadPost " . expand("%:r")
" Convert all text to encrypted text before writing
autocmd BufWritePre,FileWritePre    *.gpg set bin
autocmd BufWritePre,FileWritePre    *.gpg let shsave=&sh
autocmd BufWritePre,FileWritePre    *.gpg let &sh='sh'
autocmd BufWritePre,FileWritePre    *.gpg '[,']!gpg --encrypt --default-recipient-self 2>/dev/null
autocmd BufWritePre,FileWritePre    *.gpg let &sh=shsave
" Undo the encryption so we are back in the normal text, directly
" after the file has been written.
autocmd BufWritePost,FileWritePost  *.gpg silent u
autocmd BufWritePost,FileWritePost  *.gpg set nobin
augroup END
" Show invisibles
" Shortcut to rapidly toggle `set list`
nmap <leader>l :set list!<CR>
" Use the same symbols as TextMate for tabstops and EOLs
set listchars=tab:▸\ ,eol:¬
" Tag navigation
function TagJumpForward()
    execute "tag " . expand("<cword>")
    try | foldopen! | catch | | endtry
endfunction

function TagJumpBack()
    try | foldclose! | catch | | endtry
    pop
endfunction

nnoremap <silent> <C-i> :call TagJumpForward()<CR>
nnoremap <silent> <C-t> :call TagJumpBack()<CR>
" Tag support in CtrlP
let g:ctrlp_extensions = ['tag']
" Settings for clang-format
let g:clang_format#style_options = {
    \"BasedOnStyle" : "llvm",
    \"IndentWidth" : 4}
let g:clang_format#auto_format = 1
let g:clang_format#command = "clang-format-3.8"
" Change to current file directory 
autocmd BufEnter * silent! :lcd%:p:h
" Make with F4
autocmd filetype cpp nnoremap <F4> :!make % && './%:r'<CR>
autocmd filetype c nnoremap <F4> :!make % && './%:r'<CR>
