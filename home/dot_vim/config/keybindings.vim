": Keybindings {{{

": `Ctrl-C` is annoying, map it to `<Esc>`
imap <C-c> <Esc>

": Don't use Ex mode, use `Q` for formatting
map Q gq

": `Ctrl-L` in insert mode to fix latest spelling mistake
": Reference: https://stackoverflow.com/a/16481737
imap <c-l> <c-g>u<Esc>[s1z=`]a<c-g>u

": `CTRL-U` in insert mode deletes a lot. Use `CTRL-G` u to first break undo,
": so we can undo `CTRL-U` after inserting a line break.
inoremap <C-U> <C-G>u<C-U>

nnoremap <Leader>do :DiffOrig<CR>
nnoremap <Leader>dc :only<CR>diffoff<CR>

": `<F2>` to toggle spell check
": https://github.com/nickjj/dotfiles/blob/master/.vimrc
map <F2> :setlocal spell!<CR>

": `<F3>` to toggle `hlsearch`
nnoremap <F3> :set hlsearch!<CR>

": `<F4>` to toggle `wrap`
nnoremap <F4> :set wrap!<CR>

": `<F5>` to toggle relative numbers
noremap <F5> :set number!<CR>
inoremap <F5> <C-o>:set number!<CR>
cnoremap <F5> <C-o>:set number!<CR>

": `<F6>` to toggle relative numbers
noremap <F6> :set relativenumber!<CR>
inoremap <F6> <C-o>:set relativenumber!<CR>
cnoremap <F6> <C-o>:set relativenumber!<CR>

": `<F7>` to toggle visually showing all whitespace characters
noremap <F7> :set list!<CR>
inoremap <F7> <C-o>:set list!<CR>
cnoremap <F7> <C-c>:set list!<CR>

": `:W!` sudo saves the file
": Reference: https://github.com/amix/vimrc/blob/master/vimrcs/basic.vim
command! -bang W execute 'w !sudo tee % >/dev/null' <bar> edit!

": When in command mode, do as the Emacs do
cnoremap <C-a> <Home>
cnoremap <C-e> <End>
cnoremap <C-b> <Left>
cnoremap <C-f> <Right>
execute "set <A-b>=\eb"
cnoremap <A-b> <S-Left>
execute "set <A-f>=\ef"
cnoremap <A-f> <S-Right>

": When in insert mode, do as the Emacs do
inoremap <C-a> <Home>
inoremap <C-e> <End>
inoremap <C-b> <Left>
inoremap <C-n> <Down>
inoremap <C-p> <Up>
inoremap <C-f> <Right>
execute "set <A-b>=\eb"
inoremap <A-b> <S-Left>
execute "set <A-f>=\ef"
inoremap <A-f> <S-Right>

": Reference: https://github.com/taufik-nurrohman/vim/blob/main/.vim/vimrc
": Preserve visual block selection after indent/outdent
vnoremap > >gv^
vnoremap < <gv^

": Navigate between split(s) with `<CTRL+LEFT/DOWN/UP/RIGHT>`
nnoremap <C-Left> <C-w>h
nnoremap <C-Down> <C-w>j
nnoremap <C-Up> <C-w>k
nnoremap <C-Right> <C-w>l

": Navigate between split(s) with `<CTRL+H/J/K/L>`
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

": Navigate to other split(s) from terminal with `<CTRL+LEFT/DOWN/UP/RIGHT>`
tnoremap <C-Left> <C-w>h
tnoremap <C-Down> <C-w>j
tnoremap <C-Up> <C-w>k
tnoremap <C-Right> <C-w>l

": New tab with `<\t>`
nnoremap <silent> <Leader>t :tabnew<CR>

": <\yp> to yank the current buffer's full path to the clipboard
nnoremap <Leader>yp :let @+ = expand("%:p")<CR>

": <\yt> to yank the current buffer's name (tail) to the clipboard
nnoremap <Leader>yt :let @+ = expand("%:t")<CR>

": <\yh> to yank the current buffer's directory (head))  to the clipboard
nnoremap <Leader>yh :let @+ = expand("%:p:h")<CR>

": Fast command line access
nnoremap ; :
nnoremap : ;

": Better defaults for searching
nnoremap / /\v
vnoremap / /\v

": Quick edit vimrc
nnoremap <leader>ev :vsplit $MYVIMRC<cr>
nnoremap <leader>sv :source $MYVIMRC<cr>

": }}}
