#!/bin/zsh

# kitty shell integration for Zsh.

if [[ -n "${KITTY_INSTALLATION_DIR:-}" ]] &&
    [[ -r "$KITTY_INSTALLATION_DIR/shell-integration/zsh/kitty-integration" ]]; then
    export KITTY_SHELL_INTEGRATION="no-rc no-title"
    autoload -Uz -- "$KITTY_INSTALLATION_DIR"/shell-integration/zsh/kitty-integration
    kitty-integration
    unfunction kitty-integration
fi
