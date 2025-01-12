": Netrw {{{

autocmd MyAutocmdGroup FileType netrw
    \ highlight CursorLine cterm=bold ctermfg=NONE ctermbg=NONE
    \                                 guifg=NONE   guibg=NONE

highlight netrwMarkFile cterm=bold ctermfg=DarkRed ctermbg=NONE
    \                              guifg=DarkRed   guibg=NONE

let g:netrw_liststyle = 3
let g:netrw_banner = 0
let g:netrw_preview = 1
let g:netrw_winsize = 30
let g:netrw_altv = 1

": }}}
