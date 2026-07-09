#!/bin/sh

# Package-manager environment.
#
# These hooks belong in profile scope because they mostly set PATH and stable
# tool roots.  Interactive helpers and completions live later in shell modules.

# Homebrew sets its own PATH and related variables.  Check common install roots
# so the rest of the config can just call "brew".
if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
elif [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# Homebrew command defaults live in ~/.config/homebrew/brew.env.

# On macOS, prefer GNU userland tools when Homebrew provides them.  On Linux,
# leave distro tools first unless a machine opts into a different policy.
if [ "$(uname -s 2>/dev/null)" = Darwin ] && [ -n "${HOMEBREW_PREFIX:-}" ]; then
    for dotfiles_pkg in coreutils findutils gnu-sed gnu-tar make; do
        dotfiles_gnubin="$HOMEBREW_PREFIX/opt/$dotfiles_pkg/libexec/gnubin"
        dotfiles_path_prepend "$dotfiles_gnubin"
    done
    unset dotfiles_pkg dotfiles_gnubin
fi

# Nix is optional and should be installed with --no-modify-profile so this file
# remains the one owner of shell startup.
dotfiles_include "$HOME/.nix-profile/etc/profile.d/nix.sh"
