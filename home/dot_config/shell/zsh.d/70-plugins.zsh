#!/bin/zsh

# Lightweight Zsh plugins from Homebrew.
#
# Keep syntax highlighting near the end of Zsh-specific setup.  It hooks into
# line editing and is easier to reason about when key bindings already exist.

if dotfiles_command_exists brew; then
    HOMEBREW_PREFIX="${HOMEBREW_PREFIX:-$(brew --prefix)}"
    dotfiles_include "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
    dotfiles_include "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi
