#!/bin/bash

# Bash-only functions.
#
# These use Bash syntax or Bash builtins, so they stay out of shared modules.

is_termcap_name() {
    # Ask terminals that support XTerm device-control queries for their terminal
    # name.  This is useful when TERM is generic but the terminal has features
    # worth detecting.
    printf $'\eP+q544e\e\\'
    read -rs -t 0.05 -d $'\\' code
    [[ "$(printf '%s' "${code:10:-1}" | xxd -r -p)" == "$1" ]]
}

is_kitty() {
    is_termcap_name xterm-kitty
}

is_wezterm() {
    is_termcap_name WezTerm
}

# Start a child Bash that keeps history in memory only.
bashout() {
    DOTFILES_HISTORY=private NO_HISTORY=1 bash -i "$@"
}

# Add an alert for long-running commands, used like: sleep 3; alert
alert() (
    local last_error_code=$?
    local last_command title

    shopt -s extglob
    last_command="$(history | tail -n 1)"
    last_command="${last_command##*([ ])*([0-9])*([ ])}"
    last_command="${last_command%%*( )@(;|&&|\|)*( )alert*( )}"

    if [[ $last_error_code -eq 0 ]]; then
        title="Command finished"
    else
        title="Command failed"
    fi

    command -v notify >/dev/null 2>&1 &&
        notify "$last_command" "$title" "$([[ $last_error_code -eq 0 ]] && printf terminal || printf error)"
)
