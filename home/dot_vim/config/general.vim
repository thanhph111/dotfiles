
": General {{{

": Enter the current millennium
set nocompatible

": Enables 24-bit RGB color in the TUI
set termguicolors

": Allow backspacing over everything in insert mode.
set backspace=indent,eol,start

": Keep 200 lines of command line history
set history=200

": Show the cursor position all the time
set ruler

": Display incomplete commands
set showcmd

": Display completion matches in a status line
set wildmenu
set wildmode=longest:full
set wildignorecase
set wildignore+=*.DS_Store,*.class,*.hg,*.o,*.obj,*.pyc,*.svn,*.swp
set wildignore+=.git,composer.lock,package-lock.json

": Time out for key codes
set ttimeout
": Wait up to 100ms after `<Esc>` for special key
set ttimeoutlen=100

": Keep 3 lines below or above the cursor
set scrolloff=3

": Don't recognize octal numbers for `<Ctrl-A>` and `<Ctrl-X>`
set nrformats-=octal

": Set line number as relative position
set number
set relativenumber

": Do incremental searching when it's possible to timeout
set incsearch

": No time for case sensitive
set ignorecase

": But if you type in uppercase, it will be case sensitive
set smartcase


": Highlight search matches
set hlsearch

": Allow to interact with mouse
set mouse=a

": Enable file type detection
filetype plugin indent on

": Switch syntax highlighting
syntax on

": I like highlighting strings inside C comments.
let c_comment_strings=1

": Prevent the langmap option applies to characters that result from a mapping
set nolangremap

": Tell Vim find the color scheme for the dark theme
": This is my theme:
":     foreground           #fffaf4
":     background           #0e1019
":     selection_foreground #181c27
":     selection_background #ffffff
":     color0               #181a1b
":     color8               #555b5e
":     color1               #a91409
":     color9               #ff3078
":     color2               #38803a
":     color10              #addd1e
":     color3               #cc7a00
":     color11              #ffec16
":     color4               #0a6ab6
":     color12              #0287c3
":     color5               #522e92
":     color13              #d10aff
":     color6               #37aab9
":     color14              #4ae3f7
":     color7               #788187
":     color15              #dcdfe4
set background=dark

": Auto change directory to a file location
": Because I usually use Vim to edit scattered files, this may help
": Set this also change CWD by using `cd` in netrw
set autochdir

": Auto indent when starting a new line
set autoindent
set smartindent

": Set tab width and auto expand tabs to space
set tabstop=4
set shiftwidth=4
set expandtab

": Disable showing whitespaces by default
set nolist

": Set whitespace characters
set listchars=eol:$,tab:>-,trail:~,extends:>,precedes:<,space:·

": Hide end of buffer symbol
set fillchars+=eob:\ "

": Disable intro
set shortmess+=I

": Always show the status line
set laststatus=2

": Don't show current mode indicator as we customize status line
set noshowmode

": Set title for filename
set title
": This used the same rules for 'statusline'
set titlestring=%t\ ✤\ VIM

": Wrap Vim's execution of all commands
": Minimum content to clear the screen before executing a command
":     #!/bin/bash
":     clear
":     shift
":     eval $@
if filereadable("~/.vim/shell.sh")
    set shell=~/.vim/shell.sh
endif

": Splitting will open windows on the right or below instead of the opposite
set splitright
set splitbelow

": Automatically read a file when it's changed outside of Vim
": Sometime we still have to use `:e` to reload the file
set autoread

": Allow wrapping of long lines
set wrap

": Wrap long lines at a character in 'breakat' rather than at the last
": character that fits on the screen.
set linebreak

": Every wrapped line will continue visually indented
set breakindent

": Change the default vertical split character, avoid spaces between lines
set fillchars+=vert:\┃  ": Use this for thinner line: `\│`
" set fillchars+=vert:\█

": Set this to always use system clipboard
" set clipboard=unnamedplus

": Don't truncate the line if it's not fit
set display=lastline

": Allow use bash aliases in external commands
": TODO: Split the bash aliases to `~/.bash_aliases` and use this to retrieve
": Reference: https://stackoverflow.com/a/18901595
if filereadable("~/.bash_aliases")
    let $BASH_ENV = "~/.bash_aliases"
endif

": Go to end of previous line or beginning of next line by arrows or `<H>`/`<L>`
": Reference: https://stackoverflow.com/a/63097471
set whichwrap+=<,h
set whichwrap+=>,l
set whichwrap+=[,]

": Search recursively
": Provides tab-completion for all file-related tasks
": Be careful if you are standing on a big CWD like '/' or '~'
set path+=**

": Set main encoding displayed
set encoding=utf-8

": Set main encoding written to files
set fileencoding=utf-8

": Use a line cursor within insert mode and a block cursor everywhere else
": I have set my terminal to beam cursor
": Cursor settings:
":     1 -> Blinking block
":     2 -> Solid block
":     3 -> Blinking underline
":     4 -> Solid underline
":     5 -> Blinking beam
":     6 -> Solid beam
let &t_SI = "\e[5 q"  ": INSERT mode
let &t_SR = "\e[3 q"  ": REPLACE mode
let &t_EI = "\e[1 q"  ": NORMAL mode (ELSE)
": The cursor is still beam when opening, let's cheat a bit
autocmd MyAutocmdGroup VimEnter * silent execute '!echo -e "' . &t_EI . '"'
": Restore the cursor when exiting
autocmd MyAutocmdGroup VimLeave * silent execute '!echo -ne "' . &t_SI . '"'
": Undercurl support
try
    let &t_Cs = "\e[4:3m"
    let &t_Ce = "\e[4:0m"
catch
endtry
": Vim hardcodes background color erase even if the terminfo file does not
": contain bce. This causes incorrect background rendering when using a color
": theme with a background color.
let &t_ut=''

": Allow overflow buffer
set hidden

": Spell check
set spell
set spelllang=en_us

": Set timeout for key press, allow using some keybinding with escape key
": Reference: https://www.johnhawthorn.com/2012/09/vi-escape-delays/
set timeoutlen=1000
set ttimeoutlen=0

": }}}
