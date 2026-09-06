# Terminal sessions

This guide explains how work survives a disconnect: `zmx` for interactive sessions, systemd user units for jobs, and what this repo configures for both.

## Two tools, two jobs

Closing an SSH connection sends `SIGHUP` to everything in the session. Two different problems come out of that, and they want different answers.

An interactive program needs a terminal that outlives the connection. That is `zmx`. It keeps the pseudo-terminal and replays its state when a client attaches again, so an agent, a REPL, or an editor is exactly where you left it.

A non-interactive job needs supervision and a log, not a terminal. That is a systemd user unit. It gives you a restart policy, a stop command, and `journalctl`.

`zmx` deliberately has no windows, tabs, or splits. Your terminal and window manager already do that, and native scrollback and copy-paste keep working because `zmx` does not render the screen remotely.

## Install

`zmx` comes from the Homebrew manifests, so it arrives with a normal apply. It is not in Homebrew core, so the manifest names the tap and keeps the formula fully qualified, which is what the shared installer trusts:

```ruby
tap "neurosnap/tap"
brew "neurosnap/tap/zmx", trusted: true
```

Tap-qualified entries sit after the core formulae, which is where `brew bundle dump` puts them.

It is in every Homebrew manifest except `darwin-agent`, which stays deliberately small.

## Everyday use

Attach creates the session when it does not exist, so one command both starts and resumes:

```bash
ssh -t <ssh-alias> zmx attach <session-name>
```

The `-t` matters. Without it the remote shell does not believe it has a terminal and the display breaks.

Detach by closing the terminal window, or press `ctrl+\`. Both leave the session running.

Other commands worth knowing:

```bash
zmx list
```

```bash
zmx history <session-name>
```

```bash
zmx kill <session-name>
```

`ctrl+\` collides with Vim's `CTRL-\ CTRL-N`. Set `ZMX_NO_DETACH_KEY` on a machine where that matters and detach by closing the window instead.

## From a phone or tablet

Blink Shell runs the same command. Over plain SSH:

```bash
ssh -t <ssh-alias> zmx attach <session-name>
```

Over mosh, on the hosts whose manifest installs it:

```bash
mosh <ssh-alias> -- zmx attach <session-name>
```

The client that typed most recently owns the window size, so attaching from a phone resizes the session to the phone. Detach there before going back to a large screen.

## What this repo configures

Two pieces, both small.

[`home/dot_config/shell/final.d/70-zmx.sh`](../../home/dot_config/shell/final.d/70-zmx.sh) refreshes the client environment before each prompt. A session created from one connection keeps that connection's `SSH_AUTH_SOCK`, so without this hook, agent forwarding and sudo through the forwarded agent stop working the first time you reattach from somewhere else. See [Remote access](./remote-access.md) for the agent forwarding and sudo setup this protects.

The Keel prompt shows `zmx:<session-name>` when `ZMX_SESSION` is set. `zmx` gives no other sign that you are inside a session.

There is no `zmx` config file. Everything else is environment variables, documented in the [zmx README](https://github.com/neurosnap/zmx).

## Upgrades kill sessions

When an upgrade changes how the client and daemon talk, every running session dies. `topgrade` upgrades Homebrew without asking which formulae it touches, so treat a `zmx` upgrade as a deliberate act:

```bash
zmx list
```

Check that nothing important is attached before upgrading, and expect to restart whatever was running.

## Long jobs

Prefer a transient systemd user unit over `nohup` on Linux. Since 2016 `systemd-logind` can terminate the user session scope at logout, so a backgrounded process is not reliably safe:

```bash
systemd-run --user --unit=<job-name> --collect <command>
```

Follow it, and stop it, through systemd:

```bash
journalctl --user --unit=<job-name> --follow
```

```bash
systemctl --user stop <job-name>
```

The user manager only outlives your login when lingering is on. This repo enables it as part of the `codex_remote_control` feature. On a host without that feature, turn it on once:

```bash
sudo loginctl enable-linger "$USER"
```

Verify with a real logout before trusting a long job to it.

macOS has no `systemd-run`. Run the job inside a `zmx` session there.

## Known rough edges

`zmx` is young. These are the upstream issues worth knowing before relying on it:

- Nested sessions through SSH, meaning `zmx` on host A into SSH into `zmx` on host B, corrupt the cursor position. Unsupported.
- `zmx attach <name> <command>` exits `0` regardless of what the command did, and drops output printed before the client connects. Use a systemd unit when the exit code matters.
- Reattaching after kitty keyboard mode was enabled can make some programs, such as `psql`, echo escape sequences.
