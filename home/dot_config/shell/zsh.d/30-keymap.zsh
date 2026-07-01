#!/bin/zsh

# Zsh line editing and shell options.

# Treat '/', '-', '.', and '=' as word separators for word movement/deletion.
WORDCHARS='*?_[]~&;!#$%^(){}<>'

# Push old directories onto the stack so popd can return to them.
setopt AUTO_PUSHD

# Word movement.
bindkey "\e[1;3D" backward-word
bindkey "\e[1;3C" forward-word
bindkey "\e[3;3~" kill-word

# Prefix history search.
bindkey '^[[A' up-line-or-search
bindkey '^[[B' down-line-or-search

# Cmd-delete or Cmd-fn-delete in terminals that send this sequence.
bindkey '\e[3;9~' kill-line

# Shift-Tab reverses menu completion.
bindkey '\e[Z' reverse-menu-complete

# Ctrl-x Ctrl-e opens the current command line in $EDITOR.
autoload -U edit-command-line
zle -N edit-command-line
bindkey '^x^e' edit-command-line
