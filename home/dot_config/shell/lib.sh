#!/bin/sh

# Shared shell helpers.
#
# This file is intentionally small.  It owns plumbing only: source another file,
# test for commands, work with PATH, and load module directories.  Real shell
# behavior belongs in profile.d, interactive.d, bash.d, zsh.d, or final.d.

# Source a file only when it exists and is readable.
dotfiles_include() {
    # The caller owns the path.  This helper is deliberately dynamic so small
    # machine-local files can be sourced without adding new loader code.
    # shellcheck disable=SC1090
    [ -r "$1" ] && [ -f "$1" ] && . "$1"
}

# Return success when a command can be found through PATH.
dotfiles_command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Add a directory to the front of PATH once.
dotfiles_path_prepend() {
    [ -n "$1" ] && [ -d "$1" ] || return 0
    case ":$PATH:" in
    *:"$1":*) ;;
    *) PATH="$1${PATH:+:$PATH}" ;;
    esac
}

# Add a directory to the end of PATH once.
dotfiles_path_append() {
    [ -n "$1" ] && [ -d "$1" ] || return 0
    case ":$PATH:" in
    *:"$1":*) ;;
    *) PATH="${PATH:+$PATH:}$1" ;;
    esac
}

# Expand a leading "~" in values passed through environment variables.
#
# Shells expand "~" only when it appears directly in shell code.  Values from
# VS Code, SSH, or other parent processes are plain strings, so we expand the
# common "~/" form before handing paths to tools like Oh My Posh.
dotfiles_expand_home() {
    case "$1" in
    \~) printf '%s\n' "$HOME" ;;
    \~/*) printf '%s\n' "$HOME/${1#\~/}" ;;
    *) printf '%s\n' "$1" ;;
    esac
}

# Source all regular files in a module directory.
#
# Names carry order.  For example, 00-base.sh runs before 90-paths.sh.
dotfiles_source_dir() {
    [ -d "$1" ] || return 0

    # List the directory with find rather than a "$1"/* glob.  An empty directory
    # makes zsh abort on the unmatched glob unless a zsh-only option is set, and
    # this loader stays shell-neutral.  sort restores the by-name order a glob
    # would give (00-base.sh before 90-paths.sh); find prints in directory order.
    # "! -name '.*'" skips hidden files so a stray .DS_Store is never sourced.
    dotfiles_modules="$(
        find "$1" -mindepth 1 -maxdepth 1 ! -name '.*' -print 2>/dev/null | sort
    )"

    # Read the list on fd 3, not stdin.  A sourced module may read stdin or test
    # whether stdin is a terminal, so leave fd 0 alone: otherwise the module sees
    # this list as its input and drains it, cutting the loop short.
    while IFS= read -r dotfiles_module <&3; do
        [ -n "$dotfiles_module" ] || continue
        [ -f "$dotfiles_module" ] || continue
        # shellcheck disable=SC1090
        . "$dotfiles_module"
    done 3<<EOF
$dotfiles_modules
EOF

    unset dotfiles_module
    unset dotfiles_modules
}

# Remove loader helpers after startup has finished.  They are useful while the
# dotfiles are being assembled, but they should not become part of the everyday
# interactive shell surface.
dotfiles_unload_helpers() {
    unset -f \
        dotfiles_include \
        dotfiles_command_exists \
        dotfiles_path_prepend \
        dotfiles_path_append \
        dotfiles_expand_home \
        dotfiles_source_dir \
        dotfiles_unload_helpers 2>/dev/null || true
}
