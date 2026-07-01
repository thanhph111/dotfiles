#!/bin/sh

# Prompt setup.
#
# Oh My Posh owns prompt rendering.  This loader only chooses which config to
# pass to it.  External tools can set OMP_CONFIG directly; POSH_THEME is kept as
# a compatibility alias for older/editor configs.

[ "${TERM_PROGRAM:-}" = Apple_Terminal ] && return 0

if dotfiles_command_exists oh-my-posh; then
    omp_config="${OMP_CONFIG:-${POSH_THEME:-}}"
    if [ -z "$omp_config" ]; then
        omp_config="$USER_CONFIG_DIR/oh-my-posh/probua.minimal.omp.json"
    fi

    omp_config="$(dotfiles_expand_home "$omp_config")"
    export OMP_CONFIG="$omp_config"

    # Use --print instead of the default cached init script.  The cache embeds
    # the exact Homebrew Cellar path, so a brew upgrade can leave new shells
    # calling a deleted oh-my-posh binary until the cache is rebuilt.
    eval "$(oh-my-posh init "$SHELL_NAME" --config "$omp_config" --print)"
elif dotfiles_command_exists starship; then
    export STARSHIP_CONFIG="$USER_CONFIG_DIR/starship/multiplex.toml"
    eval "$(starship init "$SHELL_NAME")"
elif [ "$SHELL_NAME" = zsh ]; then
    PS1='%n@%m:%~%# '
else
    [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ] &&
        debian_chroot=$(cat /etc/debian_chroot)
    PS1="${debian_chroot:+($debian_chroot)}\u@\h:\w\$ "
fi

unset omp_config
