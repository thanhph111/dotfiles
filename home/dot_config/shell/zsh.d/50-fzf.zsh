#!/bin/zsh

# Zsh fzf integration.
#
# Shared fzf behavior lives in interactive.d/40-fzf.sh. This file only owns the
# Zsh integration script and ZLE widgets.
#
# Keep picker behavior in the shared file. This file should only load fzf and
# map Zsh keys to shared functions.

command -v fzf >/dev/null 2>&1 || return 0
[[ -t 0 && -t 1 ]] || return 0

if fzf --zsh >/dev/null 2>&1; then
    source <(fzf --zsh)
elif [[ -n "${FZF_REPO_DIR:-}" ]]; then
    [[ $- == *i* ]] && source "$FZF_REPO_DIR/shell/completion.zsh" 2>/dev/null
    source "$FZF_REPO_DIR/shell/key-bindings.zsh" 2>/dev/null
fi

# fzf's generated Zsh script owns CTRL-T, ALT-C, and CTRL-R.
#
# CTRL-O keeps non-Git actions in one place. Press CTRL-O, then a plain key:
# f edits a file
# r searches text with ripgrep
# w opens a VS Code workspace
# p selects processes to kill
# b inserts a command from PATH
# ? shows these keys
#
# CTRL-G keeps Git object insertion in one place. Press CTRL-G, then:
# f for files
# b for branches
# t for tags
# r for remotes
# h for commit hashes
# s for stashes
# ? shows Git keys

_fzf_run_widget() {
    case "$WIDGET" in
    fzf-edit-file-widget) fzf_edit_file ;;
    fzf-search-text-widget) fzf_search_text ;;
    fzf-open-code-workspace-widget) fzf_open_code_workspace ;;
    fzf-kill-process-widget) fzf_kill_process ;;
    *) return 1 ;;
    esac

    zle reset-prompt
}

_fzf_show_keymap_widget() {
    case "$WIDGET" in
    fzf-actions-help-widget) fzf_show_keymap actions ;;
    fzf-git-help-widget) fzf_show_keymap git ;;
    *) return 1 ;;
    esac

    zle reset-prompt
}

_fzf_insert_path_executable_widget() {
    local result

    result="$(fzf_select_path_executable | _fzf_quote)"

    zle reset-prompt
    LBUFFER+="$result"
}

_fzf_git_widget() {
    local result

    case "$WIDGET" in
    fzf-gf-widget) result="$(fzf_select_git_changed_files | _fzf_quote)" ;;
    fzf-gb-widget) result="$(fzf_select_git_branches | _fzf_quote)" ;;
    fzf-gt-widget) result="$(fzf_select_git_tags | _fzf_quote)" ;;
    fzf-gr-widget) result="$(fzf_select_git_remotes | _fzf_quote)" ;;
    fzf-gh-widget) result="$(fzf_select_git_commit_hashes | _fzf_quote)" ;;
    fzf-gs-widget) result="$(fzf_select_git_stashes | _fzf_quote)" ;;
    *) return 1 ;;
    esac

    zle reset-prompt
    LBUFFER+="$result"
}

zle -N fzf-edit-file-widget _fzf_run_widget
zle -N fzf-search-text-widget _fzf_run_widget
zle -N fzf-open-code-workspace-widget _fzf_run_widget
zle -N fzf-kill-process-widget _fzf_run_widget
zle -N fzf-actions-help-widget _fzf_show_keymap_widget
zle -N fzf-insert-path-executable-widget _fzf_insert_path_executable_widget

zle -N fzf-gf-widget _fzf_git_widget
zle -N fzf-gb-widget _fzf_git_widget
zle -N fzf-gt-widget _fzf_git_widget
zle -N fzf-gr-widget _fzf_git_widget
zle -N fzf-gh-widget _fzf_git_widget
zle -N fzf-gs-widget _fzf_git_widget
zle -N fzf-git-help-widget _fzf_show_keymap_widget

bindkey -r '^O'
bindkey -r '^G'

bindkey '^of' fzf-edit-file-widget
bindkey '^or' fzf-search-text-widget
bindkey '^ow' fzf-open-code-workspace-widget
bindkey '^op' fzf-kill-process-widget
bindkey '^ob' fzf-insert-path-executable-widget
bindkey '^o?' fzf-actions-help-widget

bindkey '^gf' fzf-gf-widget
bindkey '^gb' fzf-gb-widget
bindkey '^gt' fzf-gt-widget
bindkey '^gr' fzf-gr-widget
bindkey '^gh' fzf-gh-widget
bindkey '^gs' fzf-gs-widget
bindkey '^g?' fzf-git-help-widget
