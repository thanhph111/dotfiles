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

# Color wrappers depend on the command variant.  GNU tools use --color=auto;
# macOS/BSD ls uses -G; and some minimal systems should get plain commands.
if command ls --color=auto -d . >/dev/null 2>&1; then
    ls() { command ls --color=auto "$@"; }
elif command ls -G -d . >/dev/null 2>&1; then
    ls() { command ls -G "$@"; }
fi

if dotfiles_command_exists dir && command dir --color=auto . >/dev/null 2>&1; then
    dir() { command dir --color=auto "$@"; }
fi

if dotfiles_command_exists vdir && command vdir --color=auto . >/dev/null 2>&1; then
    vdir() { command vdir --color=auto "$@"; }
fi

if printf '%s\n' x | command grep --color=auto x >/dev/null 2>&1; then
    grep() { command grep --color=auto "$@"; }
    fgrep() { command fgrep --color=auto "$@"; }
    egrep() { command egrep --color=auto "$@"; }
fi

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias lt='du -sh * | sort -h'
alias lsdir='ls -ld */'
alias lsfile='ls -flp | grep -v /'

alias reboot='sudo shutdown -r now'
alias shutdown='sudo shutdown -h now'

alias clean="clear && printf '\e[3J'"
alias printvar='(set -o posix; set)'

dotfiles_command_exists xdg-open && alias open=xdg-open
dotfiles_command_exists pwsh && alias pwsh='pwsh -NoLogo'
if dotfiles_command_exists wget && [ -f "$XDG_DATA_HOME/wget-hsts" ]; then
    wget() { command wget --hsts-file="$XDG_DATA_HOME/wget-hsts" "$@"; }
fi

alias python=python3
alias pip=pip3
alias mute-spotify-ads='(mute-spotify-ads >/dev/null 2>&1 &)'
alias npm-exec='PATH=$(npm bin):$PATH'

# Load KEY=value files into the current shell.  This intentionally stays a
# function, not an alias, so `set -a` is restored even when the file errors.
# shellcheck disable=SC3043
export_env_file() {
    local env_file="${1:-.env}"
    local had_allexport=0
    local env_status

    if [ ! -r "$env_file" ]; then
        printf '%s\n' "export_env_file: cannot read $env_file" >&2
        return 1
    fi

    case "$-" in
    *a*) had_allexport=1 ;;
    esac

    set -a
    # shellcheck source=/dev/null
    . "$env_file"
    env_status=$?

    [ "$had_allexport" = 1 ] || set +a
    return "$env_status"
}
