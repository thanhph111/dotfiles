#!/bin/sh

# Desktop, cloud, and app-specific environment.
#
# These are exported because child processes need to see them.  App aliases and
# interactive helpers belong in interactive modules instead.

# Qt/Kvantum.
export QT_STYLE_OVERRIDE=kvantum

# IBus Bamboo and other input-method aware apps.
export GTK_IM_MODULE=ibus
export QT_IM_MODULE=ibus
export XMODIFIERS=@im=ibus
export QT4_IM_MODULE=ibus
export CLUTTER_IM_MODULE=ibus
export GLFW_IM_MODULE=ibus

# Secretive / 1Password SSH agents on macOS.
#
# Keep real forwarded SSH agents, but prefer the local app agent over macOS's
# default launchd socket. Git SSH signing needs the key-holding agent directly.
dotfiles_ssh_agent=
if [ -S "$HOME/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh" ]; then
    dotfiles_ssh_agent="$HOME/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh"
elif [ -S "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock" ]; then
    dotfiles_ssh_agent="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
fi

if [ -n "$dotfiles_ssh_agent" ]; then
    if [ -z "${SSH_AUTH_SOCK:-}" ] || [ ! -S "$SSH_AUTH_SOCK" ]; then
        export SSH_AUTH_SOCK="$dotfiles_ssh_agent"
    elif [ -z "${SSH_CONNECTION:-}${SSH_CLIENT:-}" ]; then
        case "$SSH_AUTH_SOCK" in
        /var/run/com.apple.launchd.*/Listeners)
            export SSH_AUTH_SOCK="$dotfiles_ssh_agent"
            ;;
        esac
    fi
fi
unset dotfiles_ssh_agent

# AWS CLI.  Keep credentials and history out of $HOME.
if dotfiles_command_exists aws; then
    export AWS_CONFIG_FILE="$XDG_CONFIG_HOME/aws/config"
    export AWS_CLI_HISTORY_FILE="$XDG_CONFIG_HOME/aws/history"
    export AWS_CREDENTIALS_FILE="$XDG_CONFIG_HOME/aws/credentials"
    export AWS_SHARED_CREDENTIALS_FILE="$XDG_CONFIG_HOME/aws/shared-credentials"
    export SAM_CLI_TELEMETRY=0
fi

# Azure CLI.
export AZURE_CONFIG_DIR="$XDG_DATA_HOME/azure"

# Modal.
export MODAL_CONFIG_PATH="$XDG_CONFIG_HOME/modal.toml"

# Docker and Minikube.
export DOCKER_CONFIG="$XDG_CONFIG_HOME/docker"
export MINIKUBE_HOME="$XDG_DATA_HOME/minikube"

# CUDA.
export CUDA_CACHE_PATH="$XDG_CACHE_HOME/nv"

# Claude Code.
export CLAUDE_CODE_MAX_OUTPUT_TOKENS=64000
