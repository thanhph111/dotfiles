": Status line {{{

": Reference: https://gist.github.com/meskarune/57b613907ebd1df67eb7bdb83c6e6641

let g:currentmode={
    \ 'n'      : 'Normal',
    \ 'no'     : 'Normal·Operator Pending',
    \ 'v'      : 'Visual',
    \ 'V'      : 'V·Line',
    \ "\<C-V>" : 'V·Block',
    \ 's'      : 'Select',
    \ 'S'      : 'S·Line',
    \ '^S'     : 'S·Block',
    \ 'i'      : 'Insert',
    \ 'R'      : 'Replace',
    \ 'Rv'     : 'V·Replace',
    \ 'c'      : 'Command',
    \ 'cv'     : 'Vim Ex',
    \ 'ce'     : 'Ex',
    \ 'r'      : 'Prompt',
    \ 'rm'     : 'More',
    \ 'r?'     : 'Confirm',
    \ '!'      : 'Shell',
    \ 't'      : 'Terminal'
\}

function! GitBranch()
    return system("git rev-parse --abbrev-ref HEAD 2>/dev/null | tr -d '\n'")
endfunction

function! StatuslineGit()
    let l:branchname = GitBranch()
    return strlen(l:branchname) > 0?'  '.l:branchname.' ':''
endfunction

set statusline=
set statusline+=%#Status_01_None#
set statusline+=%0*\ %n
set statusline+=%0*\ \ "
set statusline+=%0*%{toupper(g:currentmode[mode()])}\ "
set statusline+=%#Status_01_02#
set statusline+=%#Status_Text_02#\ %<%t%h%w%m%r\ "
set statusline+=%#Status_02_03#
set statusline+=%#Status_Text_03#\ %Y\ "
set statusline+=%#Status_03_03#%=
set statusline+=%#Status_Text_03#\ %{''.toupper(&fenc!=''?&fenc:&enc).''}
set statusline+=%#Status_Text_03#\ \ %{toupper(&ff)}\ "
set statusline+=%#Status_02_03#
set statusline+=%#Status_Text_02#\ %l:%c%V\ \ %L\ "
set statusline+=%#Status_01_02#
set statusline+=%#Status_Text_01#\ %03p%%\ "
set statusline+=%#Status_01_None#
set statusline+=%*
set statusline+=
" set statusline+=%{StatuslineGit()}

highlight Status_01_None cterm=NONE ctermfg=White    ctermbg=NONE
    \                               guifg=White      guibg=NONE
highlight Status_Text_01 cterm=NONE ctermfg=Black    ctermbg=White
    \                               guifg=Black      guibg=White
highlight Status_01_02   cterm=NONE ctermfg=White    ctermbg=DarkGray
    \                               guifg=White      guibg=#5c6070
highlight Status_Text_02 cterm=NONE ctermfg=White    ctermbg=DarkGray
    \                               guifg=White      guibg=#5c6070
highlight Status_02_03   cterm=NONE ctermfg=DarkGray ctermbg=237
    \                               guifg=#5c6070    guibg=#2c3040
highlight Status_Text_03 cterm=NONE ctermfg=White    ctermbg=237
    \                               guifg=White      guibg=#2c3040
highlight Status_03_03   cterm=NONE ctermfg=237      ctermbg=237
    \                               guifg=#2c3040    guibg=#2c3040

": Vim will reset `stl` to '^' if `stl` and `stlnc` are the same
": Because we've set them to invisible, we don't have to worry about this
" set fillchars+=stl:\ ,stlnc:\ "

": Don't reverse but bold
highlight StatusLine       cterm=bold ctermfg=Black    ctermbg=White
    \                                 guifg=Black      guibg=White
highlight StatusLineNC     cterm=NONE ctermfg=DarkGray ctermbg=White
    \                                 guifg=DarkGray   guibg=White
highlight StatusLineTerm   cterm=bold ctermfg=Black    ctermbg=White
    \                                 guifg=Black      guibg=White
highlight StatusLineTermNC cterm=NONE ctermfg=DarkGray ctermbg=White
    \                                 guifg=DarkGray   guibg=White

": Indicator for modes
function InsertStatusColor()
    highlight StatusLine cterm=bold ctermfg=DarkGreen ctermbg=White
        \                           guifg=DarkGreen   guibg=White
endfunction
function CommandStatusColor()
    highlight StatusLine cterm=bold ctermfg=DarkBlue ctermbg=White
        \                           guifg=DarkBlue   guibg=White
    redraw
endfunction
function ResetStatusColor()
    highlight StatusLine cterm=bold ctermfg=Black ctermbg=White
        \                           guifg=Black   guibg=White
endfunction
autocmd MyAutocmdGroup InsertEnter * :call InsertStatusColor()
autocmd MyAutocmdGroup InsertLeave * :call ResetStatusColor()
autocmd MyAutocmdGroup CmdlineEnter * :call CommandStatusColor()
autocmd MyAutocmdGroup CmdlineLeave * :call ResetStatusColor()

": }}}
