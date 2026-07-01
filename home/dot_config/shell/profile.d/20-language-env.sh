#!/bin/sh

# Language and build tool environment.
#
# Prefer stable roots under XDG directories.  Each tool keeps its own block so a
# future change has an obvious owner.

# Git LFS can download large files during clone/checkout.  Opt out by default,
# but let a project, machine, or one-off shell opt back in.
export GIT_LFS_SKIP_SMUDGE="${GIT_LFS_SKIP_SMUDGE:-1}"

# Rust and Cargo.
export RUSTUP_HOME="$XDG_CACHE_HOME/rustup"
export CARGO_HOME="$XDG_CACHE_HOME/cargo"
dotfiles_include "$CARGO_HOME/env"
dotfiles_path_prepend "$CARGO_HOME/bin"

# Go.
export GOPATH="$XDG_DATA_HOME/go"
dotfiles_path_prepend "$GOPATH/bin"

# PowerShell.
export POWERSHELL_UPDATECHECK=Off
export POWERSHELL_TELEMETRY_OPTOUT=1

# Node.js and npm.
export NODE_REPL_HISTORY="$XDG_CACHE_HOME/node/history"
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/config"
export NPM_CONFIG_CACHE="$XDG_CACHE_HOME/npm"
dotfiles_path_prepend "$XDG_DATA_HOME/npm/bin"

# Next.js.
export NEXT_TELEMETRY_DISABLED=1

# Java through jenv.  Put jenv on PATH before checking for it.
dotfiles_path_prepend "$HOME/.jenv/bin"
if dotfiles_command_exists jenv; then
    eval "$(jenv init -)"
fi

# Android Studio.
export ANDROID_HOME="$XDG_DATA_HOME/android"

# Gradle.
export GRADLE_USER_HOME="$XDG_DATA_HOME/gradle"

# .NET.
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export DOTNET_CLI_HOME="$XDG_CACHE_HOME/dotnet"

# Python.
[ -f "$XDG_CONFIG_HOME/python/startup" ] &&
    export PYTHONSTARTUP="$XDG_CONFIG_HOME/python/startup"
export PYTHON_KEYRING_BACKEND=keyring.backends.null.Keyring
export PIP_DISABLE_PIP_VERSION_CHECK=1

# Poetry.
dotfiles_command_exists poetry && export POETRY_VIRTUALENVS_IN_PROJECT=1

# IPython and Jupyter.
export IPYTHONDIR="$XDG_CONFIG_HOME/ipython"
export JUPYTER_CONFIG_DIR="$XDG_CONFIG_HOME/jupyter"

# Matplotlib and Keras.
export MPLCONFIGDIR="$XDG_CACHE_HOME/matplotlib"
export KERAS_HOME="$XDG_STATE_HOME/keras"

# Gauge.
export GAUGE_HOME="$XDG_DATA_HOME/gauge"

# Pyenv.  The root must be known before pyenv is found.
export PYENV_ROOT="$XDG_DATA_HOME/pyenv"
dotfiles_path_prepend "$PYENV_ROOT/bin"
if dotfiles_command_exists pyenv; then
    eval "$(pyenv init -)"
fi
