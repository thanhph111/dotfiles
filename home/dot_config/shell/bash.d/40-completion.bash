#!/bin/bash

# Bash completion.

if ! shopt -oq posix; then
    dotfiles_completion_loaded="${BASH_COMPLETION_VERSINFO:+1}"

    if dotfiles_command_exists brew; then
        HOMEBREW_PREFIX="${HOMEBREW_PREFIX:-$(brew --prefix)}"
        dotfiles_brew_completion="$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh"

        if [ -r "$dotfiles_brew_completion" ]; then
            # Prefer Homebrew's bash-completion@2 loader when it is installed.
            # Login Bash can load the distro completion framework from
            # /etc/profile.d before ~/.bashrc runs; Homebrew's loader exits
            # when BASH_COMPLETION_VERSINFO is already set, so clear that guard
            # and let Homebrew own completion paths for Homebrew packages.
            unset BASH_COMPLETION_VERSINFO
            dotfiles_include "$dotfiles_brew_completion"
            [ -n "${BASH_COMPLETION_VERSINFO:-}" ] &&
                dotfiles_completion_loaded=1
        fi
    fi

    # Modern bash-completion lazy-loads command completions when Tab is pressed.
    # Source only one framework here; do not also loop through completion.d files,
    # because that directory is an old eager-load path and the framework already
    # handles it when needed.
    [ -n "$dotfiles_completion_loaded" ] ||
        dotfiles_include /usr/share/bash-completion/bash_completion
    [ -n "${BASH_COMPLETION_VERSINFO:-}" ] &&
        dotfiles_completion_loaded=1
    [ -n "$dotfiles_completion_loaded" ] ||
        dotfiles_include /etc/bash_completion

    unset dotfiles_brew_completion dotfiles_completion_loaded
fi
