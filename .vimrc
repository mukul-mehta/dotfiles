set number
set relativenumber
syntax on
set expandtab ts=4 sw=4 ai
set nocompatible
filetype off
set termguicolors

set rtp+=~/.vim/bundle/Vundle.vim

call vundle#begin()

Plugin 'VundleVim/Vundle.vim'
Plugin 'jiangmiao/auto-pairs'
Plugin 'alvan/vim-closetag'
Plugin 'mattn/emmet-vim'
Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'
Plugin 'chrisbra/csv.vim'
Plugin 'xypnox/vim-material'
Plugin 'scrooloose/nerdTree' "Documents tree
Plugin 'davidhalter/jedi-vim' "python autocompletion
Plugin 'tpope/vim-fugitive' "git integration
"Plugin 'scrooloose/syntastic' "code syntaxis
Plugin 'Raimondi/delimitMate' "automatic closing of quotes, parenthesis...
Plugin 'yggdroot/indentline' "Show indent lines (useful for loops)
Plugin 'tmhedberg/SimpylFold' "Python folding
Plugin 'vim-scripts/indentpython.vim'
Plugin 'nvie/vim-flake8'
Plugin 'kien/ctrlp.vim'
Plugin 'ervandew/supertab'
call vundle#end()

filetype plugin indent on
let g:user_emmet_leader_key='<C-Z>'
let g:material_style='oceanic'
let g:deoplete#enable_at_startup = 1
let g:SimpylFold_docstring_preview=1
let python_highlight_all=1

set background=dark
colorscheme vim-material
set t_Co=256

set foldmethod=indent
set foldlevel=99
nnoremap <space> za
au BufRead, BufNewFile *.py,*.pyw,*.c,*.h match BadWhitespace /\s\+$/

