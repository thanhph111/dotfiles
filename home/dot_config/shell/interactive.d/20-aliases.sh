#!/bin/sh

# Common aliases.
#
# Aliases are interactive only.  Scripts should keep seeing the real commands.

if [ -x /bin/dircolors ]; then
    if [ -r "$HOME/.dircolors" ]; then
        eval "$(/bin/dircolors -b "$HOME/.dircolors")"
    else
        eval "$(/bin/dircolors -b)"
    fi
fi

# Color and folder-first wrappers depend on the command variant.  GNU ls supports
# both --color=auto and --group-directories-first.  On macOS, Homebrew coreutils
# may provide that command as gls.
if command ls --group-directories-first --color=auto -d . >/dev/null 2>&1; then
    ls() { command ls --group-directories-first --color=auto "$@"; }
elif dotfiles_command_exists gls &&
    command gls --group-directories-first --color=auto -d . >/dev/null 2>&1; then
    ls() { command gls --group-directories-first --color=auto "$@"; }
elif command ls --color=auto -d . >/dev/null 2>&1; then
    ls() { command ls --color=auto "$@"; }
elif command ls -G -d . >/dev/null 2>&1; then
    ls() { command ls -G "$@"; }
fi

if printf '%s\n' x | command grep --color=auto x >/dev/null 2>&1; then
    grep() { command grep --color=auto "$@"; }
fi

alias ll='ls -lhAF'
alias la='ls -A'
alias l='ls -CF'

alias reboot-now='sudo shutdown -r now'
alias shutdown-now='sudo shutdown -h now'

if ! dotfiles_command_exists open && dotfiles_command_exists xdg-open; then
    alias open=xdg-open
fi
dotfiles_command_exists pwsh && alias pwsh='pwsh -NoLogo'
if dotfiles_command_exists wget && [ -f "$XDG_DATA_HOME/wget-hsts" ]; then
    wget() { command wget --hsts-file="$XDG_DATA_HOME/wget-hsts" "$@"; }
fi
