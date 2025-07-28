" -------------------------
" パス設定
" -------------------------
let $PATH = '/opt/homebrew/bin:' . $PATH


" -------------------------
" 基本設定
" -------------------------
let mapleader = "\<space>"
set encoding=UTF-8
set belloff=all
set nocompatible              " 古いVi互換をオフ
syntax on                     " 構文ハイライト
filetype plugin indent on     " ファイルタイプ別プラグインとインデント


" -------------------------
" UI設定
" -------------------------
set number                    " 行番号
set cursorline                " カーソル行をハイライト
set showmatch                 " 括弧の対応表示
set signcolumn=yes            " Git等の表示がズレないように
set laststatus=2              " ステータスライン常時表示
set background=dark           " グルーボックス向け背景設定
set termguicolors             " True Color（24bit）有効化


" -------------------------
" 編集設定
" -------------------------
set tabstop=2                 " タブ幅
set shiftwidth=2              " 自動インデント幅
set expandtab                 " タブをスペースに変換
set autoindent                " 自動インデント
set smartindent               " スマートインデント
set backspace=indent,eol,start " バックスペース拡張


" -------------------------
" 検索設定
" -------------------------
set ignorecase                " 小文字で検索すると大文字もヒット
set smartcase                 " 大文字混在時は区別
set incsearch                 " インクリメンタルサーチ
set hlsearch                  " 検索結果をハイライト


" -------------------------
" クリップボード（MacVim）
" -------------------------
set clipboard=unnamed         " Macのクリップボードと共有


" -------------------------
" キーコンフィグ
" -------------------------
" ハイライトオフ 
nnoremap <ESC><ESC> :nohlsearch<CR>

" ウィンドウ間移動を Ctrl + hjkl に
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" タブ操作
nnoremap <Leader>tn :tabnew<CR>
nnoremap <Leader>th :tabprev<CR>
nnoremap <Leader>tl :tabnext<CR>
nnoremap <Leader>tc :tabclose<CR>

" fzf関連
nnoremap <Leader>s :Files<CR>
nnoremap <Leader>g :GFiles<CR>
nnoremap <Leader>b :Buffers<CR>
nnoremap <Leader>r :Rg<Space>


" ターミナル
nnoremap <Leader>t :terminal<CR>

" 再読み込みコマンド
command! Reload execute 'source %' | echo 'Reloaded ' . expand('%')


" -------------------------
" プラグイン管理（vim-plug）
" -------------------------
call plug#begin('~/.vim/plugged')

Plug 'rose-pine/vim'
Plug 'itchyny/lightline.vim'

Plug 'brglng/vim-im-select'

Plug 'lambdalisue/nerdfont.vim'
Plug 'lambdalisue/fern.vim'
Plug 'lambdalisue/vim-fern-renderer-nerdfont'
Plug 'lambdalisue/fern-hijack.vim'
Plug 'lambdalisue/fern-git-status.vim'

Plug 'SidOfc/mkdx'

Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

Plug 'tpope/vim-commentary'

Plug 'airblade/vim-gitgutter'

call plug#end()


" -------------------------
" カラー設定
" -------------------------
set background=dark
colorscheme rosepine
let g:lightline = { 'colorscheme': 'rosepine' }


" -------------------------
" GUIフォント（MacVim専用）
" -------------------------
if has('gui_running')
  set guifont=UDEV\ Gothic\ 35NF:h12
  set guifontwide=UDEV\ Gothic\ 35NF:h12
endif


" -------------------------
" Fernの設定
" -------------------------
nnoremap <Leader>e :Fern . -drawer -toggle -reveal=%<CR>
nnoremap <Leader>f :Fern %:h -reveal=% -drawer -toggle<CR>
let g:fern#renderer = "nerdfont"


" -------------------------
" Markdownの設定
" -------------------------
let g:mkdx#settings = { 'map': { 'enabel': 1, 'prefix': ',' }, 'checkbox': { 'toggles': [' ', 'x'] } }


" -------------------------
" IME自動切り替え制御
" -------------------------
let g:im_select_command = 'im-select'
let g:im_select_default = 'com.apple.inputmethod.Kotoeri.RomajiTyping.Roman'
let g:im_select_enable = 1
let g:im_select_enable_for_gvim = 1

