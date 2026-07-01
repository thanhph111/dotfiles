#!/bin/bash

# Bash line editing and shell options.

# Disable XON/XOFF so Ctrl-s can be used by readline search and applications.
[ -t 0 ] && [ -x /bin/stty ] && /bin/stty -ixon

# Avoid running pasted text immediately when it contains newlines.
bind 'set enable-bracketed-paste on'

# Show completion choices on the first Tab press.
bind 'set show-all-if-ambiguous on'

# Keep LINES and COLUMNS current after each command.
shopt -s checkwinsize

# Friendly directory spelling fixes.
shopt -s cdspell
shopt -s dirspell 2>/dev/null

# Recursive globbing with **.
shopt -s globstar 2>/dev/null
