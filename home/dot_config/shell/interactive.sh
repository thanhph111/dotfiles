#!/bin/sh

# Shared interactive shell loader.
#
# Entry files such as ~/.bashrc and ~/.zshrc should stay tiny and call this
# file with the shell name.  The loader then runs common modules, shell-specific
# modules, and final hooks in a predictable order.

SHELL_NAME="$1"
shift || true

case "$SHELL_NAME" in
bash | zsh) ;;
*)
    printf '%s\n' "dotfiles: unknown shell '$SHELL_NAME'" >&2
    return 1
    ;;
esac

# Do nothing in non-interactive shells.
case "$-" in
*i*) ;;
*) return 0 ;;
esac

[ -n "$HOME" ] || return 0

DOTFILES_SHELL_ROOT="${DOTFILES_SHELL_ROOT:-${XDG_CONFIG_HOME:-$HOME/.config}/shell}"
[ -r "$DOTFILES_SHELL_ROOT/lib.sh" ] || return 0
# The shell root may come from the tiny entry files, so ShellCheck cannot know
# the final path here.
# shellcheck disable=SC1091
# shellcheck source=dot_config/shell/lib.sh
. "$DOTFILES_SHELL_ROOT/lib.sh"

# Interactive shells still need the login/session environment.  This keeps
# "bash -i" and "zsh -i" useful even when the parent process skipped login files.
# profile.sh reads this while sourced.  ShellCheck cannot see across that
# runtime source boundary.
# shellcheck disable=SC2034
DOTFILES_KEEP_HELPERS=1
dotfiles_include "$DOTFILES_SHELL_ROOT/profile.sh"
unset DOTFILES_KEEP_HELPERS

export SHELL_NAME
export SHELL_CACHE_DIR="$USER_CACHE_DIR/$SHELL_NAME"
export SHELL_MODULE_DIR="$DOTFILES_SHELL_ROOT/$SHELL_NAME.d"
mkdir -p "$SHELL_CACHE_DIR" "$SHELL_MODULE_DIR"

# Common interactive behavior comes first.
dotfiles_source_dir "$DOTFILES_SHELL_ROOT/interactive.d"

# Bash/Zsh details come next: history, completion, key bindings, and terminal
# integrations.  Prompt hooks run after these so they can see final shell state.
dotfiles_source_dir "$SHELL_MODULE_DIR"

# Final hooks are deliberately last.  Prompt engines and direnv both install
# shell hooks, so keeping them at the end avoids hidden ordering bugs.
dotfiles_source_dir "$DOTFILES_SHELL_ROOT/final.d"

# Compatibility for terminal profiles that pass:
#   bash -is eval 'some command'
#   zsh -ils eval 'some command'
#
# Keep this tiny and explicit.  The eval-pair form is intentionally flexible:
# terminals can pass any one-off command without adding a new dotfiles setting.
while [ "${1:-}" = eval ]; do
    shift
    [ "$#" -gt 0 ] || break
    eval "$1"
    shift
done

dotfiles_unload_helpers
unset SHELL_NAME
