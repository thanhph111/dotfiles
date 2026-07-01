#!/bin/zsh

# Zsh completion.

if dotfiles_command_exists brew; then
    HOMEBREW_PREFIX="${HOMEBREW_PREFIX:-$(brew --prefix)}"
    FPATH="$HOMEBREW_PREFIX/share/zsh/site-functions:${FPATH}"
fi

# Add user completions before compinit builds the completion cache.
[[ -d "$SHELL_MODULE_DIR/completions" ]] &&
    FPATH="$SHELL_MODULE_DIR/completions:${FPATH}"

# Case-insensitive completion with increasingly flexible matching.
zstyle ':completion:*' matcher-list \
    'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' \
    'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*' \
    'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*' \
    'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*'

zstyle ':completion:*' cache-path "$SHELL_CACHE_DIR/completions"
zstyle ':completion:*' list-suffixes true
zstyle ':completion:*' expand prefix suffix
zstyle ':completion:*' menu select

setopt nolistambiguous
setopt globdots
setopt globstarshort

autoload -U colors && colors
autoload -Uz compinit && compinit -d "$SHELL_CACHE_DIR/completion"
