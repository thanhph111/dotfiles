#!/bin/bash

# Shared fzf setup and picker functions.
#
# Bash and Zsh bind keys differently, but the picker behavior should be the
# same in both shells.
#
# Rule:
# - This file owns picker behavior: fzf defaults, source commands, previews,
#   and public commands named fzf_<verb>_<object>.
# - Selector commands print the selected thing. Bash and Zsh decide how to
#   insert that selection into the active command line.
# - Bash and Zsh files only load shell integration and map keys.
# - Public helper commands in ~/.local/bin own work useful outside fzf.
# - Private fzf helper executables live in ~/.local/libexec.

[ -z "${FZF_CONFIG_READY:-}" ] || return 0
export FZF_CONFIG_READY=1

if ! dotfiles_command_exists fzf; then
    if [ -z "${FZF_REPO_DIR:-}" ] && dotfiles_command_exists brew; then
        FZF_REPO_DIR="$(brew --prefix fzf 2>/dev/null || true)"
        export FZF_REPO_DIR
    fi
    [ -n "${FZF_REPO_DIR:-}" ] && dotfiles_path_append "$FZF_REPO_DIR/bin"
fi

dotfiles_command_exists fzf || return 0

if [ -z "${FZF_PREVIEW_COMMAND:-}" ] || [ "$FZF_PREVIEW_COMMAND" = fzf-preview ]; then
    FZF_PREVIEW_COMMAND="$HOME/.local/libexec/fzf-preview"
fi
export FZF_PREVIEW_COMMAND

if [ -z "${FZF_COLORS:-}" ]; then
    FZF_COLORS='--color=16,'
    FZF_COLORS+='fg:-1,'
    FZF_COLORS+='fg+:6:bold,'
    FZF_COLORS+='bg:-1,'
    FZF_COLORS+='bg+:-1,'
    FZF_COLORS+='hl:6:bold,'
    FZF_COLORS+='hl+:14:bold,'
    FZF_COLORS+='info:8,'
    FZF_COLORS+='prompt:6:bold,'
    FZF_COLORS+='pointer:6:bold,'
    FZF_COLORS+='marker:2:bold,'
    FZF_COLORS+='spinner:6,'
    FZF_COLORS+='gutter:-1,'
    FZF_COLORS+='preview-fg:-1,'
    FZF_COLORS+='preview-bg:-1,'
    FZF_COLORS+='preview-border:8,'
    FZF_COLORS+='query:-1:bold,'
    FZF_COLORS+='ghost:8,'
    FZF_COLORS+='disabled:8,'
    FZF_COLORS+='border:8,'
    FZF_COLORS+='label:6,'
    FZF_COLORS+='input-border:6,'
    FZF_COLORS+='input-label:6:bold,'
    FZF_COLORS+='list-border:8,'
    FZF_COLORS+='list-label:8,'
    FZF_COLORS+='footer-border:8,'
    FZF_COLORS+='header:8,'
    FZF_COLORS+='footer:8'
fi
export FZF_COLORS

_fzf_user_default_opts="${FZF_DEFAULT_OPTS:-}"
_fzf_user_ctrl_t_opts="${FZF_CTRL_T_OPTS:-}"
_fzf_user_alt_c_opts="${FZF_ALT_C_OPTS:-}"
_fzf_user_ctrl_r_opts="${FZF_CTRL_R_OPTS:-}"
_fzf_user_completion_path_opts="${FZF_COMPLETION_PATH_OPTS:-}"
_fzf_user_completion_dir_opts="${FZF_COMPLETION_DIR_OPTS:-}"

