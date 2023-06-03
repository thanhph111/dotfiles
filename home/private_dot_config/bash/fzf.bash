type brew &>/dev/null && FZF_REPO_DIR="$(brew --prefix)/opt/fzf"

[[ -z "$FZF_REPO_DIR" ]] && return

# Setup fzf
# ---------
if [[ ! "$PATH" == *$FZF_REPO_DIR/bin* ]]; then
    export PATH="${PATH:+${PATH}:}$FZF_REPO_DIR/bin"
fi

# Auto-completion
# ---------------
[[ $- == *i* ]] && source "$FZF_REPO_DIR/shell/completion.bash" 2>/dev/null

# Key bindings
# ------------
source "$FZF_REPO_DIR/shell/key-bindings.bash"

__fzf_preview_file_type() {
    # kitty +kitten icat --transfer-mode=file --silent --clear
    bat_args='--style numbers --color always'
    case "$1" in
    *.csv)
        # vd "$1"
        bat $bat_args "$1"
        ;;
    *)
        mime=$(file -b --mime-type "$1")
        case "$mime" in
        text/*)
            bat $bat_args "$1"
            ;;
        image/svg+xml | \
            image/png | \
            image/gif | \
            image/jpeg | \
            image/webp)
            # kitty +kitten icat \
            # --transfer-mode=file \
            # --silent \
            # --align=left \
            # --place "$COLUMNS"x"$LINES"@0x0 \
            # --z-index=-1 \
            # -- "$1"
            file -b "$1"
            echo "$mime"
            ;;
        application/gzip | \
            application/java-archive | \
            application/x-7z-compressed | \
            application/x-bzip2 | \
            application/x-chrome-extension | \
            application/x-rar | \
            application/x-tar | \
            application/x-xar | \
            application/zip)
            7z l $1 | tail -n +12
            ;;
        *)
            file -b "$1"
            echo "$mime"
            ;;
        esac
        ;;
    esac
}
export -f __fzf_preview_file_type

# export FZF_DEFAULT_COMMAND='find $(pwd)'

code_workspace() {
    get_code_workspaces() {
        CONFIG_PATH=~/.config/Code
        find "$CONFIG_PATH/User/workspaceStorage/" \
            -type f \
            -name 'workspace.json' \
            -exec cat {} \; | jq -r '.folder' | while read i; do
            if [ -z "$i" ]; then
                continue
            fi
            folder=$(sed 's/file:\/\///' <<<"$i")
            if [ -d "$folder" ]; then
                echo "$folder"
            fi
        done
    }
    workspace=$(get_code_workspaces | fzf --keep-right --preview 'exa --tree {}')
    [ -n "$workspace" ] && code --new-window "$workspace"
}

FZF_DEFAULT_OPTS="--info=inline \
--border \
--multi \
--cycle \
--layout=reverse \
--margin=2% \
--padding=1 \
--pointer='→ ' \
--marker='◉ ' \
--height=80%"
# --preview \"$(type __fzf_preview_file_type | tail -n +2); __fzf_preview_file_type {}\" \

FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS \
--bind 'ctrl-t:toggle-all' \
--bind 'home:first' \
--bind 'end:last' \
--bind 'ctrl-y:execute-silent(echo -n {+} | xclip -selection clipboard)' \
--bind 'alt-y:execute-silent(readlink -fn {} | xclip -selection clipboard)' \
"
# --pointer='' \
export FZF_COLORS="--color=\
fg:#981748,\
fg+:#e31b61:bold,\
bg:-1,\
bg+:-1,\
hl:#0571a3:bold,\
hl+:#00a5ed:bold,\
info:3,\
prompt:4,\
pointer:13,\
marker:10,\
spinner:10,\
gutter:-1,\
preview-fg:15,\
preview-bg:-1,\
query:15,\
disabled:8,\
border:8,\
header:15"

export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS $FZF_COLORS"

# GIT heart FZF
# -------------

is_in_git_repo() {
    git rev-parse HEAD >/dev/null 2>&1
}

fzf-down() {
    fzf --height 50% --min-height 20 --border --bind ctrl-/:toggle-preview "$@"
}

_gf() {
    is_in_git_repo || return
    git -c color.status=always status --short |
        fzf-down -m --ansi --nth 2..,.. \
            --preview '(git diff --color=always -- {-1} | sed 1,4d; cat {-1})' \
            --preview-window 'wrap' |
        cut -c4- | sed 's/.* -> //'
}

_gb() {
    is_in_git_repo || return
    git branch -a --color=always | grep -v '/HEAD\s' | sort |
        fzf-down --ansi --multi --tac --preview-window right:70% \
            --preview "git log \
--oneline \
--graph \
--date=short \
--color=always \
--pretty=\"format:%C(auto)%cd %h%d %s\" \
\$(sed s/^..// <<< {} | cut -d ' ' -f1)" |
        sed 's/^..//' | cut -d' ' -f1 |
        sed 's#^remotes/##'
}

_gt() {
    is_in_git_repo || return
    git tag --sort -version:refname |
        fzf-down --multi --preview-window right:70% \
            --preview 'git show --color=always {}'
}

_gh() {
    is_in_git_repo || return
    git log \
        --date=short \
        --format="%C(green)%C(bold)%cd %C(auto)%h%d %s (%an)" \
        --graph --color=always |
        fzf-down \
            --ansi \
            --no-sort \
            --reverse \
            --multi \
            --bind 'ctrl-s:toggle-sort' \
            --header 'Press CTRL-S to toggle sort' \
            --preview "grep -o '[a-f0-9]\{7,\}' <<< {} | \
xargs git show --color=always" |
        grep -o "[a-f0-9]\{7,\}"
}

_gr() {
    is_in_git_repo || return
    git remote -v | awk '{print $1 "\t" $2}' | uniq |
        fzf-down --tac \
            --preview "git log \
--oneline \
--graph \
--date=short \
--pretty='format:%C(auto)%cd %h%d %s' {1}" |
        cut -d$'\t' -f1
}

_gs() {
    is_in_git_repo || return
    git stash list | fzf-down \
        --reverse -d: \
        --preview 'git show --color=always {1}' |
        cut -d: -f1
}

#: https://gist.github.com/junegunn/8b572b8d4b5eddd8b85e5f4d40f17236
#: CTRL-G CTRL-F for files
#: CTRL-G CTRL-B for branches
#: CTRL-G CTRL-T for tags
#: CTRL-G CTRL-R for remotes
#: CTRL-G CTRL-H for commit hashes
if [[ $- =~ i ]]; then
    bind '"\er": redraw-current-line'
    bind '"\C-g\C-f": "$(_gf)\e\C-e\er"'
    bind '"\C-g\C-b": "$(_gb)\e\C-e\er"'
    bind '"\C-g\C-t": "$(_gt)\e\C-e\er"'
    bind '"\C-g\C-h": "$(_gh)\e\C-e\er"'
    bind '"\C-g\C-r": "$(_gr)\e\C-e\er"'
    bind '"\C-g\C-s": "$(_gs)\e\C-e\er"'
fi

#: Two-phase filtering with Ripgrep and fzf
#:
#: 1. Search for text in files using Ripgrep
#: 2. Interactively restart Ripgrep with reload action
#:    * Press alt-enter to switch to fzf-only filtering
#: 3. Open the file in Vim
#: TODO: https://github.com/junegunn/fzf/blob/master/ADVANCED.md#switching-between-ripgrep-mode-and-fzf-mode
rfv() {
    RG_PREFIX="rg \
    --column \
    --line-number \
    --no-heading \
    --color=always \
    --smart-case "
    INITIAL_QUERY="${*:-}"
    IFS=: read -ra selected < <(
        FZF_DEFAULT_COMMAND="$RG_PREFIX $(printf %q "$INITIAL_QUERY")" \
            fzf --ansi \
            $FZF_COLORS \
            --disabled --query "$INITIAL_QUERY" \
            --bind "change:reload:sleep 0.1; $RG_PREFIX {q} || true" \
            --bind "alt-enter:\
unbind(change,alt-enter)\
+change-prompt(2. fzf> )\
+enable-search\
+clear-query" \
            --prompt '1. ripgrep> ' \
            --delimiter : \
            --preview 'bat --color=always {1} --highlight-line {2}' \
            --preview-window 'up,60%,border-bottom,+{2}+3/3,~3'
    )
    [ -n "${selected[0]}" ] && vim "${selected[0]}" "+${selected[1]}"
}

fp() {
    fzf --preview '__fzf_preview_file_type {}'
}

export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -200'"
export FZF_CTRL_R_OPTS="--preview 'echo {}' \
--preview-window down:3:hidden:wrap \
--bind 'ctrl-/:toggle-preview'"
export FZF_CTRL_T_COMMAND="rg --files --no-messages --hidden --follow --glob '!{.git,.gitignore}' --glob '!{.DS_Store,.Trash}'"

#: Find binaries in PATH
#: Mnemonic: [F]ind [B]inaries
#: List directories in $PATH, press [enter] on an entry to list the executables
#: inside. press [escape] to go back to directory listing, [escape] twice to
#: exit completely
#: Reference: https://github.com/SidOfc/dotfiles/blob/d07fa3862ed065c2a5a7f1160ae98416bfe2e1ee/zsh/fp
fb() {
    local loc=$(echo $PATH | sed -e $'s/:/\\\n/g' | eval "fzf ${FZF_DEFAULT_OPTS} --header='[find:path]'")
    if [[ -d $loc ]]; then
        echo "$(rg --files $loc | rev | cut -d"/" -f1 | rev)" | eval "fzf ${FZF_DEFAULT_OPTS} --header='[find:exe] => ${loc}' >/dev/null"
        fb
    fi
}

#: Kill processes
#: Mnemonic: [K]ill [P]rocess
#: show output of "ps -ef", use [tab] to select one or multiple entries press
#: [enter] to kill selected processes and go back to the process list. or press
#: [escape] to go back to the process list. Press [escape] twice to exit
#: completely.
#: Reference: https://github.com/SidOfc/dotfiles/blob/d07fa3862ed065c2a5a7f1160ae98416bfe2e1ee/zsh/kp
kp() {
    local pid=$(ps -ef | sed 1d | eval "fzf ${FZF_DEFAULT_OPTS} -m --header='[kill:process]'" | awk '{print $2}')
    if [ "x$pid" != "x" ]; then
        echo $pid | xargs kill -${1:-9}
        kp
    fi
}

#: Support '**' completion for `code`
_fzf_setup_completion path code
