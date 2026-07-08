#!/bin/bash

# Bash completion.

if ! shopt -oq posix; then
    if dotfiles_command_exists brew; then
        HOMEBREW_PREFIX="${HOMEBREW_PREFIX:-$(brew --prefix)}"
        dotfiles_include "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh"
    fi

    # Modern bash-completion lazy-loads command completions when Tab is pressed.
    # Source only one framework here; do not also loop through completion.d files,
    # because that directory is an old eager-load path and the framework already
    # handles it when needed.
    [ -n "${BASH_COMPLETION_VERSINFO:-}" ] ||
        dotfiles_include /usr/share/bash-completion/bash_completion
    [ -n "${BASH_COMPLETION_VERSINFO:-}" ] ||
        dotfiles_include /etc/bash_completion
fi