# fzf parses these option strings later; the embedded quotes are intentional.
# shellcheck disable=SC2089
FZF_DEFAULT_OPTS='--style=full'
FZF_DEFAULT_OPTS+=' --info=inline-right'
FZF_DEFAULT_OPTS+=' --border=none'
FZF_DEFAULT_OPTS+=" --list-label=' Results '"
FZF_DEFAULT_OPTS+=' --multi'
FZF_DEFAULT_OPTS+=' --walker-skip=.git,node_modules,target,.venv,__pycache__'
FZF_DEFAULT_OPTS+=' --cycle'
FZF_DEFAULT_OPTS+=' --layout=reverse'
FZF_DEFAULT_OPTS+=' --margin=0'
FZF_DEFAULT_OPTS+=' --padding=0'
FZF_DEFAULT_OPTS+=' --scroll-off=3'
FZF_DEFAULT_OPTS+=' --no-scrollbar'
FZF_DEFAULT_OPTS+=" --gutter=' '"
FZF_DEFAULT_OPTS+=" --pointer='> '"
FZF_DEFAULT_OPTS+=" --marker='* '"
FZF_DEFAULT_OPTS+=' --height=80%'
FZF_DEFAULT_OPTS+=' --highlight-line'
FZF_DEFAULT_OPTS+=" --input-label=' Query '"
FZF_DEFAULT_OPTS+=" --ghost='Type to filter'"
FZF_DEFAULT_OPTS+=" --footer='Ctrl-Y copy | Alt-Y copy path'"
FZF_DEFAULT_OPTS+=' --footer-border=none'
FZF_DEFAULT_OPTS+=" --bind='change:first'"
FZF_DEFAULT_OPTS+=" --bind='ctrl-t:toggle-all'"
FZF_DEFAULT_OPTS+=" --bind='home:first'"
FZF_DEFAULT_OPTS+=" --bind='end:last'"
FZF_DEFAULT_OPTS+=" --bind='ctrl-y:execute-silent(cat {+f} | clipcopy)'"
FZF_DEFAULT_OPTS+=" --bind='alt-y:execute-silent("
FZF_DEFAULT_OPTS+="while IFS= read -r item; do "
FZF_DEFAULT_OPTS+="realpath -- \"\$item\" 2>/dev/null || "
FZF_DEFAULT_OPTS+="readlink -f -- \"\$item\" 2>/dev/null || "
FZF_DEFAULT_OPTS+="printf '%s\n' \"\$item\"; "
FZF_DEFAULT_OPTS+='done < {+f} | clipcopy'
FZF_DEFAULT_OPTS+=")'"
FZF_DEFAULT_OPTS+=" $FZF_COLORS"
FZF_DEFAULT_OPTS+=" $_fzf_user_default_opts"
# shellcheck disable=SC2090
export FZF_DEFAULT_OPTS

# shellcheck disable=SC2089
FZF_CTRL_T_OPTS='--scheme=path'
FZF_CTRL_T_OPTS+=" --input-label=' Path query '"
FZF_CTRL_T_OPTS+=" --list-label=' Files '"
FZF_CTRL_T_OPTS+=" --preview='$FZF_PREVIEW_COMMAND {}'"
FZF_CTRL_T_OPTS+=" --preview-label=' Path preview '"
FZF_CTRL_T_OPTS+=" --preview-window='right,60%,border-left,<90(down,50%,border-top)'"
FZF_CTRL_T_OPTS+=" --footer='Enter insert | Tab mark | Ctrl-/ preview | Ctrl-Y copy'"
FZF_CTRL_T_OPTS+=" --bind='ctrl-/:change-preview-window("
FZF_CTRL_T_OPTS+='right,60%,border-left|down,50%,border-top|hidden'
FZF_CTRL_T_OPTS+=")'"
FZF_CTRL_T_OPTS+=" $_fzf_user_ctrl_t_opts"
# shellcheck disable=SC2089
FZF_ALT_C_OPTS='--scheme=path'
FZF_ALT_C_OPTS+=" --input-label=' Directory query '"
FZF_ALT_C_OPTS+=" --list-label=' Directories '"
FZF_ALT_C_OPTS+=" --preview='$FZF_PREVIEW_COMMAND {}'"
FZF_ALT_C_OPTS+=" --preview-label=' Directory preview '"
FZF_ALT_C_OPTS+=" --preview-window='right,60%,border-left,<90(down,50%,border-top)'"
FZF_ALT_C_OPTS+=" --footer='Enter cd | Ctrl-/ preview | Ctrl-Y copy | Alt-Y path'"
FZF_ALT_C_OPTS+=" --bind='ctrl-/:change-preview-window("
FZF_ALT_C_OPTS+='right,60%,border-left|down,50%,border-top|hidden'
FZF_ALT_C_OPTS+=")'"
FZF_ALT_C_OPTS+=" $_fzf_user_alt_c_opts"
# shellcheck disable=SC2089
FZF_CTRL_R_OPTS='--scheme=history'
FZF_CTRL_R_OPTS+=' --height=75%'
FZF_CTRL_R_OPTS+=' --min-height=14'
FZF_CTRL_R_OPTS+=' --border=none'
FZF_CTRL_R_OPTS+=" --input-label=' Search history '"
FZF_CTRL_R_OPTS+=" --list-label=' Commands '"
FZF_CTRL_R_OPTS+=" --preview='echo {}'"
FZF_CTRL_R_OPTS+=" --preview-label=' Command '"
FZF_CTRL_R_OPTS+=' --preview-window=down:3:hidden:wrap'
FZF_CTRL_R_OPTS+=" --bind='ctrl-/:toggle-preview'"
FZF_CTRL_R_OPTS+=" --footer='Enter use | Ctrl-R sort | Alt-R raw | Ctrl-/ preview'"
FZF_CTRL_R_OPTS+=" $_fzf_user_ctrl_r_opts"
# shellcheck disable=SC2090
export FZF_CTRL_T_OPTS FZF_ALT_C_OPTS FZF_CTRL_R_OPTS

