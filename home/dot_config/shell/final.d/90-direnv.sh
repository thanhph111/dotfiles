#!/bin/sh

# direnv should be hooked late so it can see the final shell state.
dotfiles_command_exists direnv && eval "$(direnv hook "$SHELL_NAME")"
