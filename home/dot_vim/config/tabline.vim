": Tab line {{{

function MyTabLine()
    let s = ''
    for i in range(tabpagenr('$'))
        ": Select the highlighting
        if i + 1 == tabpagenr()
            let tab_none = '%#Tab_Active_Tab_None#'
            let text_tab = '%#Tab_Active_Text_Tab#'
            let close_tab = '%#Tab_Active_Close_Tab#'
            let text_close = '%#Tab_Active_Text_Close#'
            let close_none = '%#Tab_Active_Close_None#'
        else
            let tab_none = '%#Tab_InActive_Tab_None#'
            let text_tab = '%#Tab_InActive_Text_Tab#'
            let close_tab = '%#Tab_InActive_Close_Tab#'
            let text_close = '%#Tab_InActive_Text_Close#'
            let close_none = '%#Tab_InActive_Close_None#'
        endif
        "
        let bufferList = tabpagebuflist(i + 1)
        let winNumber = tabpagewinnr(i + 1)
        let tabName = bufname(bufferList[winNumber - 1])
        ": Set the tab page number (for mouse clicks)
        let s .= '%' . (i + 1) . 'T'
        ": Set the tab name
        let s .= tab_none . ''
        let s .= text_tab
        let s .= ' ' . (i + 1)
        let s .= (tabName != '' ? ('  ' . tabName) : '') . ' '
        let s .= '%T'
        ": Set the close button
        let s .= '%' . (i + 1) . 'X'
        let s .= close_tab . ''
        let s .= text_close . ''
        let s .= close_none . ''
        let s .= '%X'
        let s .= '%* '
    endfor
    return s
endfunction
set tabline=%!MyTabLine()

highlight TabLineFill cterm=NONE ctermfg=NONE ctermbg=NONE
    \                            guifg=NONE   guibg=NONE

highlight Tab_Active_Tab_None   cterm=NONE ctermfg=DarkGreen ctermbg=NONE
    \                                      guifg=DarkGreen   guibg=NONE
highlight Tab_Active_Text_Tab   cterm=NONE ctermfg=White     ctermbg=DarkGreen
    \                                      guifg=White       guibg=DarkGreen
highlight Tab_Active_Close_Tab  cterm=NONE ctermfg=DarkRed   ctermbg=DarkGreen
    \                                      guifg=DarkRed     guibg=DarkGreen
highlight Tab_Active_Text_Close cterm=NONE ctermfg=White     ctermbg=DarkRed
    \                                      guifg=White       guibg=DarkRed
highlight Tab_Active_Close_None cterm=NONE ctermfg=DarkRed   ctermbg=NONE
    \                                      guifg=DarkRed     guibg=NONE

highlight Tab_InActive_Tab_None   cterm=NONE ctermfg=White     ctermbg=NONE
    \                                        guifg=White       guibg=NONE
highlight Tab_InActive_Text_Tab   cterm=NONE ctermfg=Black     ctermbg=White
    \                                        guifg=Black       guibg=White
highlight Tab_InActive_Close_Tab  cterm=NONE ctermfg=DarkRed   ctermbg=White
    \                                        guifg=DarkRed     guibg=White
highlight Tab_InActive_Text_Close cterm=NONE ctermfg=White     ctermbg=DarkRed
    \                                        guifg=White       guibg=DarkRed
highlight Tab_InActive_Close_None cterm=NONE ctermfg=DarkRed   ctermbg=NONE
    \                                        guifg=DarkRed     guibg=NONE

": }}}