FZF_COMPLETION_PATH_OPTS='--walker=file,dir,follow,hidden'
FZF_COMPLETION_PATH_OPTS+=' --walker-skip=.git,node_modules,target,.venv,__pycache__'
FZF_COMPLETION_PATH_OPTS+=" $_fzf_user_completion_path_opts"
FZF_COMPLETION_DIR_OPTS='--walker=dir,follow,hidden'
FZF_COMPLETION_DIR_OPTS+=' --walker-skip=.git,node_modules,target,.venv,__pycache__'
FZF_COMPLETION_DIR_OPTS+=" $_fzf_user_completion_dir_opts"
export FZF_COMPLETION_PATH_OPTS FZF_COMPLETION_DIR_OPTS

unset _fzf_user_default_opts
unset _fzf_user_ctrl_t_opts
unset _fzf_user_alt_c_opts
unset _fzf_user_ctrl_r_opts
unset _fzf_user_completion_path_opts
unset _fzf_user_completion_dir_opts

# Shared fzf helpers live here so Bash and Zsh key bindings can use the same
# behavior.

_fzf_comprun() {
    local command_name process_preview

    command_name="$1"
    shift

    case "$command_name" in
    cd | pushd | rmdir)
        fzf --preview "$FZF_PREVIEW_COMMAND {}" \
            --preview-label ' Directory preview ' \
            "$@"
        ;;
    kill)
        process_preview='ps -p {1} -o pid,ppid,user,stat,%cpu,%mem,etime,command'
        process_preview+=' 2>/dev/null || echo {}'

        fzf --preview "$process_preview" \
            --preview-label ' Process details ' \
            --preview-window down,4,border-top,wrap \
            "$@"
        ;;
    *)
        fzf --preview "$FZF_PREVIEW_COMMAND {}" \
            --preview-label ' Path preview ' \
            "$@"
        ;;
    esac
}

_fzf_in_git_repo() {
    git rev-parse --is-inside-work-tree >/dev/null 2>&1
}

_fzf_down() {
    fzf --height 50% --min-height 20 --border=none \
        --bind 'ctrl-/:toggle-preview' "$@"
}

_fzf_quote() {
    local item
    while IFS= read -r item; do
        printf '%q ' "$item"
    done
}

