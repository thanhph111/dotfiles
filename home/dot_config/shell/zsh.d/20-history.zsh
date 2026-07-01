#!/bin/zsh

# Zsh history policy.
#
# DOTFILES_HISTORY controls disk writes:
#   normal  - keep normal shared history
#   private - keep in-session history, do not write to disk
#   off     - disable shell history for this shell

DOTFILES_HISTORY="${DOTFILES_HISTORY:-normal}"
[[ -n "${NO_HISTORY:-}" ]] && DOTFILES_HISTORY=private

case "$DOTFILES_HISTORY" in
normal | private | off) ;;
*)
    print -u2 "dotfiles: unknown DOTFILES_HISTORY='$DOTFILES_HISTORY'; using normal"
    DOTFILES_HISTORY=normal
    ;;
esac

case "$DOTFILES_HISTORY" in
off)
    unset HISTFILE
    HISTSIZE=0
    SAVEHIST=0
    ;;
private)
    unset HISTFILE
    HISTSIZE=2000
    SAVEHIST=0
    ;;
normal)
    HISTFILE="$SHELL_CACHE_DIR/history"
    HISTSIZE=10000
    SAVEHIST=10000
    setopt HIST_EXPIRE_DUPS_FIRST
    setopt HIST_IGNORE_DUPS
    setopt HIST_IGNORE_ALL_DUPS
    setopt HIST_IGNORE_SPACE
    setopt HIST_FIND_NO_DUPS
    setopt HIST_SAVE_NO_DUPS
    setopt EXTENDED_HISTORY
    setopt HIST_VERIFY
    setopt INC_APPEND_HISTORY
    ;;
esac
