# Operation commands

Machine operations are `dot-<domain>` commands in `~/.local/bin`, with the verbs as subcommands. Utilities keep their own names.

## The line

An operation changes or inspects the state of this machine. A utility transforms data you hand it. `dot-service` and `dot-brew` are operations; `clipcopy`, `extract-archive`, and `sort-ini` are not.

The bar for writing one at all is a sequence you would otherwise get wrong, not a keystroke saved. `systemctl --user restart spotifyd.service` already completes its own unit name and needs no wrapper. The seven-step Spotifyd login, three steps of which exist only to keep the token private, does.

## Running them

Type `dot-` and press Tab to see the domains. Each one answers for itself:

```bash
dot-service --help
```

Then run a verb:

```bash
dot-service check spotifyd.service
```

Verbs, flags, and arguments all complete. Where an argument has a known set of values, the shell offers them: `dot-theme switch` completes to `dark` or `light`, and `dot-service` completes unit names from the live `systemctl --user` list.

## How they work

Each command is one executable with a `usage` shebang and a spec in comments:

```bash
#!/usr/bin/env -S usage bash

# ShellCheck cannot read the usage shebang, so name the shell for it.
# shellcheck shell=bash

#USAGE about "Operate the thing"
#USAGE cmd "check" help="Look at the thing" {
#USAGE     arg "<name>" help="Which one"
#USAGE }
#USAGE complete "name" run="some-command-that-lists-them"
```

[`usage`](https://usage.jdx.dev) parses that spec before the script body runs. It generates `--help`, rejects an unknown subcommand or an invalid choice, and hands the parsed values to the script as `usage_*` variables — `arg "<name>"` becomes `$usage_name`. The subcommand itself is not one of those variables, so the script switches on `$1`.

One line in each shell config registers a default completion handler that covers every usage-shebang command on `PATH`, so a new command needs no completion of its own. It lives at the end of [`bash.d/40-completion.bash`](../../home/dot_config/shell/bash.d/40-completion.bash) and [`zsh.d/40-completion.zsh`](../../home/dot_config/shell/zsh.d/40-completion.zsh), after the completion framework each shell needs first.

## Why not mise tasks

mise can hold these as global file tasks, and it gives the same spec language and the same `mise tasks` menu. It was the first shape tried here and it was dropped for one reason: global tasks merge into every project's task list and completion, and nothing turns that off. `cascade = false` does not do it, and `mise tasks ls --local` only hides them from one listing. The personal set would get noisier in every unrelated project as it grew.

`usage` is the tool mise's own task specs are built on, so using it directly costs nothing in expressiveness and keeps the commands where every other program can reach them too.

## Adding one

Three things that are easy to get wrong:

- **Switch on `$1`, not on a `usage_` variable.** Only declared args and flags are bound; the subcommand is a positional word.
- **Handle the empty verb.** `usage` does not require a subcommand. Print a usage line and exit 2.
- **Add the ShellCheck directive.** ShellCheck reports SC1008 for the usage shebang and then analyses nothing at all, silently. The `# shellcheck shell=bash` line is what makes the lint real.

`usage` is a hard runtime dependency: without it the shebang fails and the command does not run. It is in every Homebrew manifest for that reason.

Per-OS rules live in [`home/dot_local/bin/.chezmoiignore`](../../home/dot_local/bin/.chezmoiignore), so a Linux-only command is never installed on macOS.

## Validation

`mise run lint` runs ShellCheck over these through a separate hook. The repo's main ShellCheck hook selects files by type, and nothing recognises the usage shebang as a shell script, so the `shellcheck-usage` hook selects them by path instead.