fzf_select_git_changed_files() {
    local preview

    _fzf_in_git_repo || return
    preview="git diff --color=always -- {-1} | sed 1,4d; "
    preview+="\"$FZF_PREVIEW_COMMAND\" {-1}"

    git -c color.status=always status --short |
        _fzf_down -m --ansi --nth 2..,.. \
            --input-label ' File query ' \
            --list-label ' Git files ' \
            --preview "$preview" \
            --preview-label ' Diff / file ' \
            --preview-window 'wrap' \
            --footer 'Enter insert paths | Tab mark | Ctrl-/ preview' |
        cut -c4- | sed 's/.* -> //'
}

fzf_select_git_branches() {
    _fzf_in_git_repo || return
    # shellcheck disable=SC2016
    git branch -a --color=always | grep -v '/HEAD\s' | sort |
        _fzf_down --ansi --multi --tac \
            --preview-window 'right,65%,border-left,<90(down,50%,border-top)' \
            --input-label ' Branch query ' \
            --list-label ' Git branches ' \
            --preview-label ' Recent commits ' \
            --footer 'Enter insert branches | Tab mark | Ctrl-/ preview' \
            --preview "$(
                printf '%s ' \
                    'git log' \
                    '--oneline' \
                    '--graph' \
                    '--date=short' \
                    '--color=always' \
                    '--pretty="format:%C(auto)%cd %h%d %s"' \
                    '$(printf "%s" {} | sed "s/^..//" | cut -d " " -f1)'
            )" |
        sed 's/^..//' | cut -d' ' -f1 |
        sed 's#^remotes/##'
}

fzf_select_git_tags() {
    _fzf_in_git_repo || return
    git tag --sort -version:refname |
        _fzf_down --multi \
            --preview-window 'right,65%,border-left,<90(down,50%,border-top)' \
            --input-label ' Tag query ' \
            --list-label ' Git tags ' \
            --preview-label ' Tag details ' \
            --footer 'Enter insert tags | Tab mark | Ctrl-/ preview' \
            --preview 'git show --color=always {}'
}

fzf_select_git_commit_hashes() {
    _fzf_in_git_repo || return
    # shellcheck disable=SC2016
    git log \
        --date=short \
        --format="%C(green)%C(bold)%cd %C(auto)%h%d %s (%an)" \
        --graph \
        --color=always |
        _fzf_down --ansi --no-sort --reverse --multi --bind 'ctrl-s:toggle-sort' \
            --input-label ' Commit query ' \
            --list-label ' Git commits ' \
            --preview-label ' Commit details ' \
            --footer 'Enter insert hashes | Tab mark | Ctrl-S sort | Ctrl-/ preview' \
            --preview "$(
                printf '%s ' \
                    'git show --color=always' \
                    '$(printf "%s" {} | grep -o "[a-f0-9]\{7,\}" | head -1)'
            )" |
        grep -o "[a-f0-9]\{7,\}"
}

fzf_select_git_remotes() {
    _fzf_in_git_repo || return
    git remote -v | awk '{print $1 "\t" $2}' | uniq |
        _fzf_down --tac \
            --input-label ' Remote query ' \
            --list-label ' Git remotes ' \
            --preview-label ' Remote commits ' \
            --footer 'Enter insert remote | Ctrl-/ preview' \
            --preview "$(
                printf '%s ' \
                    'git log' \
                    '--oneline' \
                    '--graph' \
                    '--date=short' \
                    '--pretty="format:%C(auto)%cd %h%d %s"' \
                    '{1}'
            )" |
        cut -d$'\t' -f1
}

fzf_select_git_stashes() {
    _fzf_in_git_repo || return
    git stash list |
        _fzf_down --reverse -d: \
            --input-label ' Stash query ' \
            --list-label ' Git stashes ' \
            --preview-label ' Stash details ' \
            --footer 'Enter insert stash | Ctrl-/ preview' \
            --preview 'git show --color=always {1}' |
        cut -d: -f1
}

