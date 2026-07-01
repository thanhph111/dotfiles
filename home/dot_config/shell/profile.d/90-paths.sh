#!/bin/sh

# Final executable search paths.
#
# Put broad user paths near the end of profile setup so they win over system
# tools while still allowing earlier modules to add their own tool roots.

# JetBrains Toolbox scripts on macOS.
toolbox_scripts="$HOME/Library/Application Support/JetBrains/Toolbox/scripts"
dotfiles_path_prepend "$toolbox_scripts"
unset toolbox_scripts

# Antigravity.
dotfiles_path_prepend "$HOME/.antigravity/bin"

# Obsidian CLI helper on macOS.
dotfiles_path_append "/Applications/Obsidian.app/Contents/MacOS"

# User scripts should be first in normal command lookup.
dotfiles_path_prepend "$HOME/.local/bin"
