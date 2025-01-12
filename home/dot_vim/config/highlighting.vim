": Highlight {{{

": Colors for 'cterm'
":     NUMBER  COLOR NAME
":     0       Black
":     1       DarkRed
":     2       DarkGreen
":     3       DarkYellow
":     4       DarkBlue
":     5       DarkMagenta
":     6       DarkCyan
":     7       Gray
":     8       DarkGray
":     9       Red
":     10      Green
":     11      Yellow
":     12      Blue
":     13      Magenta
":     14      Cyan
":     15      White

": Most for whitespaces
    highlight NonText    cterm=NONE ctermfg=DarkGray ctermbg=NONE
    \                           guifg=#5c5d61    guibg=NONE
highlight SpecialKey cterm=NONE ctermfg=DarkGray ctermbg=NONE
    \                           guifg=#3c3e44    guibg=NONE

": Cursor line and number
highlight CursorLine   cterm=NONE ctermbg=Black
    \                             guibg=#181b26
highlight CursorLineNr cterm=bold ctermfg=DarkYellow
    \                             guifg=#cc7a00

": Diff view
highlight DiffAdd    cterm=bold ctermfg=NONE  ctermbg=22
    \                           guifg=NONE    guibg=#162620
highlight DiffDelete cterm=bold ctermfg=52    ctermbg=52
    \                           guifg=#2d1116 guibg=#2d1116
highlight DiffChange cterm=bold ctermfg=NONE  ctermbg=130
    \                           guifg=NONE    guibg=#342514
highlight DiffText   cterm=NONE ctermfg=NONE  ctermbg=DarkYellow
    \                           guifg=NONE    guibg=#473012

": Vertical split line
highlight VertSplit cterm=NONE ctermfg=White ctermbg=NONE
    \                          guifg=White   guibg=NONE

": Popup menu
highlight Pmenu      cterm=NONE ctermfg=White ctermbg=DarkBlue
    \                           guifg=White   guibg=#0a6ab6
highlight PmenuSel   cterm=bold ctermfg=White ctermbg=Blue
    \                           guifg=White   guibg=#0287c3
highlight PmenuSbar  cterm=NONE ctermfg=NONE  ctermbg=DarkCyan
    \                           guifg=NONE    guibg=#37aab9
highlight PmenuThumb cterm=NONE ctermfg=NONE  ctermbg=Cyan
    \                           guifg=NONE    guibg=#4ae3f7

": Keyword highlighting
highlight Error cterm=bold ctermfg=White ctermbg=DarkRed
    \                      guifg=White   guibg=DarkRed
highlight Todo  cterm=bold ctermfg=White ctermbg=DarkYellow
    \                      guifg=White   guibg=DarkYellow

": Visual mode selection
highlight Visual    cterm=NONE guifg=NONE      guibg=#2f3240
    \
": Visual mode selection when vim is "Not Owning the Selection"
highlight VisualNOS cterm=NONE ctermfg=DarkRed ctermbg=NONE
    \                          guifg=DarkRed   guibg=NONE

": Error and Warning message
highlight ErrorMsg   cterm=bold ctermfg=DarkRed    ctermbg=NONE
    \                           guifg=DarkRed      guibg=NONE
highlight WarningMsg cterm=bold ctermfg=DarkYellow ctermbg=NONE
    \                           guifg=DarkYellow   guibg=NONE

": Wildmenu uses StatusLine color for FB and BG colors
": This set colors for selection
highlight WildMenu cterm=bold ctermfg=DarkYellow ctermbg=White
    \                         guifg=#cc7a00      guibg=White

": Set color for a column (81) and fill all background from another column (120)
": Reference: https://stackoverflow.com/a/13731714
" let &colorcolumn="81,".join(range(120,999),",")
highlight ColorColumn ctermbg=Black
    \                 guibg=#141721

": }}}