_fzf_keymap_rows() {
    case "${1:-all}" in
    actions)
        printf '%s\n' \
            'Ctrl-T|Files|Insert one or more paths into the command line.' \
            'Alt-C|Directories|Change to a directory.' \
            'Ctrl-R|History|Search shell history and put the command on the prompt.' \
            'Ctrl-O f|Edit file|Pick one file and open it in your editor.' \
            'Ctrl-O r|Text search|Search file contents with ripgrep, then open the match.' \
            'Ctrl-O w|VS Code workspace|Open a recent VS Code workspace.' \
            'Ctrl-O p|Processes|Pick processes and send TERM.' \
            'Ctrl-O b|PATH command|Pick an executable from PATH and insert its name.' \
            'Ctrl-O ?|This help|Show the non-Git fzf keys.'
        ;;
    git)
        printf '%s\n' \
            'Ctrl-G f|Git files|Insert changed file paths.' \
            'Ctrl-G b|Git branches|Insert local or remote branch names.' \
            'Ctrl-G t|Git tags|Insert tag names.' \
            'Ctrl-G r|Git remotes|Insert remote names.' \
            'Ctrl-G h|Git commits|Insert commit hashes.' \
            'Ctrl-G s|Git stashes|Insert stash names.' \
            'Ctrl-G ?|This help|Show the Git fzf keys.'
        ;;
    *)
        _fzf_keymap_rows actions
        _fzf_keymap_rows git
        ;;
    esac
}

# These picker commands are deliberately callable from the prompt. Public names
# start with fzf_. The Bash and Zsh files only add key bindings to them.

fzf_show_keymap() {
    local group label

    group="${1:-all}"
    case "$group" in
    actions) label=' FZF keys ' ;;
    git) label=' Git fzf keys ' ;;
    *) label=' FZF keys ' ;;
    esac

    _fzf_keymap_rows "$group" |
        awk -F'|' '{ printf "%-15s  %-18s  %s\n", $1, $2, $3 }' |
        fzf +m --no-sort \
            --input-label ' Key query ' \
            --list-label "$label" \
            --footer 'Enter close | Type to filter' >/dev/null
}

fzf_open_code_workspace() {
    local config_path folder folder_uri workspace

    command -v code >/dev/null 2>&1 || return 1
    command -v jq >/dev/null 2>&1 || return 1

    workspace=$(
        for config_path in \
            "$HOME/Library/Application Support/Code" \
            "$HOME/.config/Code"; do
            [ -d "$config_path/User/workspaceStorage" ] || continue
            find "$config_path/User/workspaceStorage/" \
                -type f \
                -name 'workspace.json' \
                -exec cat {} \;
        done |
            jq -r '.folder // empty' |
            while IFS= read -r folder_uri; do
                [ -n "$folder_uri" ] || continue
                folder="${folder_uri#file://}"
                [ -d "$folder" ] && printf '%s\n' "$folder"
            done |
            fzf +m --keep-right \
                --input-label ' Workspace query ' \
                --list-label ' VS Code workspaces ' \
                --preview "$FZF_PREVIEW_COMMAND {}" \
                --preview-label ' Workspace files ' \
                --preview-window 'right,60%,border-left,<90(down,50%,border-top)' \
                --footer 'Enter open workspace'
    )
    [ -n "$workspace" ] && code --new-window "$workspace"
}

fzf_edit_file() {
    local editor selected

    editor="${VISUAL:-${EDITOR:-vim}}"
    selected=$(
        fzf +m --scheme=path \
            --walker=file,follow,hidden \
            --walker-skip=.git,node_modules,target,.venv,__pycache__ \
            --input-label ' File query ' \
            --list-label ' Edit file ' \
            --preview "$FZF_PREVIEW_COMMAND {}" \
            --preview-label ' File preview ' \
            --preview-window 'right,60%,border-left,<90(down,50%,border-top)' \
            --footer 'Enter edit | Ctrl-Y copy | Alt-Y path'
    )
    [ -n "$selected" ] && "$editor" "$selected"
}

