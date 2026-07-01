#!/bin/sh

# Login/session environment.
#
# This file is safe to source from POSIX sh, Bash, or Zsh.  It should not set
# prompts, key bindings, shell options, aliases, or completions.  Those need an
# interactive shell and live in interactive.sh and the interactive modules.

[ -n "$HOME" ] || return 0

# If a child shell inherits this flag, it also inherited the environment this
# file created.  A clean shell started with env -i will not have the flag and
# will rebuild the environment.
[ "${DOTFILES_PROFILE_LOADED:-}" = 1 ] && return 0

DOTFILES_SHELL_ROOT="${DOTFILES_SHELL_ROOT:-${XDG_CONFIG_HOME:-$HOME/.config}/shell}"
[ -r "$DOTFILES_SHELL_ROOT/lib.sh" ] || return 0
# The shell root may come from the tiny entry files, so ShellCheck cannot know
# the final path here.
# shellcheck disable=SC1091
# shellcheck source=dot_config/shell/lib.sh
. "$DOTFILES_SHELL_ROOT/lib.sh"

export DOTFILES_PROFILE_LOADED=1

# XDG base directories are the roots used by most modules below.
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"

# Short aliases used by the shell modules.  They stay exported because child
# shells and editor terminals are expected to reuse the same roots.
export USER_CONFIG_DIR="$XDG_CONFIG_HOME"
export USER_CACHE_DIR="$XDG_CACHE_HOME"
export DOTFILES_SHELL_ROOT

dotfiles_source_dir "$DOTFILES_SHELL_ROOT/profile.d"

export PATH

[ "${DOTFILES_KEEP_HELPERS:-}" = 1 ] || dotfiles_unload_helpers
