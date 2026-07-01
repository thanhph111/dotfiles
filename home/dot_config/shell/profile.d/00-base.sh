#!/bin/sh

# Basic process environment.
#
# These values should be available to graphical apps, SSH sessions, login
# shells, and interactive shells.  Keep this file about boring defaults only.

# Prefer UTF-8 when the parent process did not choose a locale.
#
# Do not force LC_ALL here.  LC_ALL overrides every narrower locale choice and
# can surprise tools, SSH sessions, and containers that already set their own
# language or collation behavior.
export LANG="${LANG:-en_US.UTF-8}"
export LC_CTYPE="${LC_CTYPE:-en_US.UTF-8}"

# Hide the old Bash warning on macOS.  This is harmless on Linux.
export BASH_SILENCE_DEPRECATION_WARNING=1

# Let tools find user-installed terminfo entries before falling back to system
# entries.  Keep the existing value first in case the parent process set one.
export TERMINFO_DIRS="${TERMINFO_DIRS:+$TERMINFO_DIRS:}$XDG_DATA_HOME/terminfo:/usr/share/terminfo"

# Readline is used by Bash and many command-line tools.
export INPUTRC="$XDG_CONFIG_HOME/readline/inputrc"

# Wget only reads WGETRC from the environment; keep its config with the rest of
# the XDG config files.
[ -f "$XDG_CONFIG_HOME/wget/wgetrc" ] &&
    export WGETRC="$XDG_CONFIG_HOME/wget/wgetrc"
