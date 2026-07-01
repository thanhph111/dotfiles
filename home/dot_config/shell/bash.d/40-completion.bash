#!/bin/bash

# Bash completion.

! shopt -oq posix && dotfiles_include /etc/bash_completion

if dotfiles_command_exists brew; then
    HOMEBREW_PREFIX="${HOMEBREW_PREFIX:-$(brew --prefix)}"
    dotfiles_include "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh"

    for completion in "$HOMEBREW_PREFIX"/etc/bash_completion.d/*; do
        dotfiles_include "$completion"
    done
    unset completion
fi

if dotfiles_command_exists kubectl; then
    alias k=kubectl
    complete -o default -F __start_kubectl k 2>/dev/null || true
fi

dotfiles_source_dir "$SHELL_MODULE_DIR/completions"
