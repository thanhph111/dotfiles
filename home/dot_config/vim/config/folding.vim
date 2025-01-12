": Fold text {{{

": Never automatically fold
set foldlevelstart=99

": Does it lose the ability to fold by syntax?
" set foldmethod=marker

": Fill characters for folding
set fillchars+=fold:=
": The rest is used for testing
set fillchars+=foldopen:b,foldclose:c,foldsep:d

function MyFoldText()
    let line = getline(v:foldstart)
    let level_points = repeat(" ", v:foldlevel)[:-2]
    let pattern = '/\*\|\*/\|' . split(&foldmarker, ',')[0] . '\d*'
    let sub = substitute(line,  pattern, level_points, 'g')
    return  sub . ' <=<< ' . (v:foldend - v:foldstart + 1) . ' lines' . ' >>'
endfunction
set foldtext=MyFoldText()

": Highlight fold text
highlight Folded     cterm=bold ctermfg=DarkGray ctermbg=NONE
    \                           guifg=#5c6070    guibg=NONE
": Invisible fold column
highlight FoldColumn cterm=NONE ctermfg=NONE     ctermbg=NONE
    \                           guifg=NONE       guibg=NONE

": }}}
