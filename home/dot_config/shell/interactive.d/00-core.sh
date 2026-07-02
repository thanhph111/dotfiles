#!/bin/sh

# Common interactive environment.
#
# This file is for shell sessions a person types into.  It may define aliases,
# functions, and terminal behavior, but it should avoid Bash-only or Zsh-only
# features.  Shell-specific details live in bash.d and zsh.d.

# Let per-machine shell env files override or extend the profile environment.
# Values are exported automatically because these files usually contain simple
# KEY=value lines meant for child processes.
if [ -r "$DOTFILES_SHELL_ROOT/env" ]; then
    set -a
    # Machine-local env files are intentionally optional and dynamic.
    dotfiles_include "$DOTFILES_SHELL_ROOT/env"
    set +a
fi

if [ -r "$SHELL_MODULE_DIR/env" ]; then
    set -a
    # Machine-local env files are intentionally optional and dynamic.
    dotfiles_include "$SHELL_MODULE_DIR/env"
    set +a
fi

# Prefer Vim when available, while letting the parent process choose another
# editor by setting VISUAL already.
if [ -z "${VISUAL:-}" ] && dotfiles_command_exists vim; then
    export VISUAL=vim
fi

# Ignore noisy file suffixes in completion.
FIGNORE="${FIGNORE}:\
~:\
.DS_Store:\
.cmd:\
.hidden:\
.swp:\
.uuid"
export FIGNORE

# Keep less history under the cache tree.
mkdir -p "$USER_CACHE_DIR/less"
export LESSHISTFILE="$USER_CACHE_DIR/less/history"

# Disable XON/XOFF so Ctrl-S can be used by line editors and applications.
[ -t 0 ] && dotfiles_command_exists stty && stty -ixon

# Color GCC diagnostics in terminals that support color.
export GCC_COLORS="\
error=01;31:\
warning=01;35:\
note=01;36:\
caret=01;32:\
locus=01:\
quote=01"

# Color man pages through less termcap values.  This remains guarded because
# some minimal terminals report a TERM value but cannot answer tput correctly.
if [ -n "${TERM:-}" ] && [ "$TERM" != dumb ] && dotfiles_command_exists tput; then
    LESS_TERMCAP_mb="$(tput blink)"
    LESS_TERMCAP_md="$(
        tput bold
        tput setaf 6
    )"
    LESS_TERMCAP_me="$(tput sgr0)"
    LESS_TERMCAP_so="$(tput smso)"
    LESS_TERMCAP_se="$(
        tput rmso
        tput sgr0
    )"
    LESS_TERMCAP_us="$(
        tput smul
        tput bold
        tput setaf 7
    )"
    LESS_TERMCAP_ue="$(
        tput rmul
        tput sgr0
    )"
    LESS_TERMCAP_mr="$(tput rev)"
    LESS_TERMCAP_mh="$(tput dim)"
    LESS_TERMCAP_ZN="$(tput ssubm)"
    LESS_TERMCAP_ZV="$(tput rsubm)"
    LESS_TERMCAP_ZO="$(tput ssupm)"
    LESS_TERMCAP_ZW="$(tput rsupm)"
    export LESS_TERMCAP_mb LESS_TERMCAP_md LESS_TERMCAP_me
    export LESS_TERMCAP_so LESS_TERMCAP_se LESS_TERMCAP_us LESS_TERMCAP_ue
    export LESS_TERMCAP_mr LESS_TERMCAP_mh
    export LESS_TERMCAP_ZN LESS_TERMCAP_ZV LESS_TERMCAP_ZO LESS_TERMCAP_ZW
    export GROFF_NO_SGR=1
fi

# Keep very wide terminals from making man pages hard to read.
MANWIDTH=$((${COLUMNS:-80} > 120 ? 120 : ${COLUMNS:-80}))
export MANWIDTH
