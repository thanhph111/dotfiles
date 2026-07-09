#!/bin/sh

# Common interactive tool hooks.
#
# Keep tool activation here when it is shell-aware but not tied to Bash or Zsh
# syntax.  Prompt and direnv hooks are final hooks because they install prompt
# callbacks and should be last.

# mise replaces many one-off language manager hooks.  It is interactive because
# it installs shell functions and shims for the current command line.
if dotfiles_command_exists mise; then
    # --silent hides normal status chatter.  Trust and config errors still show
    # up because they need a user decision before mise can apply project tools.
    dotfiles_mise_activation="$(mise activate --silent "$SHELL_NAME" 2>/dev/null)" &&
        eval "$dotfiles_mise_activation"
    unset dotfiles_mise_activation
fi

# Podman shell completions, when installed.
if dotfiles_command_exists podman; then
    eval "$(podman completion "$SHELL_NAME")"
fi

# Ripgrep reads extra default flags from this file when present.
[ -f "$USER_CONFIG_DIR/ripgrep/config" ] &&
    export RIPGREP_CONFIG_PATH="$USER_CONFIG_DIR/ripgrep/config"

# Prefer bat for paging when available.
dotfiles_command_exists batman && alias man=batman
if dotfiles_command_exists bat; then
    export PAGER=bat
elif dotfiles_command_exists less; then
    export PAGER=less
fi

# kitty helpers shared by Bash and Zsh.
if [ -d "$HOME/Documents/Projects/External/kitty" ]; then
    export KITTY_DEVELOP_FROM="$HOME/Documents/Projects/External/kitty"
fi

if dotfiles_command_exists kitty; then
    alias diff_kitty='kitty +kitten diff'
    alias icat='kitty +kitten icat'
    alias set_kitty_dark='echo "include themes/Multiplex_Dark.conf" > "$USER_CONFIG_DIR/kitty/current-theme.conf"'
    alias set_kitty_light='echo "include themes/Multiplex_Light.conf" > "$USER_CONFIG_DIR/kitty/current-theme.conf"'
    alias ssh_kitty='kitty +kitten ssh'
fi

# OrbStack shell helpers, when installed.
dotfiles_include "$HOME/.orbstack/shell/init.$SHELL_NAME"
