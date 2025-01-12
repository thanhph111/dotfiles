": Autocommands {{{

": Institutive moving line
": Reference: https://stackoverflow.com/a/21000307
nnoremap <expr> j v:count ? 'j' : 'gj'
nnoremap <expr> k v:count ? 'k' : 'gk'

": Set current line only in insert mode
autocmd MyAutocmdGroup InsertEnter * set cursorline
autocmd MyAutocmdGroup InsertLeave * set nocursorline

": Auto-trim trailing whitespaces and fix EOL on save
": Don't turn off 'fixeol' if you want to keep last trailing newline
": Reference: https://unix.stackexchange.com/a/75438
": Reference: https://stackoverflow.com/a/7501902
function! <SID>FixTrailingWhitespacesAndEol()
    let l = line(".")
    let c = col(".")
    silent! %s/\s\+$//e
    " %s#\($\n\s*\)\+\%$##
    silent! 0;/^\%(\n*.\)\@!/,$d
    call cursor(l, c)
endfun
autocmd MyAutocmdGroup BufWritePre * :call <SID>FixTrailingWhitespacesAndEol()

": When editing a file, always jump to the last known cursor position
autocmd MyAutocmdGroup BufReadPost *
    \ if line("'\"") >= 1 && line("'\"") <= line("$") && &ft !~# 'commit'
    \ |   exe "normal! g`\""
    \ | endif

": Ask for creating a new file with path if it doesn't exist when writing
autocmd MyAutocmdGroup BufWritePre *
    \ call s:auto_mkdir(expand('<afile>:p:h'), v:cmdbang)
function! s:auto_mkdir(dir, force)
    if !isdirectory(a:dir) && (
        \ a:force ||
        \ input(
            \ "'" . a:dir . "' does not exist. Create? [y/N]"
        \ ) =~? '^y\%[es]$'
    \ )
        call mkdir(iconv(a:dir, &encoding, &termencoding), 'p')
    endif
endfunction

": Make command mode case insensitive
": Reference: https://vi.stackexchange.com/a/16511
autocmd MyAutocmdGroup CmdLineEnter :set nosmartcase ignorecase
autocmd MyAutocmdGroup CmdLineLeave :set smartcase noignorecase

": Auto close brackets when adding a new line after them
inoremap {<CR> {<CR>}<c-o><s-o>
inoremap [<CR> [<CR>]<c-o><s-o>
inoremap (<CR> (<CR>)<c-o><s-o>

": Hot reload $MYVIMRC
autocmd MyAutocmdGroup BufWritePost .vimrc,_vimrc source $MYVIMRC

": Change the background mode based on macOS's `Appearance` setting
": Initialize the colorscheme for the first run
call utils#change_background()
": Change the color scheme if we receive a SigUSR1: `kill -SIGUSR1 $pid`
autocmd MyAutocmdGroup SigUSR1 * call utils#change_background()

": }}}
