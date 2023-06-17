type brew &>/dev/null && FZF_REPO_DIR="$(brew --prefix)/opt/fzf"

[[ -z "$FZF_REPO_DIR" ]] && return

# Setup fzf
# ---------
if [[ ! "$PATH" == *$FZF_REPO_DIR/bin* ]]; then
    export PATH="${PATH:+${PATH}:}$FZF_REPO_DIR/bin"
fi

# Auto-completion
# ---------------
[[ $- == *i* ]] && source "$FZF_REPO_DIR/shell/completion.zsh" 2>/dev/null

# Key bindings
# ------------
source "$FZF_REPO_DIR/shell/key-bindings.zsh"

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

FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS \
--bind 'ctrl-t:toggle-all' \
--bind 'home:first' \
--bind 'end:last' \
--bind 'ctrl-y:execute-silent(if [[ \"$OSTYPE\" == \"darwin\"* ]]; then echo -n {+} | pbcopy; else echo -n {+} | xclip -selection clipboard; fi)' \
--bind 'alt-y:execute-silent(if [[ \"$OSTYPE\" == \"darwin\"* ]]; then readlink -fn {} | pbcopy; else readlink -fn {} | xclip -selection clipboard; fi)' \
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
#: Reference: https://gist.github.com/junegunn/8b572b8d4b5eddd8b85e5f4d40f17236
#: CTRL-G CTRL-F for files
#: CTRL-G CTRL-B for branches
#: CTRL-G CTRL-T for tags
#: CTRL-G CTRL-R for remotes
#: CTRL-G CTRL-H for commit hashes
# -------------

is_in_git_repo() {
    git rev-parse HEAD >/dev/null 2>&1
}

fzf-down() {
    fzf --height 50% --min-height 20 --border --bind ctrl-/:toggle-preview "$@"
}

fzf_gf() {
    is_in_git_repo || return
    git -c color.status=always status --short |
        fzf-down -m --ansi --nth 2..,.. \
            --preview '(git diff --color=always -- {-1} | sed 1,4d; cat {-1})' |
        cut -c4- | sed 's/.* -> //'
}

fzf_gb() {
    is_in_git_repo || return
    git branch -a --color=always | grep -v '/HEAD\s' | sort |
        fzf-down --ansi --multi --tac --preview-window right:70% \
            --preview 'git log --oneline --graph --date=short --color=always --pretty="format:%C(auto)%cd %h%d %s" $(sed s/^..// <<< {} | cut -d" " -f1)' |
        sed 's/^..//' | cut -d' ' -f1 |
        sed 's#^remotes/##'
}

fzf_gt() {
    is_in_git_repo || return
    git tag --sort -version:refname |
        fzf-down --multi --preview-window right:70% \
            --preview 'git show --color=always {}'
}

fzf_gh() {
    is_in_git_repo || return
    git log --date=short --format="%C(green)%C(bold)%cd %C(auto)%h%d %s (%an)" --graph --color=always |
        fzf-down --ansi --no-sort --reverse --multi --bind 'ctrl-s:toggle-sort' \
            --header 'Press CTRL-S to toggle sort' \
            --preview 'grep -o "[a-f0-9]\{7,\}" <<< {} | xargs git show --color=always' |
        grep -o "[a-f0-9]\{7,\}"
}

fzf_gr() {
    is_in_git_repo || return
    git remote -v | awk '{print $1 "\t" $2}' | uniq |
        fzf-down --tac \
            --preview 'git log --oneline --graph --date=short --pretty="format:%C(auto)%cd %h%d %s" {1}' |
        cut -d$'\t' -f1
}

fzf_gs() {
    is_in_git_repo || return
    git stash list | fzf-down --reverse -d: --preview 'git show --color=always {1}' |
        cut -d: -f1
}

() {
    join-lines() {
        local item
        while read item; do
            echo -n "${(q)item} "
        done
    }
    local c
    for c in $@; do
        eval "fzf-g$c-widget() { local result=\$(fzf_g$c | join-lines); zle reset-prompt; LBUFFER+=\$result }"
        eval "zle -N fzf-g$c-widget"
        eval "bindkey '^g^$c' fzf-g$c-widget"
    done
} f b t r h s
