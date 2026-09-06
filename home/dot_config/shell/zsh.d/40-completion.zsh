#!/bin/zsh

# Zsh completion.

# "menu select" uses Zsh's menu-selection module.  Loading it explicitly keeps
# completion behavior stable across systems where the module is not autoloaded.
zmodload -i zsh/complist

# Completion functions are found through fpath.  Keep local completions first so
# this repo can override vendor completions, then add package-manager completions.
# Zsh ties fpath and FPATH together, so working with the array keeps the code
# easier to read than editing the colon-separated FPATH string by hand.
# This file is sourced through a loader function, so mark fpath globally unique.
typeset -gaU fpath

[[ -d "$SHELL_MODULE_DIR/completions" ]] &&
    fpath=("$SHELL_MODULE_DIR/completions" "${fpath[@]}")

if [[ -n "${HOMEBREW_PREFIX:-}" ]]; then
    [[ -d "$HOMEBREW_PREFIX/share/zsh/site-functions" ]] &&
        fpath=("$HOMEBREW_PREFIX/share/zsh/site-functions" "${fpath[@]}")
fi

# Completion matching is staged from strict to flexible:
# 1. exact prefix match,
# 2. case-insensitive match,
# 3. case-insensitive partial-word match around common separators.
zstyle ':completion:*' matcher-list \
    '' \
    'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' \
    'm:{[:lower:][:upper:]}={[:upper:][:lower:]} r:|[._-]=* r:|=*'

zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$SHELL_CACHE_DIR/completions"
zstyle ':completion:*' accept-exact-dirs true
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*' list-suffixes true
zstyle ':completion:*' expand prefix suffix
zstyle ':completion:*' menu select
zstyle ':completion:*' group-name ''
zstyle ':completion:*' verbose true
zstyle ':completion:*:*:git:*' tag-order common-commands alias-commands

[[ -n "${LS_COLORS:-}" ]] &&
    zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

setopt nolistambiguous
setopt autolist
setopt automenu
unsetopt menucomplete
setopt globdots
setopt globstarshort

autoload -U colors && colors
autoload -Uz compinit
# `compinit -C` skips some checks, so only use it while the dump file is fresh.
# A normal run below refreshes stale or missing completion state.
if zmodload -F zsh/stat b:zstat 2>/dev/null &&
    zmodload zsh/datetime 2>/dev/null &&
    [[ -r "$SHELL_CACHE_DIR/completion" ]] &&
    ((EPOCHSECONDS - $(zstat +mtime "$SHELL_CACHE_DIR/completion") < 86400)); then
    compinit -C -d "$SHELL_CACHE_DIR/completion"
else
    compinit -d "$SHELL_CACHE_DIR/completion"
fi

# Commands whose shebang runs `usage` carry their own spec, and one fallback
# handler completes all of them.  It must come after compinit, which is what
# installs the completion system this hooks into.
if dotfiles_command_exists usage; then
    dotfiles_usage_completion="$(usage generate completion-init zsh 2>/dev/null)" &&
        eval "$dotfiles_usage_completion"
    unset dotfiles_usage_completion
fi