fzf_search_text() {
    local editor initial_query line rest rg_prefix selected

    command -v rg >/dev/null 2>&1 || return 1

    editor="${VISUAL:-${EDITOR:-vim}}"
    initial_query="${*:-}"
    rg_prefix='rg --column --line-number --no-heading --color=always --smart-case'
    rg_prefix+=' --hidden --glob "!.git/*" --glob "!node_modules/*"'
    rg_prefix+=' --glob "!target/*" --glob "!.venv/*"'
    rg_prefix+=' --glob "!__pycache__/*"'

    selected=$(
        : |
            fzf +m --ansi --disabled --query "$initial_query" \
                --input-label ' Ripgrep query ' \
                --list-label ' Text search ' \
                --bind "start:reload:$rg_prefix {q} || true" \
                --bind "change:reload:sleep 0.1; $rg_prefix {q} || true" \
                --bind "$(
                    printf '%s' \
                        'alt-enter:unbind(change,alt-enter)' \
                        '+change-prompt(2. FZF> )' \
                        '+enable-search' \
                        '+clear-query'
                )" \
                --bind "$(
                    printf '%s' \
                        'ctrl-/:change-preview-window(' \
                        'up,60%,border-bottom,+{2}+3/3,~3|' \
                        'down,50%,border-top,+{2}+3/3,~3|' \
                        'hidden)'
                )" \
                --prompt '1. Ripgrep> ' \
                --delimiter : \
                --preview "$FZF_PREVIEW_COMMAND --line {2} {1}" \
                --preview-label ' Match preview ' \
                --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' \
                --footer 'Enter edit match | Alt-Enter filter results | Ctrl-/ preview'
    )

    [ -n "$selected" ] || return 0
    rest="${selected#*:}"
    line="${rest%%:*}"
    "$editor" "${selected%%:*}" "+$line"
}

fzf_select_path_executable() {
    local command_preview loc selected

    command_preview='file -b -- {2}; echo; '
    command_preview+='whatis {1} 2>/dev/null || true; echo; ls -l {2}'

    selected=$(
        printf '%s\n' "$PATH" | tr ':' '\n' |
            awk 'NF && !seen[$0]++' |
            while IFS= read -r loc; do
                [ -d "$loc" ] || continue
                find "$loc" -maxdepth 1 -type f -perm -111 -print 2>/dev/null
            done |
            awk -F/ '!seen[$NF]++ { print $NF "\t" $0 }' |
            sort |
            fzf +m \
                --delimiter=$'\t' \
                --with-nth=1 \
                --nth=1,2 \
                --input-label ' Command query ' \
                --list-label ' PATH commands ' \
                --preview "$command_preview" \
                --preview-label ' Command details ' \
                --preview-window down,6,border-top,wrap \
                --bind 'ctrl-y:execute-silent(printf "%s\n" {1} | clipcopy)' \
                --bind 'alt-y:execute-silent(printf "%s\n" {2} | clipcopy)' \
                --footer 'Enter insert command | Ctrl-Y copy | Alt-Y path'
    )
    [ -n "$selected" ] && printf '%s\n' "${selected%%$'\t'*}"
}

fzf_kill_process() {
    local pid process_preview selected_pids signal

    signal="${1:-TERM}"
    process_preview='ps -p {2} -o pid,ppid,user,stat,%cpu,%mem,etime,command'
    process_preview+=' 2>/dev/null || echo {}'

    while :; do
        selected_pids=$(
            ps -ef |
                fzf --multi \
                    --header-lines=1 \
                    --track \
                    --id-nth=2 \
                    --input-label ' Process query ' \
                    --list-label " Processes (kill -$signal) " \
                    --bind 'start,every(2):reload-sync:ps -ef' \
                    --bind 'ctrl-r:reload-sync:ps -ef' \
                    --preview "$process_preview" \
                    --preview-label ' Process details ' \
                    --preview-window down,4,border-top,wrap \
                    --footer "Enter send -$signal | Tab mark | Ctrl-R reload" |
                awk '{print $2}'
        )
        [ -n "$selected_pids" ] || return

        while IFS= read -r pid; do
            [ -n "$pid" ] && kill "-$signal" "$pid"
        done <<EOF
$selected_pids
EOF
    done
}
