#!/bin/sh

# zmx client environment refresh.
#
# A zmx session outlives the terminal that started it, so the shell inside one
# can be reattached from another terminal or a new SSH connection.  Variables
# that describe the client, such as SSH_AUTH_SOCK and DISPLAY, still name the
# connection that created the session, so agent forwarding and clipboard tools
# break after the first reattach.  zmx tracks those variables per client, and
# this hook copies them from the attached client before each prompt.
#
# It is registered before the prompt so the prompt renders with fresh values.

dotfiles_command_exists zmx || return 0

_zmx_env_hook() {
    # "." names the current session.  Outside a session there is nothing to
    # refresh, and asking would start a daemon lookup on every prompt.
    [ -n "${ZMX_SESSION:-}" ] || return 0
    eval "$(zmx print-env -s .)"
}

case "$SHELL_NAME" in
bash) PROMPT_COMMAND="_zmx_env_hook${PROMPT_COMMAND:+; $PROMPT_COMMAND}" ;;
zsh)
    autoload -Uz add-zsh-hook
    add-zsh-hook precmd _zmx_env_hook
    ;;
esac
