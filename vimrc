autocmd vimenter * ++nested colorscheme gruvbox
set et ts=4 sts=4 sw=4
set fdm=syntax fdl=100
set nu ru ls=2
set hls is si
set ci cino=j1,(0,ws,Ws
set tm=360 ttm=10
set mouse=a
set bg=dark
set nocompatible
set backspace=indent,eol,start

syntax on
filetype on
filetype plugin on
filetype indent on

nnoremap <silent> <F1> :wa<CR>:A<CR>
nnoremap <silent> <F2> :wa<CR>:bp<CR>
nnoremap <silent> <F3> :wa<CR>:bn<CR>
nnoremap <silent> <F4> :wa<CR>
inoremap <silent> <F1> <ESC>
inoremap <silent> <F2> <ESC>:wa<CR>:bp<CR>
inoremap <silent> <F3> <ESC>:wa<CR>:bn<CR>
inoremap <silent> <F4> <ESC>:wa<CR>
nnoremap <silent> <F5> :wa<CR>:CMake<CR>
nnoremap <silent> <F6> :wa<CR>:CMakeBuild<CR>
nnoremap <silent> <C-F7> :wa<CR>:CMakeRun<CR>
nnoremap <silent> <S-F7> :wa<CR>:!make\|\|(echo -n .;read -n1)<CR><CR>
nnoremap <silent> <F7> :wa<CR>:!make<CR>
nnoremap <silent> <F8> :wa<CR>:sh<CR><CR>
nnoremap <silent> <F9> :wa<CR>:TagbarToggle<CR>:NERDTreeToggle<CR><C-w>l
nnoremap <silent> <F10> :wa<CR>:QFix<CR>
inoremap <silent> <F10> <ESC>:wa<CR>:QFix<CR>
nnoremap <silent> <S-F11> :wa<CR>:botright terminal<CR>
nnoremap <silent> <F12> /required from here<CR>
nnoremap <silent> <C-k> <C-w>k:q<CR>
nnoremap <silent> <C-j> <C-w>j
nnoremap Z ZZ
nnoremap Q @@

let mapleader = "/"
nnoremap <Leader>q :q<CR>
nnoremap <Leader>w :w<CR>
nnoremap <Leader>qq :q!<CR>
nnoremap <Leader>g :NERDTreeToggle<CR>
nnoremap <Leader>f :NERDTreeToggle<CR>

" rid annoying swap prompts:
autocmd SwapExists * let v:swapchoice = "e"

let g:cmake_build_target = 'main'
let g:cmake_build_type = 'Debug'
let g:cmake_compile_commands = 1
let g:cmake_build_path_pattern = ["/tmp/build/%s", "getcwd()"]

" for YouCompleteMe:
let g:ycm_confirm_extra_conf = 0
let g:ycm_error_symbol = '✗'
let g:ycm_warning_symbol = '⚠'
let g:ycm_filetype_whitelist = {"c": 1, "cpp": 1, "python": 1}
let g:ycm_min_num_of_chars_for_completion = 2
let g:ycm_show_diagnostics_ui = 1
let g:ycm_key_invoke_completion = '<c-z>'
let g:ycm_enable_diagnostic_signs = 0
let g:ycm_enable_diagnostic_highlighting = 1
let g:ycm_key_list_stop_completion = ['<C-y>', '<CR>']
let g:ycm_globle_ycm_extra_conf = '/Users/biblethump_cry/.ycm_extra_conf.py'
let g:ycm_key_list_select_completion = ['<Up>']
"let g:ycm_key_list_previous_completion = ['<Up>']
"let g:ycm_show_diagnostics_ui = 0

" for ultisnips:
let g:UltiSnipsExpandTrigger="<tab>"
let g:UltiSnipsJumpForwardTrigger="<c-s>"
let g:UltiSnipsJumpBackwardTrigger="<s-tab>"
let g:UltiSnipsEditSplit="vertical"
let g:UltiSnipsSnippetDirectorie=["UltiSnips", "plugged", "ultisnips"]

" for vim-cpp-modern:
let g:cpp_attributes_highlight = 1
"let g:cpp_member_highlight = 1

" for vim-airline:
let g:airline#extensions#tabline#enabled = 1

" quick query all leader maps:
" nnoremap <LEADER>? :nnoremap <LEADER><CR>

" for YouCompleteMe:
nnoremap <LEADER><LEADER> :YcmCompleter GoTo<CR>
nnoremap <LEADER>[ :YcmCompleter GoToDefinitionElseDeclaration<CR>
nnoremap <LEADER>d :YcmCompleter GetDoc<CR>
nnoremap <LEADER>r :YcmCompleter RefactorRename<SPACE>
nnoremap <LEADER>f :YcmCompleter FixIt<CR>1
nnoremap <LEADER>y :call ToggleYcmDiagnostics()<CR><CR>:wa<CR>:e<CR>
func! ToggleYcmDiagnostics()
    let g:ycm_show_diagnostics_ui = !g:ycm_show_diagnostics_ui
    YcmRestartServer
endfunc

" for nerdcommenter:
" nmap <LEADER>/ <LEADER>ci
" vmap <LEADER>/ <LEADER>ci

call plug#begin('~/.vim/plugged')

Plug 'vim-scripts/Tagbar'
Plug 'vim-scripts/surround.vim'
Plug 'preservim/nerdtree'
Plug 'archibate/QFixToggle'
Plug 'ycm-core/YouCompleteMe', {'do': './install.py --clang-completer'}
Plug 'vim-scripts/fugitive.vim'
Plug 'bfrg/vim-cpp-modern'
Plug 'vim-scripts/vim-airline'
Plug 'cskeeters/vim-smooth-scroll'
Plug 'tikhomirov/vim-glsl'
Plug 'junegunn/vim-slash'
Plug 'skywind3000/asyncrun.vim'
Plug 'vim-scripts/a.vim'
Plug 'machakann/vim-swap'
Plug 'preservim/nerdcommenter'
Plug 'peterhoeg/vim-qml'
Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'
Plug 'Shougo/vimproc.vim', {'do': 'make'}
Plug 'ilyachur/cmake4vim'
Plug 'ctrlpvim/ctrlp.vim'
Plug 'morhetz/gruvbox'

call plug#end()

if filereadable(".vim_localrc")
        source .vim_localrc
endif
