": Autocomplete {{{

set omnifunc=syntaxcomplete#Complete
set completeopt=longest,menuone,noinsert

": Set this to add dictionary words to the autocomplete list
" set complete+=kspell

": `<Tab>` to accept
": This doesn't work
" inoremap <expr> <CR> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"

": `<C-Space>` to toggle default menu
inoremap <expr> <C-Space> pumvisible() \|\| &omnifunc == '' ?
    \ "\<lt>C-n>" :
    \ "\<lt>C-x>\<lt>C-o><c-r>=pumvisible() ?" .
    \ "\"\\<lt>c-n>\\<lt>c-p>\\<lt>c-n>\" :" .
    \ "\" \\<lt>bs>\\<lt>C-n>\"\<CR>"
imap <C-@> <C-Space>

": }}}
