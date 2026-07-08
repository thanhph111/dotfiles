#!/bin/bash

# Bash line editing and shell options.

# Bash reads INPUTRC very early, before this repo's profile loader can set it in
# some shell launch paths.  Load it here too so interactive Bash always sees the
# same Readline settings.
[[ -r "${INPUTRC:-}" ]] && bind -f "$INPUTRC"

# Mimic Zsh's autolist + automenu: the first Tab lists every candidate and fills
# the common prefix, then each further Tab cycles to the next match and Shift-Tab
# to the previous one.  show-all-if-ambiguous draws the list, and
# menu-complete-display-prefix makes that first Tab settle the prefix instead of
# jumping straight into a match.  This overrides inputrc's "TAB: complete".
# Binding it here (not only in inputrc) covers shells that start before chezmoi
# has applied ~/.config/readline/inputrc.
bind 'set show-all-if-ambiguous on'
bind 'set show-all-if-unmodified on'
bind 'set menu-complete-display-prefix on'
bind 'TAB: menu-complete'
bind '"\e[Z": menu-complete-backward'

# Keep LINES and COLUMNS current after each command.
shopt -s checkwinsize

# Friendly directory spelling fixes.
shopt -s cdspell
shopt -s dirspell 2>/dev/null

# Recursive globbing with **.
shopt -s globstar 2>/dev/null
