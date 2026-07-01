#!/bin/sh

# Small shared shell functions.
#
# Keep only functions that work in both Bash and Zsh here.  If a function needs
# arrays, bindkey, bind, or shell-specific options, put it in bash.d or zsh.d.

checksum() {
    if [ "$#" -eq 1 ]; then
        printf '%s\n' "$1" | shasum | awk '{ print $1 }'
        return
    fi

    printf '%s  %s\n' "$1" "$(realpath "$2")" | shasum -c
}

dsize() {
    du -hs "${1:-$(pwd)}"
}

detach() {
    ("$@" >/dev/null 2>&1 &)
}

mnt() {
    mount |
        awk -F' ' '{ printf "%s\t%s\n",$1,$3; }' |
        column -t |
        grep -E '^/dev/' |
        sort
}

if dotfiles_command_exists pactl; then
    toggle_mute() {
        pactl set-sink-mute @DEFAULT_SINK@ toggle
    }

    set_volume() {
        pactl set-sink-volume @DEFAULT_SINK@ "$1%"
    }
fi

# User function drop-ins.  Shared functions go in shell/functions; shell-specific
# functions go in shell/bash.d/functions or shell/zsh.d/functions.
dotfiles_source_dir "$DOTFILES_SHELL_ROOT/functions"
dotfiles_source_dir "$SHELL_MODULE_DIR/functions"
