# Shell startup

Shell startup should only trust files and arguments owned by the local machine or the current project.

## Project environment files

Dotfiles does not load `.env` files globally.

Projects that need `.env` should opt in through their own trusted `.envrc`:

```sh
dotenv_if_exists .env
```

Then run:

```bash
direnv allow
```

This lets each project own its environment rules.

Dotfiles also does not ignore `.env` globally. Some projects intentionally track files such as `.env.example`, `.env.test`, or a non-secret `.env`. Each project should decide this in its own `.gitignore`.

## Startup eval

Some local terminal profiles start the shell with an extra command:

```sh
bash -is eval 'piccel ~/.local/bin/pac-man.json'
zsh -ils eval 'piccel ~/.local/bin/pac-man.json'
```

This is kept on purpose for local terminal profiles. Treat it like:

```sh
bash -ic 'command'
```

The caller controls the command string. Do not feed this argument from a project file, remote input, or generated data.

## Chezmoi script path

Chezmoi scripts use a fixed `PATH` from known user, package-manager, and system directories.

They should not inherit the full caller `PATH`, because `chezmoi apply` may run from a project shell with project-local commands.
