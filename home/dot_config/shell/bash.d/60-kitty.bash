#!/bin/bash

# kitty shell integration for Bash.
#
# Prompt tools also touch PS1, so kitty integration stays shell-specific and
# runs before final prompt setup.

if
    [[ -n "${KITTY_INSTALLATION_DIR:-}" ]] &&
        [[ -r "$KITTY_INSTALLATION_DIR/shell-integration/bash/kitty.bash" ]]
then
    export KITTY_SHELL_INTEGRATION="no-rc no-title"
    # shellcheck disable=SC1091
    . "$KITTY_INSTALLATION_DIR/shell-integration/bash/kitty.bash"
fi
