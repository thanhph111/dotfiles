": Vim files {{{

": Reference: https://stackoverflow.com/a/9528322
": Save your backup files to a less annoying place than the current directory.
": If you have `.vim-backup` folder in the current directory, it'll use that.
": Otherwise it saves it to `~/.cache/vim/backup` or `.`.
if isdirectory($HOME . '/.cache/vim/backup') == 0
    :silent !mkdir -p ~/.cache/vim/backup >/dev/null 2>&1
endif
set backupdir-=.
set backupdir+=.
set backupdir-=~/
set backupdir^=~/.cache/vim/backup/
set backupdir^=./.vim-backup/
set backup

": Save your swap files to a less annoying place than the current directory.
": If you have `.vim-swap` in the current directory, it'll use that.
": Otherwise it saves it to `~/.cache/vim/swap`, `~/tmp` or `.`.
if isdirectory($HOME . '/.cache/vim/swap') == 0
    :silent !mkdir -p ~/.cache/vim/swap >/dev/null 2>&1
endif
set directory=./.vim-swap//
set directory+=~/.cache/vim/swap//
set directory+=~/tmp//
set directory+=.

": `viminfo` stores the state of your previous editing session
set viminfo+=n~/.cache/vim/viminfo

if exists("+undofile")
    ": `undofile` - This allows you to use undos after exiting and restarting
    ": This, like swap and backup files, uses `.vim-undo`, then
    ": `~/.cache/vim/undo`
    ": This is only present in 7.3+. Read more: `:help undo-persistence`
    if isdirectory($HOME . '/.cache/vim/undo') == 0
        :silent !mkdir -p ~/.cache/vim/undo > /dev/null 2>&1
    endif
    set undodir=./.vim-undo//
    set undodir+=~/.cache/vim/undo//
    set undofile
endif

": `.netrwhist` stores the history all the directories that were modified
let g:netrw_home = '~/.cache/vim'

": }}}
