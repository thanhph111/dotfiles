#!/bin/bash

# Bash history policy.
#
# DOTFILES_HISTORY controls disk writes:
#   normal  - keep history and let Bash append it when the shell exits
#   private - keep in-session history, do not write to disk
#   off     - disable Bash history for this shell
#
# NO_HISTORY remains supported as an older name for private mode.

DOTFILES_HISTORY="${DOTFILES_HISTORY:-normal}"
[ -n "${NO_HISTORY:-}" ] && DOTFILES_HISTORY=private

case "$DOTFILES_HISTORY" in
normal | private | off) ;;
*)
    printf '%s\n' "dotfiles: unknown DOTFILES_HISTORY='$DOTFILES_HISTORY'; using normal" >&2
    DOTFILES_HISTORY=normal
    ;;
esac

remove_history() {
    local history_file="${HISTFILE:-$SHELL_CACHE_DIR/history}"
    sed -n -e :a -e "1,${1:-1}!{P;N;D;};N;ba" -i "$history_file"
}

case "$DOTFILES_HISTORY" in
off)
    set +o history
    unset HISTFILE
    ;;
private)
    HISTSIZE=2000
    unset HISTFILE
    ;;
normal)
    mkdir -p "$SHELL_CACHE_DIR"
    HISTFILE="$SHELL_CACHE_DIR/history"
    HISTFILESIZE=10000
    HISTSIZE=10000

    shopt -s histappend
    shopt -s cmdhist
    shopt -s lithist 2>/dev/null || true
    shopt -s extglob
    HISTCONTROL=ignoreboth:erasedups
    HISTIGNORE="${HISTIGNORE:+$HISTIGNORE:}\
.( /)*:\
+( )*:\
[bf]g+( ):\
&:\
bash+( )+([^ ])*( ):\
cd+( )+([^ ])*( ):\
clear+( ):\
code+( )+([^ ])*( ):\
exit+( ):\
hash+( )+([^ ])*( ):\
history+( )+([^ ])*( ):\
pwd+( ):\
printf+( )+([^ ])*( ):\
rm+( )+([^ ])*( ):\
remove_history*( )*:\
tree+( )+([^ ])*( ):\
type+( )+([^ ])*( ):\
which+( )+([^ ])*( )"

    export HISTFILE HISTFILESIZE HISTSIZE HISTCONTROL HISTIGNORE
    ;;
esac
